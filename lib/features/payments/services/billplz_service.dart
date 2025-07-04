import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';
import 'dart:developer' as dev;

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
      dev.log('Creating bill with params:'); // Debug log
      dev.log('- Customer Name: $customerName');
      dev.log('- Customer Email: $customerEmail');
      dev.log('- Customer Phone: ${customerPhone ?? "Not provided"}');
      dev.log('- Amount: RM ${amount.toStringAsFixed(2)}');
      dev.log('- Description: $description');
      dev.log('- Redirect URL: $redirectUrl');

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

      dev.log('Invoking Edge Function with data: ${jsonEncode(requestData)}'); // Debug log

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

      dev.log('Edge Function Response Status: ${response.status}'); // Debug log
      dev.log('Edge Function Response Data: ${response.data}'); // Debug log

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
      dev.log('Error creating bill: $e'); // Debug log
      dev.log('Stack trace: $stackTrace'); // Debug log for troubleshooting
      throw Exception('Failed to create bill: $e');
    }
  }

  Future<Map<String, dynamic>> getBillStatus(String billId) async {
    try {
      dev.log('Getting status for bill: $billId'); // Debug log

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

      dev.log('Edge Function Response Status: ${response.status}'); // Debug log
      dev.log('Edge Function Response Data: ${response.data}'); // Debug log

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
      dev.log('Error getting bill status: $e'); // Debug log
      dev.log('Stack trace: $stackTrace'); // Debug log for troubleshooting
      throw Exception('Failed to get bill status: $e');
    }
  }

  // Test method to verify the payment flow
  Future<void> testPaymentFlow() async {
    try {
      dev.log('\n=== Starting Payment Flow Test ===\n');

      // Step 1: Create a test payment record
      dev.log('Step 1: Creating test payment record...');
      final paymentData = await _supabase.from('taskaway_payments').insert({
        'task_id': 'test-task-${DateTime.now().millisecondsSinceEpoch}',
        'payer_id': 'test-payer',
        'payee_id': 'test-payee',
        'amount': 10.00, // RM 10.00
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      dev.log('Payment record created: ${jsonEncode(paymentData)}');

      // Step 2: Create Billplz bill
      dev.log('\nStep 2: Creating Billplz bill...');
      final billData = await createBill(
        customerName: 'Test User',
        customerEmail: 'test@example.com',
        customerPhone: '60123456789',
        amount: 10.00,
        description: 'Test Payment',
        redirectUrl: ApiConstants.getRedirectUrl(paymentData['id']),
      );

      dev.log('Bill created successfully:');
      dev.log('- Bill ID: ${billData['id']}');
      dev.log('- Payment URL: ${billData['url']}');

      // Step 3: Update payment record with bill ID
      dev.log('\nStep 3: Updating payment record with bill ID...');
      await _supabase.from('taskaway_payments').update({
        'billplz_bill_id': billData['id'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentData['id']);

      dev.log('Payment record updated with bill ID');

      // Step 4: Check bill status
      dev.log('\nStep 4: Checking bill status...');
      final statusData = await getBillStatus(billData['id']);
      dev.log('Current bill status: ${statusData['state']}');

      dev.log('\n=== Payment Flow Test Completed ===');
      dev.log('\nTo complete the payment, open this URL in your browser:');
      dev.log(billData['url']);
      dev.log('\nAfter payment, check the payment status using:');
      dev.log('Payment ID: ${paymentData['id']}');
      dev.log('Bill ID: ${billData['id']}');

    } catch (e, stackTrace) {
      dev.log('\n=== Payment Flow Test Failed ===');
      dev.log('Error: $e');
      dev.log('Stack trace: $stackTrace');
      throw Exception('Payment flow test failed: $e');
    }
  }
} 