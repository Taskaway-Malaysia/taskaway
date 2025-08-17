import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/style_constants.dart';
import '../controllers/payment_controller.dart';
import '../../applications/controllers/application_controller.dart';
import 'dart:developer' as dev;

class PaymentAuthorizationScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final String clientSecret;
  final double amount;
  final String taskTitle;
  final String paymentType; // 'offer_acceptance' or 'task_completion'
  final String? applicationId; // Required for offer_acceptance
  final String? taskId; // Required for offer_acceptance
  final String? taskerId; // Required for offer_acceptance
  final double? offerPrice; // Required for offer_acceptance

  const PaymentAuthorizationScreen({
    super.key,
    required this.paymentId,
    required this.clientSecret,
    required this.amount,
    required this.taskTitle,
    this.paymentType = 'task_completion',
    this.applicationId,
    this.taskId,
    this.taskerId,
    this.offerPrice,
  });

  @override
  ConsumerState<PaymentAuthorizationScreen> createState() => _PaymentAuthorizationScreenState();
}

class _PaymentAuthorizationScreenState extends ConsumerState<PaymentAuthorizationScreen> {
  bool _isProcessing = false;
  String? _errorMessage;
  CardFormEditController? _cardController;

  @override
  void initState() {
    super.initState();
    print('[PaymentAuth] initState - Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    print('[PaymentAuth] Mock payments enabled: ${ApiConstants.mockPayments}');
    
    if (!kIsWeb) {
      try {
        print('[PaymentAuth] Creating CardFormEditController for mobile...');
        _cardController = CardFormEditController();
        print('[PaymentAuth] CardFormEditController created successfully');
      } catch (e) {
        print('[PaymentAuth] Error creating CardFormEditController: $e');
      }
    }
    
    // Log Stripe initialization status
    try {
      print('[PaymentAuth] Stripe publishable key: ${Stripe.publishableKey.substring(0, 20)}...');
      print('[PaymentAuth] Stripe instance available: ${Stripe.instance != null}');
    } catch (e) {
      print('[PaymentAuth] Error checking Stripe status: $e');
    }
  }

  @override
  void dispose() {
    _cardController?.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      print('Starting payment authorization process for type: ${widget.paymentType}');
      
      if (ApiConstants.mockPayments) {
        print('[MOCK] Skipping Stripe card flow');
        
        if (widget.paymentType == 'offer_acceptance') {
          // For offer acceptance, complete the acceptance flow
          await ref.read(applicationControllerProvider.notifier).completeOfferAcceptance(
            applicationId: widget.applicationId!,
            taskId: widget.taskId!,
            taskerId: widget.taskerId!,
            paymentIntentId: widget.paymentId,
            offerPrice: widget.offerPrice!,
          );
        } else {
          // For task completion, use existing payment flow
          await ref.read(paymentControllerProvider).handlePaymentAuthorization(
            paymentId: widget.paymentId,
            paymentMethodId: 'pm_mock',
          );
        }
      } else {
        // Platform-specific payment processing
        if (kIsWeb) {
          // Web: Use confirmPayment with required params for web
          print('Web payment processing with CardField');
          
          // Web requires PaymentMethodParams to be passed
          await Stripe.instance.confirmPayment(
            paymentIntentClientSecret: widget.clientSecret,
            data: const PaymentMethodParams.card(
              paymentMethodData: PaymentMethodData(),
            ),
          );
          
          print('Payment confirmed on web, proceeding with flow...');
          
          if (widget.paymentType == 'offer_acceptance') {
            // For offer acceptance, complete the acceptance flow
            await ref.read(applicationControllerProvider.notifier).completeOfferAcceptance(
              applicationId: widget.applicationId!,
              taskId: widget.taskId!,
              taskerId: widget.taskerId!,
              paymentIntentId: widget.paymentId,
              offerPrice: widget.offerPrice!,
            );
          } else {
            // For task completion, use existing payment flow
            // Note: We don't have paymentMethod.id on web, so we pass the paymentId
            await ref.read(paymentControllerProvider).handlePaymentAuthorization(
              paymentId: widget.paymentId,
              paymentMethodId: widget.paymentId, // Use paymentId as fallback
            );
          }
        } else {
          // Mobile: Use CardFormField
          final paymentMethod = await Stripe.instance.createPaymentMethod(
            params: const PaymentMethodParams.card(
              paymentMethodData: PaymentMethodData(),
            ),
          );
          
          print('Payment method created: ${paymentMethod.id}');

          await Stripe.instance.confirmPayment(
            paymentIntentClientSecret: widget.clientSecret,
            data: PaymentMethodParams.card(
              paymentMethodData: PaymentMethodData(
                billingDetails: BillingDetails(
                  email: null, // Will be populated from user profile
                ),
              ),
            ),
          );
          
          print('Payment confirmed, proceeding with authorization...');

          if (widget.paymentType == 'offer_acceptance') {
            // For offer acceptance, complete the acceptance flow
            await ref.read(applicationControllerProvider.notifier).completeOfferAcceptance(
              applicationId: widget.applicationId!,
              taskId: widget.taskId!,
              taskerId: widget.taskerId!,
              paymentIntentId: widget.paymentId,
              offerPrice: widget.offerPrice!,
            );
          } else {
            // For task completion, use existing payment flow
            await ref.read(paymentControllerProvider).handlePaymentAuthorization(
              paymentId: widget.paymentId,
              paymentMethodId: paymentMethod.id,
            );
          }
        }
      }

      // Navigate to appropriate success screen
      if (mounted) {
        if (widget.paymentType == 'offer_acceptance') {
          context.go('/home/browse/${widget.taskId}/offer-accepted-success/${widget.offerPrice}');
        } else {
          context.go('/payment/success', extra: {
            'amount': widget.amount,
            'taskTitle': widget.taskTitle,
          });
        }
      }

    } catch (e) {
      print('Payment authorization error: $e');
      setState(() {
        _errorMessage = _getReadableError(e.toString());
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _getReadableError(String error) {
    if (error.contains('authentication_required')) {
      return 'Additional authentication required. Please check your payment method.';
    } else if (error.contains('insufficient_funds')) {
      return 'Insufficient funds. Please check your account balance.';
    } else if (error.contains('card_declined')) {
      return 'Your card was declined. Please try a different payment method.';
    } else if (error.contains('expired_card')) {
      return 'Your card has expired. Please use a different card.';
    }
    return 'Payment failed. Please try again or use a different payment method.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platformFeeAmount = widget.amount * 0.05; // 5% platform fee
    final totalAmount = widget.amount;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.paymentType == 'offer_acceptance' 
          ? 'Authorize & Accept Offer' 
          : 'Authorize Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(StyleConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Summary',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Task: ${widget.taskTitle}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Task Amount:',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'RM ${(totalAmount - platformFeeAmount).toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Platform Fee (5%):',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'RM ${platformFeeAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'RM ${totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Security Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.paymentType == 'offer_acceptance'
                          ? 'Your payment will be authorized and held securely until the task is completed. The tasker can then start work.'
                          : 'Your payment will be held securely until the task is completed. You can cancel if needed.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (ApiConstants.mockPayments) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Developer mode: Mock payments are enabled. No real charges will occur.',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],

              // Card Form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (!ApiConstants.mockPayments) ...[
                        if (kIsWeb)
                          // Web: Use CardField which is the web-compatible card input
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: CardField(
                              enablePostalCode: true,
                              onCardChanged: (card) {
                                // Card details changed callback
                                if (card?.complete == true) {
                                  print('Card details are complete and valid');
                                } else {
                                  print('Card details are incomplete or invalid');
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Card details',
                                hintText: 'Enter card information',
                                border: InputBorder.none,
                              ),
                            ),
                          )
                        else
                          // Mobile: Use CardFormField
                          Builder(
                            builder: (context) {
                              print('[PaymentAuth] Building CardFormField for mobile');
                              print('[PaymentAuth] Controller available: ${_cardController != null}');
                              
                              if (_cardController == null) {
                                print('[PaymentAuth] CardController is null, showing error message');
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.shade300),
                                  ),
                                  child: const Text(
                                    'Error: Card input not available. Please restart the app.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                );
                              }
                              
                              try {
                                return CardFormField(
                                  controller: _cardController!,
                                  style: CardFormStyle(
                                    backgroundColor: Colors.white,
                                    borderRadius: 8,
                                    borderColor: Colors.grey.shade300,
                                    borderWidth: 1,
                                  ),
                                );
                              } catch (e) {
                                print('[PaymentAuth] Error rendering CardFormField: $e');
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.shade300),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Payment initialization error',
                                        style: TextStyle(
                                          color: Colors.orange.shade900,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Please restart the app to initialize payment system',
                                        style: TextStyle(color: Colors.orange.shade700),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(ApiConstants.mockPayments
                              ? 'Simulate Authorization'
                              : widget.paymentType == 'offer_acceptance'
                                ? 'Authorize & Accept Offer'
                                : 'Authorize Payment'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}