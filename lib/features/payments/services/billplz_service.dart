import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class BillplzService {
  final _supabase = Supabase.instance.client;

  // Helper methods for amount conversion
  static double convertToRM(int amountInCents) {
    return amountInCents / 100;
  }

  Future<Map<String, dynamic>> createBill({
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    required double amount,
    required String description,
    required String redirectUrl,
  }) async {
    try {
      _logger.i('Creating bill with params:'); // Debug log
      _logger.i('- Customer Name: $customerName');
      _logger.i('- Customer Email: $customerEmail');
      _logger.i('- Customer Phone: ${customerPhone ?? "Not provided"}');
      _logger.i('- Amount: RM ${amount.toStringAsFixed(2)}');
      _logger.i('- Description: $description');
      _logger.i('- Redirect URL: $redirectUrl');

      // Get current session for auth header
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      // Prepare request data
      final requestData = {
        'name': 'Functions',
        'customer_email': customerEmail,
        'customer_phone': customerPhone ?? '',
        'customer_name': customerName,
        'total_customer_to_pay': amount,
        'description': description,
        'redirect_url': redirectUrl,
      };

      _logger.i('Invoking Edge Function with data: ${jsonEncode(requestData)}'); // Debug log

      final response = await _supabase.functions.invoke(
        'create-bill',
        body: requestData,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );

      _logger.i('Edge Function Response Status: ${response.status}'); // Debug log
      _logger.i('Edge Function Response Data: ${response.data}'); // Debug log

      if (response.status != 200) {
        final errorMessage = response.data is Map 
            ? response.data['error'] ?? 'Unknown error'
            : 'Invalid response format';
        throw Exception('Failed to create bill: $errorMessage (Status: ${response.status})');
      }

      if (response.data == null || response.data is! Map) {
        throw Exception('Invalid response data format');
      }

      return response.data;
    } catch (e, stackTrace) {
      _logger.e('Error creating bill: $e'); // Debug log
      _logger.e('Stack trace: $stackTrace'); // Debug log for troubleshooting
      throw Exception('Failed to create bill: $e');
    }
  }

  Future<Map<String, dynamic>> getBillStatus(String billId) async {
    try {
      _logger.i('Getting status for bill: $billId'); // Debug log

      // Get current session for auth header
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final response = await _supabase.functions.invoke(
        'staging-billplz-get-status',
        method: HttpMethod.post,
        body: {
          'billId': billId,
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );

      _logger.i('Edge Function Response Status: ${response.status}'); // Debug log
      _logger.i('Edge Function Response Data: ${response.data}'); // Debug log

      if (response.status != 200) {
        final errorMessage = response.data is Map 
            ? response.data['error'] ?? 'Unknown error'
            : 'Invalid response format';
        throw Exception('Failed to get bill status: $errorMessage (Status: ${response.status})');
      }

      if (response.data == null || response.data is! Map) {
        throw Exception('Invalid response data format');
      }

      return response.data;
    } catch (e, stackTrace) {
      _logger.e('Error getting bill status: $e'); // Debug log
      _logger.e('Stack trace: $stackTrace'); // Debug log for troubleshooting
      throw Exception('Failed to get bill status: $e');
    }
  }

  // Test method to verify the payment flow
  Future<void> testPaymentFlow() async {
    try {
      _logger.i('\n=== Starting Payment Flow Test ===\n');

      // Step 1: Create a test payment record
      _logger.i('Step 1: Creating test payment record...');
      final paymentData = await _supabase.from('taskaway_payments').insert({
        'task_id': 'test-task-${DateTime.now().millisecondsSinceEpoch}',
        'payer_id': 'test-payer',
        'payee_id': 'test-payee',
        'amount': 10.00, // RM 10.00
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      _logger.i('Payment record created: ${jsonEncode(paymentData)}');

      // Step 2: Create Billplz bill
      _logger.i('\nStep 2: Creating Billplz bill...');
      final billData = await createBill(
        customerName: 'Test User',
        customerEmail: 'test@example.com',
        customerPhone: '60123456789',
        amount: 10.00,
        description: 'Test Payment',
        redirectUrl: ApiConstants.getRedirectUrl(paymentData['id']),
      );

      _logger.i('Bill created successfully:');
      _logger.i('- Bill ID: ${billData['id']}');
      _logger.i('- Payment URL: ${billData['url']}');

      // Step 3: Update payment record with bill ID
      _logger.i('\nStep 3: Updating payment record with bill ID...');
      await _supabase.from('taskaway_payments').update({
        'billplz_bill_id': billData['id'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentData['id']);

      _logger.i('Payment record updated with bill ID');

      // Step 4: Check bill status
      _logger.i('\nStep 4: Checking bill status...');
      final statusData = await getBillStatus(billData['id']);
      _logger.i('Current bill status: ${statusData['state']}');

      _logger.i('\n=== Payment Flow Test Completed ===');
      _logger.i('\nTo complete the payment, open this URL in your browser:');
      _logger.i(billData['url']);
      _logger.i('\nAfter payment, check the payment status using:');
      _logger.i('Payment ID: ${paymentData['id']}');
      _logger.i('Bill ID: ${billData['id']}');

    } catch (e, stackTrace) {
      _logger.e('\n=== Payment Flow Test Failed ===');
      _logger.e('Error: $e');
      _logger.e('Stack trace: $stackTrace');
      throw Exception('Payment flow test failed: $e');
    }
  }
} 