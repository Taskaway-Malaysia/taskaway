import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';

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
      print('Creating bill with params:'); // Debug log
      print('- Customer Name: $customerName');
      print('- Customer Email: $customerEmail');
      print('- Customer Phone: ${customerPhone ?? "Not provided"}');
      print('- Amount: RM ${amount.toStringAsFixed(2)}');
      print('- Description: $description');
      print('- Redirect URL: $redirectUrl');

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

      print('Invoking Edge Function with data: ${jsonEncode(requestData)}'); // Debug log

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

      print('Edge Function Response Status: ${response.status}'); // Debug log
      print('Edge Function Response Data: ${response.data}'); // Debug log

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
      print('Error creating bill: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log for troubleshooting
      throw Exception('Failed to create bill: $e');
    }
  }

  Future<Map<String, dynamic>> getBillStatus(String billId) async {
    try {
      print('Getting status for bill: $billId'); // Debug log

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

      print('Edge Function Response Status: ${response.status}'); // Debug log
      print('Edge Function Response Data: ${response.data}'); // Debug log

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
      print('Error getting bill status: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log for troubleshooting
      throw Exception('Failed to get bill status: $e');
    }
  }

  // Test method to verify the payment flow
  Future<void> testPaymentFlow() async {
    try {
      print('\n=== Starting Payment Flow Test ===\n');

      // Step 1: Create a test payment record
      print('Step 1: Creating test payment record...');
      final paymentData = await _supabase.from('taskaway_payments').insert({
        'task_id': 'test-task-${DateTime.now().millisecondsSinceEpoch}',
        'payer_id': 'test-payer',
        'payee_id': 'test-payee',
        'amount': 10.00, // RM 10.00
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      print('Payment record created: ${jsonEncode(paymentData)}');

      // Step 2: Create Billplz bill
      print('\nStep 2: Creating Billplz bill...');
      final billData = await createBill(
        customerName: 'Test User',
        customerEmail: 'test@example.com',
        customerPhone: '60123456789',
        amount: 10.00,
        description: 'Test Payment',
        redirectUrl: ApiConstants.getRedirectUrl(paymentData['id']),
      );

      print('Bill created successfully:');
      print('- Bill ID: ${billData['id']}');
      print('- Payment URL: ${billData['url']}');

      // Step 3: Update payment record with bill ID
      print('\nStep 3: Updating payment record with bill ID...');
      await _supabase.from('taskaway_payments').update({
        'billplz_bill_id': billData['id'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentData['id']);

      print('Payment record updated with bill ID');

      // Step 4: Check bill status
      print('\nStep 4: Checking bill status...');
      final statusData = await getBillStatus(billData['id']);
      print('Current bill status: ${statusData['state']}');

      print('\n=== Payment Flow Test Completed ===');
      print('\nTo complete the payment, open this URL in your browser:');
      print(billData['url']);
      print('\nAfter payment, check the payment status using:');
      print('Payment ID: ${paymentData['id']}');
      print('Bill ID: ${billData['id']}');

    } catch (e, stackTrace) {
      print('\n=== Payment Flow Test Failed ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Payment flow test failed: $e');
    }
  }
} 