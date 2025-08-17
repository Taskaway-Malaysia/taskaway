import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import 'dart:developer' as dev;

class StripeService {
  final _supabase = Supabase.instance.client;
  
  // Platform fee percentage (5% for example)
  static const double platformFeePercentage = 0.05;
  
  // Get dynamic return URL based on platform
  String _getPaymentReturnUrl() {
    if (kIsWeb) {
      // For web, use current URL as base with hash routing
      final uri = Uri.base;
      // Build the return URL with current host
      final host = uri.host;
      final port = uri.hasPort ? ':${uri.port}' : '';
      final protocol = uri.scheme;
      // Use hash routing for web (#/payment-return instead of /payment-return)
      return '$protocol://$host$port/#/payment-return';
    } else {
      // For mobile apps (iOS/Android), use deep link scheme
      // This is configured in:
      // - iOS: Info.plist with CFBundleURLSchemes
      // - Android: AndroidManifest.xml with intent-filter
      return 'taskaway://payment-return';
    }
  }

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

  /// Create Stripe PaymentIntent using Flutter Stripe SDK
  /// Note: For production, you should create PaymentIntent on server-side
  /// This is a simplified version for demonstration
  Future<Map<String, dynamic>> createPaymentIntent({
    required String customerEmail,
    required double amount,
    required String description,
    required String taskId,
    required String posterId,
    String? taskerId,
  }) async {
    try {
      print('Creating Stripe PaymentIntent:');
      print('- Customer Email: $customerEmail');
      print('- Amount: \$${amount.toStringAsFixed(2)}');
      print('- Description: $description');
      print('- Task ID: $taskId');

      // Mock mode: skip network calls
      final platformFee = calculatePlatformFee(amount);
      final taskerAmount = calculateTaskerAmount(amount);
      
      if (ApiConstants.mockPayments) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        print('[MOCK] createPaymentIntent');
        return {
          'payment_intent_id': 'pi_mock_$ts',
          'client_secret': 'cs_mock_$ts',
          'amount': amount,
          'platform_fee': platformFee,
          'tasker_amount': taskerAmount,
        };
      }

      // For production apps, PaymentIntent should be created server-side
      // Here we use Edge Function as a secure way to create it
      // This is the ONE place where Edge Function is still needed
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      // Create PaymentIntent via Edge Function (secure)
      final response = await _supabase.functions.invoke(
        'create-stripe-payment-intent',
        body: {
          'amount': convertToStripeAmount(amount),
          'currency': 'myr', // Malaysian Ringgit for Malaysian marketplace
          'customer_email': customerEmail,
          'description': description,
          'task_id': taskId,
          'poster_id': posterId,
          'platform_fee': convertToStripeAmount(platformFee),
          'tasker_amount': convertToStripeAmount(taskerAmount),
          'capture_method': 'manual', // For escrow
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response.status != 200) {
        final errorMessage = response.data is Map 
            ? response.data['error'] ?? 'Unknown error'
            : 'Invalid response format';
        throw Exception('Failed to create PaymentIntent: $errorMessage');
      }

      return {
        'payment_intent_id': response.data['id'],
        'client_secret': response.data['client_secret'],
        'amount': amount,
        'platform_fee': platformFee,
        'tasker_amount': taskerAmount,
      };
    } catch (e, stackTrace) {
      print('Error creating PaymentIntent: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to create PaymentIntent: $e');
    }
  }

  /// Confirm Payment using Flutter Stripe SDK directly
  Future<Map<String, dynamic>> confirmPaymentIntent({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      print('Confirming PaymentIntent: $paymentIntentId with method: $paymentMethodId');

      if (ApiConstants.mockPayments) {
        print('[MOCK] confirmPaymentIntent');
        return {
          'id': paymentIntentId,
          'status': 'succeeded',
        };
      }

      // Use Flutter Stripe SDK to confirm payment
      // This happens on the client-side securely
      // The payment method should already be attached
      
      // For manual capture (escrow), the payment will be authorized but not captured
      // Status will be 'requires_capture' after successful confirmation
      
      // Note: The actual confirmation happens in payment_authorization_screen.dart
      // using Stripe.instance.confirmPayment()
      // This method is kept for backwards compatibility
      
      return {
        'id': paymentIntentId,
        'status': 'requires_capture', // For manual capture flow
      };
    } catch (e) {
      print('Error confirming payment intent: $e');
      throw Exception('Failed to confirm payment intent: $e');
    }
  }

  /// Authorize payment (same as confirm for manual capture)
  Future<Map<String, dynamic>> authorizePayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    // For manual capture, authorize is the same as confirm
    // The payment is authorized but not captured
    return confirmPaymentIntent(
      paymentIntentId: paymentIntentId,
      paymentMethodId: paymentMethodId,
    );
  }

  /// Capture payment after task completion
  /// This MUST use Edge Function as it requires secret key
  Future<Map<String, dynamic>> capturePayment({
    required String paymentIntentId,
  }) async {
    try {
      print('Capturing payment for PaymentIntent: $paymentIntentId');

      if (ApiConstants.mockPayments) {
        print('[MOCK] capturePayment');
        return {
          'id': paymentIntentId,
          'status': 'succeeded',
        };
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      // Capture requires secret key, must use Edge Function
      final response = await _supabase.functions.invoke(
        'capture-stripe-payment-intent',
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
      print('Error capturing payment: $e');
      throw Exception('Failed to capture payment: $e');
    }
  }

  /// Cancel payment intent
  /// This requires secret key, so Edge Function is needed
  Future<void> cancelPaymentIntent({
    required String paymentIntentId,
  }) async {
    try {
      print('Cancelling PaymentIntent: $paymentIntentId');

      if (ApiConstants.mockPayments) {
        print('[MOCK] cancelPaymentIntent');
        return;
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      // Cancel requires secret key, must use Edge Function
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
      print('Error cancelling payment intent: $e');
      throw Exception('Failed to cancel payment intent: $e');
    }
  }

  /// Create a payment method using Flutter Stripe SDK
  Future<PaymentMethod> createPaymentMethod({
    required CardDetails card,
    BillingDetails? billingDetails,
  }) async {
    try {
      print('Creating payment method with Flutter Stripe SDK');
      
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );
      
      print('Payment method created: ${paymentMethod.id}');
      return paymentMethod;
    } catch (e) {
      print('Error creating payment method: $e');
      throw Exception('Failed to create payment method: $e');
    }
  }

  /// Confirm payment using Flutter Stripe SDK with client secret
  Future<PaymentIntent> confirmPaymentWithClientSecret({
    required String clientSecret,
    String? paymentMethodId,
  }) async {
    try {
      print('Confirming payment with client secret');
      
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethodId != null 
          ? PaymentMethodParams.cardFromMethodId(
              paymentMethodData: PaymentMethodDataCardFromMethod(
                paymentMethodId: paymentMethodId,
              ),
            )
          : const PaymentMethodParams.card(
              paymentMethodData: PaymentMethodData(),
            ),
      );
      
      print('Payment confirmed: ${paymentIntent.id}, status: ${paymentIntent.status}');
      return paymentIntent;
    } catch (e) {
      print('Error confirming payment: $e');
      throw Exception('Failed to confirm payment: $e');
    }
  }

  /// Present payment sheet for better UX
  Future<void> presentPaymentSheet({
    required String clientSecret,
    required String customerEmail,
    required String merchantDisplayName,
  }) async {
    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName,
          customerEphemeralKeySecret: null, // Would need Edge Function to create
          customerId: null, // Would need customer ID
          style: ThemeMode.light,
          billingDetails: BillingDetails(
            email: customerEmail,
          ),
        ),
      );
      
      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      print('Payment sheet completed successfully');
    } catch (e) {
      if (e is StripeException) {
        if (e.error.code == FailureCode.Canceled) {
          print('User cancelled payment sheet');
          throw Exception('Payment cancelled');
        }
      }
      print('Error with payment sheet: $e');
      throw Exception('Payment failed: $e');
    }
  }

  /// Create FPX payment intent (Malaysian online banking)
  Future<Map<String, dynamic>> createFPXPayment({
    required double amountMYR,
    required String bankCode,
    required String taskId,
    required String customerEmail,
    String? posterId,
    String? taskerId,
  }) async {
    try {
      print('Creating FPX PaymentIntent:');
      print('- Amount: RM ${amountMYR.toStringAsFixed(2)}');
      print('- Bank Code: $bankCode');
      print('- Task ID: $taskId');
      
      // Log the return URL for debugging
      final returnUrl = _getPaymentReturnUrl();
      print('- Return URL: $returnUrl');

      final platformFee = calculatePlatformFee(amountMYR);
      final taskerAmount = calculateTaskerAmount(amountMYR);

      if (ApiConstants.mockPayments) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        print('[MOCK] createFPXPayment');
        return {
          'payment_intent_id': 'pi_fpx_mock_$ts',
          'status': 'succeeded', // FPX is immediate payment
          'amount': amountMYR,
          'platform_fee': platformFee,
          'tasker_amount': taskerAmount,
          'payment_method': 'fpx',
          'bank_code': bankCode,
        };
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      // Create FPX PaymentIntent via Edge Function
      final response = await _supabase.functions.invoke(
        'create-stripe-payment-intent',
        body: {
          'amount': convertToStripeAmount(amountMYR),
          'currency': 'myr', // FPX only supports MYR
          'payment_method_types': ['fpx'],
          'payment_method_options': {
            'fpx': {
              'bank': bankCode,
            },
          },
          'customer_email': customerEmail,
          'description': 'Task payment #$taskId',
          'task_id': taskId,
          'poster_id': posterId,
          'tasker_id': taskerId,
          'platform_fee': convertToStripeAmount(platformFee),
          'tasker_amount': convertToStripeAmount(taskerAmount),
          'capture_method': 'automatic', // FPX doesn't support manual capture
          'metadata': {
            'payment_method': 'fpx',
            'bank_code': bankCode,
            'task_id': taskId,
            'poster_id': posterId ?? '',
            'tasker_id': taskerId ?? '',
          },
          'confirm_payment': true, // Auto-confirm to get redirect URL
          'return_url': _getPaymentReturnUrl(), // Dynamic return URL based on platform
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response.status != 200) {
        final errorMessage = response.data is Map 
            ? response.data['error'] ?? 'Unknown error'
            : 'Invalid response format';
        throw Exception('Failed to create FPX payment: $errorMessage');
      }

      return {
        'payment_intent_id': response.data['id'],
        'client_secret': response.data['client_secret'],
        'redirect_url': response.data['redirect_url'] ?? response.data['next_action']?['redirect_to_url']?['url'],
        'amount': amountMYR,
        'platform_fee': platformFee,
        'tasker_amount': taskerAmount,
        'payment_method': 'fpx',
      };
    } catch (e, stackTrace) {
      print('Error creating FPX payment: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to create FPX payment: $e');
    }
  }

  /// Create GrabPay payment intent
  Future<Map<String, dynamic>> createGrabPayPayment({
    required double amountMYR,
    required String taskId,
    required String customerEmail,
    String? posterId,
    String? taskerId,
  }) async {
    try {
      print('Creating GrabPay PaymentIntent:');
      print('- Amount: RM ${amountMYR.toStringAsFixed(2)}');
      print('- Task ID: $taskId');
      
      // Log the return URL for debugging
      final returnUrl = _getPaymentReturnUrl();
      print('- Return URL: $returnUrl');

      final platformFee = calculatePlatformFee(amountMYR);
      final taskerAmount = calculateTaskerAmount(amountMYR);

      if (ApiConstants.mockPayments) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        print('[MOCK] createGrabPayPayment');
        return {
          'payment_intent_id': 'pi_grabpay_mock_$ts',
          'status': 'succeeded', // GrabPay is immediate payment
          'amount': amountMYR,
          'platform_fee': platformFee,
          'tasker_amount': taskerAmount,
          'payment_method': 'grabpay',
        };
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      // Create GrabPay PaymentIntent via Edge Function
      final response = await _supabase.functions.invoke(
        'create-stripe-payment-intent',
        body: {
          'amount': convertToStripeAmount(amountMYR),
          'currency': 'myr', // GrabPay supports MYR in Malaysia
          'payment_method_types': ['grabpay'],
          'customer_email': customerEmail,
          'description': 'Task payment #$taskId',
          'task_id': taskId,
          'poster_id': posterId,
          'tasker_id': taskerId,
          'platform_fee': convertToStripeAmount(platformFee),
          'tasker_amount': convertToStripeAmount(taskerAmount),
          'capture_method': 'automatic', // GrabPay doesn't support manual capture
          'metadata': {
            'payment_method': 'grabpay',
            'task_id': taskId,
            'poster_id': posterId ?? '',
            'tasker_id': taskerId ?? '',
          },
          'confirm_payment': true, // Auto-confirm to get redirect URL
          'return_url': _getPaymentReturnUrl(), // Dynamic return URL based on platform
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response.status != 200) {
        final errorMessage = response.data is Map 
            ? response.data['error'] ?? 'Unknown error'
            : 'Invalid response format';
        throw Exception('Failed to create GrabPay payment: $errorMessage');
      }

      return {
        'payment_intent_id': response.data['id'],
        'client_secret': response.data['client_secret'],
        'redirect_url': response.data['redirect_url'] ?? response.data['next_action']?['redirect_to_url']?['url'],
        'amount': amountMYR,
        'platform_fee': platformFee,
        'tasker_amount': taskerAmount,
        'payment_method': 'grabpay',
      };
    } catch (e, stackTrace) {
      print('Error creating GrabPay payment: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to create GrabPay payment: $e');
    }
  }

  /// Process refund for immediate payment methods (FPX, GrabPay)
  Future<Map<String, dynamic>> refundPayment({
    required String paymentIntentId,
    required double amountMYR,
    required String reason,
  }) async {
    try {
      print('Processing refund:');
      print('- PaymentIntent: $paymentIntentId');
      print('- Amount: RM ${amountMYR.toStringAsFixed(2)}');
      print('- Reason: $reason');

      if (ApiConstants.mockPayments) {
        print('[MOCK] refundPayment');
        return {
          'refund_id': 're_mock_${DateTime.now().millisecondsSinceEpoch}',
          'status': 'succeeded',
          'amount': amountMYR,
        };
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      // Process refund via Edge Function
      final response = await _supabase.functions.invoke(
        'refund-payment',
        body: {
          'payment_intent_id': paymentIntentId,
          'amount': convertToStripeAmount(amountMYR),
          'reason': reason,
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to process refund: ${response.data}');
      }

      return response.data;
    } catch (e) {
      print('Error processing refund: $e');
      throw Exception('Failed to process refund: $e');
    }
  }
}