import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stripe_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;
import '../../../core/constants/api_constants.dart';

final paymentControllerProvider = Provider((ref) => PaymentController());

class PaymentController {
  final _supabase = Supabase.instance.client;
  final _stripeService = StripeService();

  PaymentController();

  /// Step 1-3: Initialize payment flow when Poster approves task
  /// Returns data needed for client-side authorization.
  Future<Map<String, dynamic>> handleTaskApproval({
    required String taskId,
    required String posterId,
    required String taskerId,
    required double amount,
    required String taskTitle,
  }) async {
    try {
      dev.log('=== Starting Stripe Payment Flow ===');
      dev.log('Task ID: $taskId');
      dev.log('Amount: \$${amount.toStringAsFixed(2)}');
      
      // Mock mode: skip Stripe + payment insert
      if (ApiConstants.mockPayments) {
        dev.log('[MOCK] Skipping Stripe PI and payment insert; updating task to pending_payment');
        await _supabase.from('taskaway_tasks').update({
          'status': 'pending_payment',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', taskId);

        final mockPaymentId = 'mock_' + taskId;
        final mockClientSecret = 'cs_mock_' + taskId;
        return {
          'paymentId': mockPaymentId,
          'clientSecret': mockClientSecret,
          'amount': amount,
          'taskTitle': taskTitle,
        };
      }
      
      // Use authenticated user's email for Stripe customer

      // Get current authenticated user
      final currentSession = _supabase.auth.currentSession;
      if (currentSession == null) {
        throw Exception('Not authenticated');
      }

      final currentUser = currentSession.user;
      if (currentUser.email == null) {
        throw Exception('User email not found');
      }

      // === STEP 1: Create Stripe PaymentIntent (manual authorization) ===
      dev.log('Step 1: Creating Stripe PaymentIntent...');
      final paymentIntentData = await _stripeService.createPaymentIntent(
        customerEmail: currentUser.email!,
        amount: amount,
        description: 'Payment for task: $taskTitle',
        taskId: taskId,
      );

      // === STEP 2: Create payment record in database ===
      dev.log('Step 2: Creating payment record...');
      final paymentData = await _supabase.from('taskaway_payments').insert({
        'task_id': taskId,
        'payer_id': posterId,
        'payee_id': taskerId,
        'amount': amount,
        'status': 'pending_authorization',
        'stripe_payment_intent_id': paymentIntentData['payment_intent_id'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      dev.log('Payment record created: ${jsonEncode(paymentData)}');

      // === STEP 3: Update task status to pending_payment ===
      dev.log('Step 3: Updating task status to pending_payment...');
      await _supabase.from('taskaway_tasks').update({
        'status': 'pending_payment',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      dev.log('✅ Payment flow initialized successfully');
      dev.log('Payment Intent ID: ${paymentIntentData['payment_intent_id']}');
      dev.log('Client Secret: ${paymentIntentData['client_secret']}');

      // Return init data for the authorization screen
      return {
        'paymentId': paymentData['id'],
        'clientSecret': paymentIntentData['client_secret'],
        'amount': amount,
        'taskTitle': taskTitle,
      };

    } catch (e, stackTrace) {
      dev.log('❌ Error in payment flow: $e');
      dev.log('Stack trace: $stackTrace');
      throw Exception('Failed to initialize payment: $e');
    }
  }

  /// Step 4-7: Handle payment authorization and capture after user confirms payment
  Future<void> handlePaymentAuthorization({
    required String paymentId,
    required String paymentMethodId,
  }) async {
    try {
      dev.log('=== Continuing Stripe Payment Flow ===');
      
      // Mock mode: finalize without Stripe/DB payments read
      if (ApiConstants.mockPayments) {
        dev.log('[MOCK] Completing payment without Stripe/DB payments read');
        final mockTaskId = paymentId.startsWith('mock_')
            ? paymentId.substring(5)
            : paymentId;
        await _supabase.from('taskaway_tasks').update({
          'status': 'completed',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', mockTaskId);
        dev.log('[MOCK] Task set to completed for taskId=' + mockTaskId);
        return;
      }
      
      // Get payment record
      final paymentData = await _supabase
          .from('taskaway_payments')
          .select('*, taskaway_tasks!inner(*)')
          .eq('id', paymentId)
          .single();

      final paymentIntentId = paymentData['stripe_payment_intent_id'];
      final taskId = paymentData['task_id'];
      final taskerId = paymentData['payee_id'];
      final amount = paymentData['amount'];
      double platformFee =
          (paymentData['platform_fee_amount'] as num?)?.toDouble() ?? 0.0;
      if (platformFee == 0.0) {
        // Fallback if column doesn't exist or wasn't stored
        platformFee =
            StripeService.calculatePlatformFee((amount as num).toDouble());
      }
      final taskerAmount = (amount as num).toDouble() - platformFee;

      // === STEP 4: Ensure payment is authorized (confirmed) ===
      dev.log('Step 4: Checking PaymentIntent status before authorization...');
      final statusResp = await _stripeService.getPaymentIntentStatus(paymentIntentId);
      String? stripeStatus;
      if (statusResp['status'] is String) {
        stripeStatus = statusResp['status'] as String?;
      } else if (statusResp['payment_intent'] is Map &&
          (statusResp['payment_intent'] as Map)['status'] is String) {
        stripeStatus = (statusResp['payment_intent'] as Map)['status'] as String?;
      }

      if (stripeStatus == null) {
        throw Exception('Unable to determine PaymentIntent status');
      }

      dev.log('Stripe PaymentIntent status: $stripeStatus');

      if (stripeStatus == 'requires_confirmation' ||
          stripeStatus == 'requires_payment_method') {
        dev.log('Confirming PaymentIntent on server...');
        await _stripeService.authorizePayment(
          paymentIntentId: paymentIntentId,
          paymentMethodId: paymentMethodId,
        );

        await _supabase.from('taskaway_payments').update({
          'status': 'authorized',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', paymentId);
        // Refresh status after confirmation
        final postConfirm = await _stripeService.getPaymentIntentStatus(paymentIntentId);
        if (postConfirm['status'] is String) {
          stripeStatus = postConfirm['status'] as String?;
        } else if (postConfirm['payment_intent'] is Map &&
            (postConfirm['payment_intent'] as Map)['status'] is String) {
          stripeStatus = (postConfirm['payment_intent'] as Map)['status'] as String?;
        }
      } else if (stripeStatus == 'requires_action') {
        // Client confirmation should have handled 3DS already
        throw Exception('Additional authentication required. Please try again.');
      }

      // If PI is already confirmed and awaiting capture, mark payment as authorized
      if (stripeStatus == 'requires_capture') {
        await _supabase.from('taskaway_payments').update({
          'status': 'authorized',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', paymentId);
      }

      // === STEP 5: User approval is implicit at this point ===
      dev.log('Step 5: User has approved the payment authorization');

      // === STEP 6: Capture payment ===
      dev.log('Step 6: Capturing payment...');
      await _stripeService.capturePayment(
        paymentIntentId: paymentIntentId,
      );

      // === STEP 7: Transfer to Tasker ===
      dev.log('Step 7: Transferring \$${taskerAmount.toStringAsFixed(2)} to Tasker...');
      
      // Get tasker's Stripe account ID (assuming it's stored in profile)
      final taskerProfile = await _supabase
          .from('taskaway_profiles')
          .select('stripe_account_id')
          .eq('id', taskerId)
          .single();

      String? taskerStripeAccountId = taskerProfile['stripe_account_id'] as String?;
      if (taskerStripeAccountId == null && ApiConstants.mockPayments) {
        dev.log('[MOCK] Using dummy tasker Stripe account id');
        taskerStripeAccountId = 'acct_mock';
      }
      if (taskerStripeAccountId == null) {
        throw Exception('Tasker has not connected their Stripe account');
      }

      await _stripeService.transferToTasker(
        taskerStripeAccountId: taskerStripeAccountId,
        amount: taskerAmount,
        paymentIntentId: paymentIntentId,
      );

      // === STEP 8: Update status to completed ===
      dev.log('Step 8: Finalizing payment and updating statuses...');
      
      // Update payment record
      await _supabase.from('taskaway_payments').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);

      // Update task status to completed
      await _supabase.from('taskaway_tasks').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      dev.log('✅ Payment flow completed successfully');
      dev.log('Platform fee deducted: \$${platformFee.toStringAsFixed(2)}');
      dev.log('Amount transferred to Tasker: \$${taskerAmount.toStringAsFixed(2)}');

    } catch (e, stackTrace) {
      dev.log('❌ Error in payment authorization: $e');
      dev.log('Stack trace: $stackTrace');
      
      // Update payment status to failed (skip in mock)
      if (!ApiConstants.mockPayments) {
        await _supabase.from('taskaway_payments').update({
          'status': 'failed',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', paymentId);
      }
      
      throw Exception('Failed to process payment authorization: $e');
    }
  }

  /// Cancel payment if task is cancelled before completion
  Future<void> cancelPayment({
    required String paymentId,
  }) async {
    try {
      dev.log('Cancelling payment: $paymentId');
      
      // Get payment record
      final paymentData = await _supabase
          .from('taskaway_payments')
          .select()
          .eq('id', paymentId)
          .single();

      final paymentIntentId = paymentData['stripe_payment_intent_id'];
      final status = paymentData['status'];
      
      // Only cancel if payment is still pending or authorized (not captured)
      if (status == 'pending_authorization' || status == 'authorized') {
        await _stripeService.cancelPaymentIntent(
          paymentIntentId: paymentIntentId,
        );

        // Update payment status
        await _supabase.from('taskaway_payments').update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', paymentId);

        dev.log('✅ Payment cancelled successfully');
      } else {
        dev.log('⚠️ Payment cannot be cancelled - current status: $status');
      }

    } catch (e) {
      dev.log('❌ Error cancelling payment: $e');
      throw Exception('Failed to cancel payment: $e');
    }
  }

  /// Get payment status
  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    try {
      final paymentData = await _supabase
          .from('taskaway_payments')
          .select()
          .eq('id', paymentId)
          .single();

      final paymentIntentId = paymentData['stripe_payment_intent_id'];
      
      if (paymentIntentId != null) {
        final stripeStatus = await _stripeService.getPaymentIntentStatus(paymentIntentId);
        return {
          'local_status': paymentData['status'],
          'stripe_status': stripeStatus,
          'payment_data': paymentData,
        };
      }

      return {
        'local_status': paymentData['status'],
        'payment_data': paymentData,
      };
    } catch (e) {
      dev.log('Error getting payment status: $e');
      throw Exception('Failed to get payment status: $e');
    }
  }
} 