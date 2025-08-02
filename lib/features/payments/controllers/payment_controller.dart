import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stripe_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

final paymentControllerProvider = Provider((ref) => PaymentController());

class PaymentController {
  final _supabase = Supabase.instance.client;
  final _stripeService = StripeService();

  PaymentController();

  /// Step 1-7: Complete payment flow when Poster approves task
  Future<void> handleTaskApproval({
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

      // Get poster profile for payment details
      final posterData = await _supabase
          .from('taskaway_profiles')
          .select('full_name, email')
          .eq('id', posterId)
          .single();

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
        customerEmail: posterData['email'] ?? currentUser.email!,
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
        'platform_fee_amount': paymentIntentData['platform_fee'],
        'status': 'pending_authorization',
        'stripe_payment_intent_id': paymentIntentData['payment_intent_id'],
        'client_secret': paymentIntentData['client_secret'],
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
      
      // Return the client secret for frontend payment confirmation
      // The frontend will handle steps 4-7 after user confirms payment
      
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
      final platformFee = paymentData['platform_fee_amount'] ?? 0.0;
      final taskerAmount = amount - platformFee;

      // === STEP 4: Authorize payment ===
      dev.log('Step 4: Authorizing payment...');
      await _stripeService.authorizePayment(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
      );

      // Update payment status
      await _supabase.from('taskaway_payments').update({
        'status': 'authorized',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);

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

      final taskerStripeAccountId = taskerProfile['stripe_account_id'];
      if (taskerStripeAccountId == null) {
        throw Exception('Tasker has not connected their Stripe account');
      }

      final transferData = await _stripeService.transferToTasker(
        taskerStripeAccountId: taskerStripeAccountId,
        amount: taskerAmount,
        paymentIntentId: paymentIntentId,
      );

      // === STEP 8: Update status to completed and record platform fee ===
      dev.log('Step 8: Finalizing payment and updating statuses...');
      
      // Update payment record
      await _supabase.from('taskaway_payments').update({
        'status': 'completed',
        'transfer_id': transferData['id'],
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
      
      // Update payment status to failed
      await _supabase.from('taskaway_payments').update({
        'status': 'failed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);
      
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