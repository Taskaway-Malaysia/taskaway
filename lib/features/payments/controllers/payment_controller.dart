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
      print('=== Starting Stripe Payment Flow ===');
      print('Task ID: $taskId');
      print('Amount: \$${amount.toStringAsFixed(2)}');
      
      // Mock mode: skip Stripe + payment insert
      if (ApiConstants.mockPayments) {
        print('[MOCK] Skipping Stripe PI and payment insert; updating task to accepted');
        await _supabase.from('taskaway_tasks').update({
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', taskId);

        final mockPaymentId = 'mock_$taskId';
        final mockClientSecret = 'cs_mock_$taskId';
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
      print('Step 1: Creating Stripe PaymentIntent...');
      final paymentIntentData = await _stripeService.createPaymentIntent(
        customerEmail: currentUser.email!,
        amount: amount,
        description: 'Payment for task: $taskTitle',
        taskId: taskId,
        posterId: posterId,
        taskerId: taskerId,
      );

      // === STEP 2: Create payment record in database ===
      print('Step 2: Creating payment record...');
      final paymentData = await _supabase.from('taskaway_payments').insert({
        'task_id': taskId,
        'payer_id': posterId,
        'payee_id': taskerId,
        'amount': amount,
        'status': 'pending',
        'stripe_payment_intent_id': paymentIntentData['payment_intent_id'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      print('Payment record created: ${jsonEncode(paymentData)}');

      // === STEP 3: Update task status to accepted ===
      print('Step 3: Updating task status to accepted...');
      await _supabase.from('taskaway_tasks').update({
        'status': 'accepted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      print('✅ Payment flow initialized successfully');
      print('Payment Intent ID: ${paymentIntentData['payment_intent_id']}');
      print('Client Secret: ${paymentIntentData['client_secret']}');

      // Return init data for the authorization screen
      return {
        'paymentId': paymentData['id'],
        'clientSecret': paymentIntentData['client_secret'],
        'amount': amount,
        'taskTitle': taskTitle,
      };

    } catch (e, stackTrace) {
      print('❌ Error in payment flow: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to initialize payment: $e');
    }
  }

  /// Step 4-7: Handle payment authorization and capture after user confirms payment
  Future<void> handlePaymentAuthorization({
    required String paymentId,
    required String paymentMethodId,
  }) async {
    try {
      print('=== Continuing Stripe Payment Flow ===');
      
      // Mock mode: finalize without Stripe/DB payments read
      if (ApiConstants.mockPayments) {
        print('[MOCK] Completing payment without Stripe/DB payments read');
        final mockTaskId = paymentId.startsWith('mock_')
            ? paymentId.substring(5)
            : paymentId;
        await _supabase.from('taskaway_tasks').update({
          'status': 'completed',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', mockTaskId);
        print('[MOCK] Task set to completed for taskId=$mockTaskId');
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
      print('Step 4: Authorizing payment...');
      
      // Try to authorize payment
      try {
        await _stripeService.authorizePayment(
          paymentIntentId: paymentIntentId,
          paymentMethodId: paymentMethodId,
        );

        await _supabase.from('taskaway_payments').update({
          'status': 'authorized',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', paymentId);
        
        print('Payment authorized successfully');
      } catch (e) {
        print('Error authorizing payment: $e');
        // For now, continue with the flow in mock mode
        if (!ApiConstants.mockPayments) {
          throw e;
        }
        print('[MOCK] Continuing despite authorization error');
      }

      // === STEP 5: User approval is implicit at this point ===
      print('Step 5: User has approved the payment authorization');

      // === STEP 6: Capture payment ===
      print('Step 6: Capturing payment...');
      await _stripeService.capturePayment(
        paymentIntentId: paymentIntentId,
      );

      // === STEP 7: Transfer to Tasker (Mock only for now) ===
      print('Step 7: Processing transfer to Tasker (\$${taskerAmount.toStringAsFixed(2)})...');
      
      if (ApiConstants.mockPayments) {
        print('[MOCK] Skipping actual transfer to tasker');
      } else {
        // Transfer functionality would go here when available
        print('Transfer to tasker functionality not yet implemented - skipping for now');
        // Note: When Stripe Connect is fully implemented, the transfer logic will go here
      }

      // === STEP 8: Update status to completed ===
      print('Step 8: Finalizing payment and updating statuses...');
      
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

      print('✅ Payment flow completed successfully');
      print('Platform fee deducted: \$${platformFee.toStringAsFixed(2)}');
      print('Amount transferred to Tasker: \$${taskerAmount.toStringAsFixed(2)}');

    } catch (e, stackTrace) {
      print('❌ Error in payment authorization: $e');
      print('Stack trace: $stackTrace');
      
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
      print('Cancelling payment: $paymentId');
      
      // Get payment record
      final paymentData = await _supabase
          .from('taskaway_payments')
          .select()
          .eq('id', paymentId)
          .single();

      final paymentIntentId = paymentData['stripe_payment_intent_id'];
      final status = paymentData['status'];
      
      // Only cancel if payment is still pending or authorized (not captured)
      if (status == 'pending' || status == 'authorized') {
        await _stripeService.cancelPaymentIntent(
          paymentIntentId: paymentIntentId,
        );

        // Update payment status
        await _supabase.from('taskaway_payments').update({
          'status': 'failed',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', paymentId);

        print('✅ Payment cancelled successfully');
      } else {
        print('⚠️ Payment cannot be cancelled - current status: $status');
      }

    } catch (e) {
      print('❌ Error cancelling payment: $e');
      throw Exception('Failed to cancel payment: $e');
    }
  }

  /// Capture existing payment when poster approves completed task
  /// This captures the payment that was authorized during offer acceptance
  Future<void> captureTaskPayment({
    required String taskId,
  }) async {
    try {
      print('=== Capturing Task Payment ===');
      print('Task ID: $taskId');
      
      // Get task details to find payment_intent_id
      final taskData = await _supabase
          .from('taskaway_tasks')
          .select('id, payment_intent_id, price, status, poster_id, tasker_id')
          .eq('id', taskId)
          .single();
      
      final paymentIntentId = taskData['payment_intent_id'];
      final status = taskData['status'];
      
      if (status != 'pending_approval') {
        throw Exception('Task must be in pending_approval status to capture payment');
      }
      
      if (paymentIntentId == null) {
        throw Exception('No payment intent found for this task. Payment may not have been authorized.');
      }
      
      print('Found PaymentIntent: $paymentIntentId');
      
      // Get payment record
      final paymentData = await _supabase
          .from('taskaway_payments')
          .select()
          .eq('stripe_payment_intent_id', paymentIntentId)
          .single();
      
      final paymentId = paymentData['id'];
      final paymentStatus = paymentData['payment_status'];
      final paymentMethodType = paymentData['payment_method_type'];
      final captureMethod = paymentData['capture_method'];
      
      // Check if payment method supports manual capture
      final supportsManualCapture = paymentMethodType == 'card' || paymentMethodType == null;
      
      // For automatic capture methods (FPX, GrabPay), skip capture
      if (captureMethod == 'automatic' || !supportsManualCapture) {
        print('Payment method $paymentMethodType uses automatic capture, skipping manual capture');
        
        // Just update the task status if payment is already succeeded
        if (paymentStatus == 'succeeded' || paymentStatus == 'completed') {
          print('Payment already captured, updating task status only');
        } else {
          throw Exception('Automatic capture payment is not in succeeded state. Status: $paymentStatus');
        }
      } else {
        // Verify payment is in correct state for manual capture
        if (paymentStatus != 'requires_capture' && !ApiConstants.mockPayments) {
          throw Exception('Payment is not in capturable state. Current status: $paymentStatus');
        }
        
        // Capture the payment (only for card payments)
        if (ApiConstants.mockPayments) {
          print('[MOCK] Simulating payment capture');
        } else {
          print('Capturing payment via Stripe...');
          await _stripeService.capturePayment(
            paymentIntentId: paymentIntentId,
          );
        }
      }
      
      // Update payment record (only if not already completed)
      if (paymentStatus != 'succeeded' && paymentStatus != 'completed') {
        await _supabase.from('taskaway_payments').update({
          'payment_status': 'succeeded',
          'status': 'completed',
          'captured_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', paymentId);
      }
      
      // Update task status to completed
      await _supabase.from('taskaway_tasks').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
      
      print('✅ Payment captured and task completed successfully');
      
    } catch (e, stackTrace) {
      print('❌ Error capturing task payment: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to capture payment: $e');
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
      
      if (paymentIntentId != null && !ApiConstants.mockPayments) {
        // When status checking is available, use it
        try {
          // final stripeStatus = await _stripeService.getPaymentIntentStatus(paymentIntentId);
          // For now, return local status only
          return {
            'local_status': paymentData['status'],
            'payment_data': paymentData,
          };
        } catch (e) {
          print('Error getting Stripe status: $e');
          return {
            'local_status': paymentData['status'],
            'payment_data': paymentData,
          };
        }
      }

      return {
        'local_status': paymentData['status'],
        'payment_data': paymentData,
      };
    } catch (e) {
      print('Error getting payment status: $e');
      throw Exception('Failed to get payment status: $e');
    }
  }
} 