import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/web_storage_service.dart';
import '../../applications/controllers/application_controller.dart';
import '../../../core/services/supabase_service.dart';

class PaymentReturnHandler extends ConsumerStatefulWidget {
  final String? paymentIntent;
  final String? redirectStatus;

  const PaymentReturnHandler({
    super.key,
    this.paymentIntent,
    this.redirectStatus,
  });

  @override
  ConsumerState<PaymentReturnHandler> createState() => _PaymentReturnHandlerState();
}

class _PaymentReturnHandlerState extends ConsumerState<PaymentReturnHandler> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePaymentReturn();
    });
  }

  Future<void> _handlePaymentReturn() async {
    print('[PaymentReturnHandler] Processing payment return...');
    print('[PaymentReturnHandler] Payment Intent: ${widget.paymentIntent}');
    print('[PaymentReturnHandler] Redirect Status: ${widget.redirectStatus}');

    String? paymentIntent = widget.paymentIntent;
    String? redirectStatus = widget.redirectStatus;

    // If parameters are null and we're on web, check sessionStorage
    if (kIsWeb && (paymentIntent == null || redirectStatus == null)) {
      print('[PaymentReturnHandler] Checking sessionStorage for payment parameters...');
      
      try {
        // Check sessionStorage for parameters captured by JavaScript bridge
        final storedPaymentIntent = WebStorageService.getSessionItem('stripe_payment_intent');
        final storedRedirectStatus = WebStorageService.getSessionItem('stripe_redirect_status');
        
        if (storedPaymentIntent != null && storedRedirectStatus != null) {
          print('[PaymentReturnHandler] Found parameters in sessionStorage');
          paymentIntent = storedPaymentIntent;
          redirectStatus = storedRedirectStatus;
          
          // Clear sessionStorage after retrieving
          WebStorageService.removeSessionItem('stripe_payment_intent');
          WebStorageService.removeSessionItem('stripe_redirect_status');
          WebStorageService.removeSessionItem('stripe_client_secret');
        } else {
          print('[PaymentReturnHandler] No parameters found in sessionStorage');
          
          // As last resort, check persistent storage for the last payment intent
          final lastPaymentIntent = await WebStorageService.getPersistentItem('last_payment_intent');
          if (lastPaymentIntent != null) {
            print('[PaymentReturnHandler] Found last payment intent in persistent storage: $lastPaymentIntent');
            paymentIntent = lastPaymentIntent;
            // We'll check the actual status from database below
            redirectStatus = 'unknown';
          }
        }
      } catch (e) {
        print('[PaymentReturnHandler] Error accessing browser storage: $e');
      }
    }

    if (paymentIntent == null || redirectStatus == null) {
      setState(() {
        _errorMessage = 'Invalid payment return parameters';
        _isProcessing = false;
      });
      return;
    }

    try {
      final supabase = SupabaseService.client;
      
      // Find the task associated with this payment intent
      var taskResponse = await supabase
          .from('taskaway_tasks')
          .select('id, title, price, poster_id, tasker_id, status')
          .eq('payment_intent_id', paymentIntent)
          .maybeSingle();

      if (taskResponse == null) {
        print('[PaymentReturnHandler] No task found with payment_intent_id: $paymentIntent');
        
        // Enhanced fallback: Try to find the payment record directly
        final paymentRecordResponse = await supabase
            .from('taskaway_payments')
            .select('task_id, amount, payment_method_type')
            .eq('stripe_payment_intent_id', paymentIntent)
            .maybeSingle();
        
        if (paymentRecordResponse != null) {
          final taskId = paymentRecordResponse['task_id'];
          print('[PaymentReturnHandler] Found payment record for task: $taskId');
          
          // Try to get task with this ID
          final fallbackTaskResponse = await supabase
              .from('taskaway_tasks')
              .select('id, title, price, poster_id, tasker_id, status')
              .eq('id', taskId)
              .maybeSingle();
          
          if (fallbackTaskResponse != null) {
            // Found task via payment record, continue processing
            taskResponse = fallbackTaskResponse;
            print('[PaymentReturnHandler] Found task via payment record: $taskId');
          }
        }
        
        if (taskResponse == null) {
          // Still no task found
          setState(() {
            _errorMessage = 'Processing payment... Please check your task list.';
            _isProcessing = false;
          });
          
          // Navigate to tasks list after a delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              context.go('/home/tasks');
            }
          });
          return;
        }
      }

      final taskId = taskResponse['id'] as String;
      final taskTitle = taskResponse['title'] as String;
      final taskerId = taskResponse['tasker_id'] as String?;
      
      print('[PaymentReturnHandler] Found task: $taskId, status: ${taskResponse['status']}');

      // Check if payment was successful
      if (redirectStatus == 'succeeded') {
        print('[PaymentReturnHandler] Payment succeeded!');
        
        // Get the correct offer price from the application
        double offerPrice = 0.0;
        String? applicationId;
        String? actualTaskerId;
        
        // Always try to find and complete the pending application, even if task has payment_intent_id
        // This handles cases where payment succeeded but DB update failed
        print('[PaymentReturnHandler] Looking for pending application for task: $taskId');
        
        // Get the most recent pending application for this task
        final applicationResponse = await supabase
            .from('taskaway_applications')
            .select('id, offer_price, tasker_id')
            .eq('task_id', taskId)
            .eq('status', 'pending')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (applicationResponse != null) {
          applicationId = applicationResponse['id'] as String;
          offerPrice = (applicationResponse['offer_price'] as num?)?.toDouble() ?? 0.0;
          actualTaskerId = applicationResponse['tasker_id'] as String;
          
          print('[PaymentReturnHandler] Found pending application: $applicationId');
          print('[PaymentReturnHandler] Tasker ID: $actualTaskerId, Offer price: $offerPrice');
          
          try {
            // Complete the offer acceptance
            print('[PaymentReturnHandler] Calling completeOfferAcceptance...');
            final success = await ref.read(applicationControllerProvider.notifier).completeOfferAcceptance(
              applicationId: applicationId,
              taskId: taskId,
              taskerId: actualTaskerId,
              paymentIntentId: paymentIntent,
              offerPrice: offerPrice,
            );
            print('[PaymentReturnHandler] completeOfferAcceptance result: $success');
          } catch (e, stackTrace) {
            print('[PaymentReturnHandler] ERROR completing offer acceptance: $e');
            print('[PaymentReturnHandler] Stack trace: $stackTrace');
            // Continue to navigation even if this fails
          }
        } else {
          print('[PaymentReturnHandler] No pending application found');
          
          // Check if task is already accepted
          if (taskResponse['status'] == 'accepted') {
            print('[PaymentReturnHandler] Task already accepted, getting price from task');
            offerPrice = (taskResponse['price'] as num?)?.toDouble() ?? 0.0;
          } else {
            print('[PaymentReturnHandler] WARNING: No pending application and task not accepted!');
            // Try to get the accepted application
            final acceptedApp = await supabase
                .from('taskaway_applications')
                .select('offer_price')
                .eq('task_id', taskId)
                .eq('status', 'accepted')
                .maybeSingle();
            
            if (acceptedApp != null) {
              offerPrice = (acceptedApp['offer_price'] as num?)?.toDouble() ?? 0.0;
              print('[PaymentReturnHandler] Found accepted application with price: $offerPrice');
            }
          }
        }
        
        // Add delay to ensure frame completion and navigation stability
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate to success screen with correct offer price
        if (mounted) {
          try {
            // Clear any existing navigation stack first
            while (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            // Small additional delay after popping
            await Future.delayed(const Duration(milliseconds: 100));
            
            // Now navigate to success screen
            if (mounted) {
              context.go('/home/browse/$taskId/offer-accepted-success/$offerPrice');
            }
          } catch (e) {
            print('[PaymentReturnHandler] Navigation error: $e');
            // Fallback: try direct navigation
            if (mounted) {
              context.go('/home/browse/$taskId/offer-accepted-success/$offerPrice');
            }
          }
        }
      } else if (redirectStatus == 'failed' || redirectStatus == 'canceled') {
        print('[PaymentReturnHandler] Payment failed or canceled');
        
        // Show error message
        setState(() {
          _errorMessage = redirectStatus == 'canceled' 
              ? 'Payment was canceled. Please try again.'
              : 'Payment failed. Please try again or use a different payment method.';
          _isProcessing = false;
        });
        
        // Navigate back to task details after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            context.go('/home/browse/$taskId');
          }
        });
      } else {
        // Unknown status - could be manual check from web waiting screen
        print('[PaymentReturnHandler] Unknown/manual check redirect status: $redirectStatus');
        
        // Check the actual payment status from database
        final paymentRecord = await supabase
            .from('taskaway_payments')
            .select('payment_status, payment_method_type')
            .eq('stripe_payment_intent_id', paymentIntent)
            .maybeSingle();
        
        if (paymentRecord != null && paymentRecord['payment_status'] == 'succeeded') {
          // Payment actually succeeded - handle as success
          print('[PaymentReturnHandler] Payment record shows success, handling as succeeded');
          
          // Get offer details and complete the flow
          double offerPrice = (taskResponse['price'] as num?)?.toDouble() ?? 0.0;
          
          // Navigate to success screen
          if (mounted) {
            context.go('/home/browse/$taskId/offer-accepted-success/$offerPrice');
          }
        } else {
          // Still unknown or pending
          setState(() {
            _errorMessage = 'Payment is being processed. Please wait a moment or check your task list.';
            _isProcessing = false;
          });
          
          // Navigate to task details after a delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              context.go('/home/browse/$taskId');
            }
          });
        }
      }
    } catch (e) {
      print('[PaymentReturnHandler] Error: $e');
      setState(() {
        _errorMessage = 'An error occurred processing your payment. Please contact support.';
        _isProcessing = false;
      });
      
      // Navigate to home after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.go('/home');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Store redirect status for use in the UI
    final String? redirectStatus = widget.redirectStatus;
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Processing payment return...',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please wait while we verify your payment',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ] else if (_errorMessage != null) ...[
                Icon(
                  redirectStatus == 'canceled' 
                      ? Icons.cancel_outlined 
                      : Icons.error_outline,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Redirecting...',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}