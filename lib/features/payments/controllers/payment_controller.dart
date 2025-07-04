import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/billplz_service.dart';
import '../../../core/constants/api_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as dev;

final paymentControllerProvider = Provider((ref) => PaymentController(ref));

class PaymentController {
  final Ref _ref;
  final _supabase = Supabase.instance.client;
  final _billplzService = BillplzService();

  PaymentController(this._ref);

  Future<void> handleTaskApproval({
    required String taskId,
    required String posterId,
    required String taskerId,
    required double amount,
    required String taskTitle,
  }) async {
    try {
      // Get poster profile for name
      final posterData = await _supabase
          .from('taskaway_profiles')
          .select('full_name')
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

      // Create payment record
      final paymentData = await _supabase.from('taskaway_payments').insert({
        'task_id': taskId,
        'payer_id': posterId,
        'payee_id': taskerId,
        'amount': amount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      dev.log('Created payment record: ${jsonEncode(paymentData)}'); // Debug log

      // Get redirect URL based on platform
      final redirectUrl = ApiConstants.getRedirectUrl(paymentData['id']);

      // Create Billplz bill
      final billData = await _billplzService.createBill(
        customerName: posterData['full_name'] ?? 'Taskaway User',
        customerEmail: currentUser.email!,
        customerPhone: null, // Optional phone number
        amount: amount,
        description: 'Payment for task: $taskTitle',
        redirectUrl: redirectUrl,
      );

      dev.log('Received Billplz response: ${jsonEncode(billData)}'); // Debug log
      
      if (billData['id'] == null) {
        throw Exception('No bill ID received from Billplz: ${jsonEncode(billData)}');
      }

      // Update payment record with bill ID
      final updateResult = await _supabase.from('taskaway_payments').update({
        'billplz_bill_id': billData['id'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentData['id']).select().single();

      dev.log('Updated payment record: ${jsonEncode(updateResult)}'); // Debug log

      // Verify the update
      final verifyPayment = await _supabase
          .from('taskaway_payments')
          .select()
          .eq('id', paymentData['id'])
          .single();
      
      dev.log('Verified payment record: ${jsonEncode(verifyPayment)}'); // Debug log

      if (verifyPayment['billplz_bill_id'] == null) {
        throw Exception('Failed to store Billplz bill ID');
      }

      // Update task status to pending_payment
      await _supabase.from('taskaway_tasks').update({
        'status': 'pending_payment',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      // Launch Billplz payment page
      final billUrl = billData['url'];
      if (billUrl == null) {
        throw Exception('No payment URL received from Billplz');
      }

      final uri = Uri.parse(billUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch payment page');
      }
    } catch (e, stackTrace) {
      dev.log('Error in handleTaskApproval: $e'); // Debug log
      dev.log('Stack trace: $stackTrace'); // Debug log
      throw Exception('Failed to process payment: $e');
    }
  }

  Future<void> handlePaymentCallback(String paymentId, Map<String, dynamic> callbackData) async {
    try {
      // Parse Billplz callback parameters
      final billplzData = {
        'id': callbackData['billplz[id]'],
        'paid': callbackData['billplz[paid]'] == 'true',
        'paid_at': callbackData['billplz[paid_at]'],
        'transaction_id': callbackData['billplz[transaction_id]'],
        'transaction_status': callbackData['billplz[transaction_status]'],
        'x_signature': callbackData['billplz[x_signature]'],
      };
      
      final paid = billplzData['paid'] == true;
      
      // Update payment record with status
      await _supabase.from('taskaway_payments').update({
        'status': paid ? 'completed' : 'failed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);

      // If payment is successful, update task status
      if (paid) {
        final paymentData = await _supabase
            .from('taskaway_payments')
            .select('task_id')
            .eq('id', paymentId)
            .single();

        await _supabase.from('taskaway_tasks').update({
          'status': 'completed',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', paymentData['task_id']);
            }
    } catch (e) {
      dev.log('Error handling payment callback: $e');
      throw Exception('Failed to handle payment callback: $e');
    }
  }
} 