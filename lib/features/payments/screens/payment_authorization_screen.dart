import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/style_constants.dart';
import '../controllers/payment_controller.dart';
import 'dart:developer' as dev;

class PaymentAuthorizationScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final String clientSecret;
  final double amount;
  final String taskTitle;

  const PaymentAuthorizationScreen({
    super.key,
    required this.paymentId,
    required this.clientSecret,
    required this.amount,
    required this.taskTitle,
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
    _cardController = CardFormEditController();
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
      dev.log('Starting payment authorization process...');
      
      if (ApiConstants.mockPayments) {
        dev.log('[MOCK] Skipping Stripe card flow');
        await ref.read(paymentControllerProvider).handlePaymentAuthorization(
          paymentId: widget.paymentId,
          paymentMethodId: 'pm_mock',
        );
      } else {
        // Validate card form
        // Note: Card validation will be handled by Stripe during payment method creation

        // Create payment method
        final paymentMethod = await Stripe.instance.createPaymentMethod(
          params: const PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(),
          ),
        );

        dev.log('Payment method created: ${paymentMethod.id}');

        // Confirm payment intent
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

        dev.log('Payment confirmed, proceeding with authorization...');

        // Handle payment authorization through our controller
        await ref.read(paymentControllerProvider).handlePaymentAuthorization(
          paymentId: widget.paymentId,
          paymentMethodId: paymentMethod.id,
        );
      }

      // Navigate to success screen
      if (mounted) {
        context.pushReplacement('/payment/success', extra: {
          'amount': widget.amount,
          'taskTitle': widget.taskTitle,
        });
      }

    } catch (e) {
      dev.log('Payment authorization error: $e');
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
        title: const Text('Authorize Payment'),
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
                            '\$${(totalAmount - platformFeeAmount).toStringAsFixed(2)}',
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
                            '\$${platformFeeAmount.toStringAsFixed(2)}',
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
                            '\$${totalAmount.toStringAsFixed(2)}',
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
                        'Your payment will be held securely until the task is completed. You can cancel if needed.',
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
                      
                      if (!ApiConstants.mockPayments)
                        CardFormField(
                          controller: _cardController!,
                          style: CardFormStyle(
                            backgroundColor: Colors.white,
                            borderRadius: 8,
                            borderColor: Colors.grey.shade300,
                            borderWidth: 1,
                          ),
                        ),

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