import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/style_constants.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../services/stripe_service.dart';
import '../../applications/controllers/application_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class GrabPayPaymentScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final double amount;
  final String taskTitle;
  final String paymentType;
  final String? applicationId;
  final String? taskId;
  final String? taskerId;
  final double? offerPrice;

  const GrabPayPaymentScreen({
    super.key,
    required this.paymentId,
    required this.amount,
    required this.taskTitle,
    this.paymentType = 'task_completion',
    this.applicationId,
    this.taskId,
    this.taskerId,
    this.offerPrice,
  });

  @override
  ConsumerState<GrabPayPaymentScreen> createState() =>
      _GrabPayPaymentScreenState();
}

class _GrabPayPaymentScreenState extends ConsumerState<GrabPayPaymentScreen> with WidgetsBindingObserver {
  bool _isProcessing = false;
  String? _errorMessage;
  String? _pendingPaymentIntentId;
  bool _isWaitingForPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Automatically start the payment process
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPayment();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground and we're waiting for payment
    if (state == AppLifecycleState.resumed && _isWaitingForPayment && _pendingPaymentIntentId != null) {
      print('[GrabPay] App resumed, payment intent: $_pendingPaymentIntentId');
      // The PaymentReturnHandler will handle everything
      // Just reset our state flags
      if (mounted) {
        setState(() {
          _isWaitingForPayment = false;
          _isProcessing = false;
        });
      }
    }
  }


  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final stripeService = StripeService();
      
      if (ApiConstants.mockPayments) {
        // Mock mode - simulate GrabPay redirect
        await Future.delayed(const Duration(seconds: 2));
        
        // Show GrabPay simulation dialog
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('GrabPay'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You would be redirected to GrabPay app to complete the payment.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount to Pay',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RM ${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text(
                    'Simulating GrabPay payment...',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          );
          
          // Simulate successful payment
          await Future.delayed(const Duration(seconds: 2));
          
          if (mounted) {
            Navigator.of(context).pop(); // Close dialog
            
            // Handle success based on payment type
            if (widget.paymentType == 'offer_acceptance') {
              await ref.read(applicationControllerProvider.notifier).completeOfferAcceptance(
                applicationId: widget.applicationId!,
                taskId: widget.taskId!,
                taskerId: widget.taskerId!,
                paymentIntentId: widget.paymentId,
                offerPrice: widget.offerPrice!,
              );
              
              context.go('/home/browse/${widget.taskId}/offer-accepted-success/${widget.offerPrice}');
            } else {
              context.go('/payment/success', extra: {
                'amount': widget.amount,
                'taskTitle': widget.taskTitle,
              });
            }
          }
        }
      } else {
        // Real GrabPay payment
        // Get current user email
        final currentUser = ref.read(currentUserProvider);
        final customerEmail = currentUser?.email ?? '';
        
        if (customerEmail.isEmpty) {
          throw Exception('User email not found. Please ensure you are logged in.');
        }
        
        print('Creating GrabPay payment for email: $customerEmail');
        
        final paymentResult = await stripeService.createGrabPayPayment(
          amountMYR: widget.amount,
          taskId: widget.taskId ?? '',
          customerEmail: customerEmail,
          posterId: widget.taskId != null ? currentUser?.id : null,
          taskerId: widget.taskerId,
        );
        
        print('GrabPay Payment created: ${paymentResult['payment_intent_id']}');
        
        // Check if payment intent was created successfully
        if (paymentResult['payment_intent_id'] == null) {
          throw Exception('Failed to create payment intent');
        }
        
        // Store payment intent ID in database before redirect
        if (widget.taskId != null) {
          final supabase = SupabaseService.client;
          await supabase
              .from('taskaway_tasks')
              .update({'payment_intent_id': paymentResult['payment_intent_id']})
              .eq('id', widget.taskId!);
          print('Stored payment intent ID in task: ${paymentResult['payment_intent_id']}');
          
          // Create payment record for offer acceptance (like card payments do)
          if (widget.paymentType == 'offer_acceptance') {
            print('Creating payment record for GrabPay offer acceptance...');
            
            // Get the task to get poster ID
            final taskData = await supabase
                .from('taskaway_tasks')
                .select('poster_id')
                .eq('id', widget.taskId!)
                .single();
            
            final paymentRecord = await supabase.from('taskaway_payments').insert({
              'task_id': widget.taskId,
              'payer_id': taskData['poster_id'], // Poster pays
              'payee_id': widget.taskerId, // Tasker receives
              'amount': widget.amount,
              'status': 'completed', // GrabPay is automatically captured
              'payment_status': 'succeeded', // GrabPay doesn't support manual capture
              'payment_method_type': 'grabpay', // Set as GrabPay payment
              'stripe_payment_intent_id': paymentResult['payment_intent_id'],
              'platform_fee': widget.amount * 0.05, // 5% platform fee
              'net_amount': widget.amount * 0.95, // 95% to tasker
              'payment_type': 'offer_acceptance',
              'capture_method': 'automatic', // GrabPay uses automatic capture
              'currency': 'myr',
              'captured_at': DateTime.now().toIso8601String(), // Captured immediately
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }).select().single();
            
            print('Payment record created for GrabPay: ${paymentRecord['id']}');
          }
        }
        
        // Check if we got a redirect URL for GrabPay
        final redirectUrl = paymentResult['redirect_url'];
        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          // Real GrabPay payment - redirect to GrabPay
          print('Redirecting to GrabPay URL: $redirectUrl');
          
          // Store payment intent ID for lifecycle handling
          _pendingPaymentIntentId = paymentResult['payment_intent_id'];
          _isWaitingForPayment = true;
          
          // Store payment intent in localStorage for web fallback
          if (kIsWeb) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_payment_intent', _pendingPaymentIntentId!);
            print('Stored payment intent in localStorage: $_pendingPaymentIntentId');
          }
          
          final uri = Uri.parse(redirectUrl);
          if (await canLaunchUrl(uri)) {
            // Platform-specific launch mode
            final launchMode = kIsWeb 
              ? LaunchMode.platformDefault      // Web: Navigate in same tab
              : LaunchMode.externalApplication; // Mobile: Opens in external browser/app
            
            // Launch GrabPay URL with platform-specific mode
            await launchUrl(
              uri,
              mode: launchMode,
            );
            
            print('User redirected to GrabPay for payment. Waiting for return...');
            print('Launch mode: ${kIsWeb ? "platformDefault (web)" : "externalApplication (mobile)"}');
            
            // Platform-specific handling after launching payment URL
            if (kIsWeb) {
              // Web: Browser navigating to payment page
              print('Web platform: Browser navigating to payment page...');
              // The browser will navigate away completely with platformDefault
              // PaymentReturnHandler will handle the return
            } else {
              // Mobile: Navigate back to task details to clear payment screens from stack
              // The deep link will handle the return and navigation to success
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) {
                context.go('/home/tasks/${widget.taskId}');
              }
              print('Mobile platform: Navigated to task details, waiting for deep link return');
            }
          } else {
            throw Exception('Could not launch GrabPay payment URL');
          }
        } else {
          // No redirect URL - shouldn't happen in production
          throw Exception('No redirect URL received from payment provider');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Payment failed: ${e.toString()}';
          _isWaitingForPayment = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GrabPay Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // GrabPay logo placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Amount display
                Text(
                  'Amount to Pay',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'RM ${widget.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.taskTitle,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Loading or error state
                if (_isProcessing) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Processing GrabPay payment...'),
                ] else if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _processPayment,
                    child: const Text('Retry Payment'),
                  ),
                ],
                
                const SizedBox(height: 48),
                
                // Information text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'GrabPay is an immediate payment method. Funds will be transferred instantly and held by the platform until task completion.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}