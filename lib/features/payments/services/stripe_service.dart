import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';
import 'dart:developer' as dev;

class StripeService {
  final _supabase = Supabase.instance.client;
  
  // Platform fee percentage (5% for example)
  static const double platformFeePercentage = 0.05;

  // Helper methods for amount conversion
  static int convertToStripeAmount(double amount) {
    // Stripe amounts are in cents
    return (amount * 100).round();
  }

  static double convertFromStripeAmount(int amountInCents) {
    return amountInCents / 100;
  }

  static double calculatePlatformFee(double amount) {
    return amount * platformFeePercentage;
  }

  static double calculateTaskerAmount(double amount) {
    return amount - calculatePlatformFee(amount);
  }

  /// Step 1: Create Stripe PaymentIntent (manual authorization)
  Future<Map<String, dynamic>> createPaymentIntent({
    required String customerEmail,
    required double amount,
    required String description,
    required String taskId,
  }) async {
    try {
      dev.log('Creating Stripe PaymentIntent:');
      dev.log('- Customer Email: $customerEmail');
      dev.log('- Amount: \$${amount.toStringAsFixed(2)}');
      dev.log('- Description: $description');
      dev.log('- Task ID: $taskId');

      // Mock mode: skip network calls (useful for web/CORS and local dev)
      final platformFeeMock = calculatePlatformFee(amount);
      final taskerAmountMock = calculateTaskerAmount(amount);
      if (ApiConstants.mockPayments) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        dev.log('[MOCK] createPaymentIntent');
        return {
          'payment_intent_id': 'pi_mock_$ts',
          'client_secret': 'cs_mock_$ts',
          'amount': amount,
          'platform_fee': platformFeeMock,
          'tasker_amount': taskerAmountMock,
        };
      }

      // Get current session for auth header
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final platformFee = calculatePlatformFee(amount);
      final taskerAmount = calculateTaskerAmount(amount);

      // Prepare request data for Supabase Edge Function
      final requestData = {
        'amount': convertToStripeAmount(amount),
        'currency': 'usd', // or 'myr' for Malaysian Ringgit
        'customer_email': customerEmail,
        'description': description,
        'task_id': taskId,
        'platform_fee': convertToStripeAmount(platformFee),
        'tasker_amount': convertToStripeAmount(taskerAmount),
        'capture_method': 'manual', // Important: Manual capture for escrow
      };

      dev.log('Invoking Stripe Edge Function with data: ${jsonEncode(requestData)}');

      final response = await _supabase.functions.invoke(
        'create-payment-intent',
        body: requestData,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );

      dev.log('Stripe Edge Function Response Status: ${response.status}');
      dev.log('Stripe Edge Function Response Data: ${response.data}');

      if (response.status != 200) {
        final errorMessage = response.data is Map 
            ? response.data['error'] ?? 'Unknown error'
            : 'Invalid response format';
        throw Exception('Failed to create PaymentIntent: $errorMessage (Status: ${response.status})');
      }

      if (response.data == null || response.data is! Map) {
        throw Exception('Invalid response data format');
      }

      return {
        'payment_intent_id': response.data['id'],
        'client_secret': response.data['client_secret'],
        'amount': amount,
        'platform_fee': platformFee,
        'tasker_amount': taskerAmount,
      };
    } catch (e, stackTrace) {
      dev.log('Error creating PaymentIntent: $e');
      dev.log('Stack trace: $stackTrace');
      throw Exception('Failed to create PaymentIntent: $e');
    }
  }

  /// Step 2: Authorize funds (capture_method: manual means funds are authorized but not captured)
  Future<Map<String, dynamic>> authorizePayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      dev.log('Authorizing payment for PaymentIntent: $paymentIntentId');

      if (ApiConstants.mockPayments) {
        dev.log('[MOCK] authorizePayment');
        return {
          'id': paymentIntentId,
          'status': 'succeeded',
        };
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final response = await _supabase.functions.invoke(
        'confirm-payment-intent',
        body: {
          'payment_intent_id': paymentIntentId,
          'payment_method_id': paymentMethodId,
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to authorize payment: ${response.data}');
      }

      return response.data;
    } catch (e) {
      dev.log('Error authorizing payment: $e');
      throw Exception('Failed to authorize payment: $e');
    }
  }

  /// Step 4: Capture payment after user approval
  Future<Map<String, dynamic>> capturePayment({
    required String paymentIntentId,
  }) async {
    try {
      dev.log('Capturing payment for PaymentIntent: $paymentIntentId');

      if (ApiConstants.mockPayments) {
        dev.log('[MOCK] capturePayment');
        return {
          'id': paymentIntentId,
          'status': 'succeeded',
        };
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final response = await _supabase.functions.invoke(
        'capture-payment-intent',
        body: {
          'payment_intent_id': paymentIntentId,
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to capture payment: ${response.data}');
      }

      return response.data;
    } catch (e) {
      dev.log('Error capturing payment: $e');
      throw Exception('Failed to capture payment: $e');
    }
  }

  /// Step 5: Transfer funds to Tasker
  Future<Map<String, dynamic>> transferToTasker({
    required String taskerStripeAccountId,
    required double amount,
    required String paymentIntentId,
  }) async {
    try {
      dev.log('Transferring \$${amount.toStringAsFixed(2)} to Tasker: $taskerStripeAccountId');

      if (ApiConstants.mockPayments) {
        dev.log('[MOCK] transferToTasker');
        final ts = DateTime.now().millisecondsSinceEpoch;
        return {
          'id': 'tr_mock_$ts',
          'amount': convertToStripeAmount(amount),
          'status': 'succeeded',
        };
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final response = await _supabase.functions.invoke(
        'transfer-to-tasker',
        body: {
          'destination_account': taskerStripeAccountId,
          'amount': convertToStripeAmount(amount),
          'payment_intent_id': paymentIntentId,
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to transfer to tasker: ${response.data}');
      }

      return response.data;
    } catch (e) {
      dev.log('Error transferring to tasker: $e');
      throw Exception('Failed to transfer to tasker: $e');
    }
  }

  /// Cancel payment intent if task is cancelled
  Future<void> cancelPaymentIntent({
    required String paymentIntentId,
  }) async {
    try {
      dev.log('Cancelling PaymentIntent: $paymentIntentId');

      if (ApiConstants.mockPayments) {
        dev.log('[MOCK] cancelPaymentIntent');
        return;
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final response = await _supabase.functions.invoke(
        'cancel-payment-intent',
        body: {
          'payment_intent_id': paymentIntentId,
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to cancel payment intent: ${response.data}');
      }
    } catch (e) {
      dev.log('Error cancelling payment intent: $e');
      throw Exception('Failed to cancel payment intent: $e');
    }
  }

  /// Get payment intent status
  Future<Map<String, dynamic>> getPaymentIntentStatus(String paymentIntentId) async {
    try {
      dev.log('Getting status for PaymentIntent: $paymentIntentId');

      if (ApiConstants.mockPayments) {
        dev.log('[MOCK] getPaymentIntentStatus');
        // Simulate a confirmed PI awaiting capture
        return {
          'status': 'requires_capture',
          'id': paymentIntentId,
        };
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final response = await _supabase.functions.invoke(
        'get-payment-intent-status',
        body: {
          'payment_intent_id': paymentIntentId,
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to get payment intent status: ${response.data}');
      }

      return response.data;
    } catch (e) {
      dev.log('Error getting payment intent status: $e');
      throw Exception('Failed to get payment intent status: $e');
    }
  }
} 