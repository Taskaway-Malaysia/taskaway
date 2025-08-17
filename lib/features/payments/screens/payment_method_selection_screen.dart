import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/style_constants.dart';
import '../models/payment_method_type.dart';
import '../services/stripe_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/supabase_service.dart';

class PaymentMethodSelectionScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final String clientSecret;
  final double amount;
  final String taskTitle;
  final String paymentType;
  final String? applicationId;
  final String? taskId;
  final String? taskerId;
  final double? offerPrice;

  const PaymentMethodSelectionScreen({
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
  ConsumerState<PaymentMethodSelectionScreen> createState() =>
      _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState
    extends ConsumerState<PaymentMethodSelectionScreen> {
  PaymentMethodType? _selectedMethod;
  bool _isProcessing = false;

  Future<void> _proceedWithPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate based on payment method
    switch (_selectedMethod!) {
      case PaymentMethodType.card:
        // For Card payments, we need to create PaymentIntent first
        setState(() => _isProcessing = true);
        try {
          String paymentId = widget.paymentId;
          String clientSecret = widget.clientSecret;
          
          // If we don't have a PaymentIntent yet, create one
          if (clientSecret.isEmpty) {
            print('Creating PaymentIntent for Card payment...');
            final currentUser = ref.read(currentUserProvider);
            final stripeService = StripeService();
            
            final paymentIntentData = await stripeService.createPaymentIntent(
              customerEmail: currentUser?.email ?? '',
              amount: widget.amount,
              description: 'Payment for task: ${widget.taskTitle}',
              taskId: widget.taskId ?? '',
              posterId: currentUser?.id ?? '',
              taskerId: widget.taskerId,
            );
            
            paymentId = paymentIntentData['payment_intent_id'];
            clientSecret = paymentIntentData['client_secret'];
            print('PaymentIntent created: $paymentId');
            
            // Create payment record in database for offer acceptance
            if (widget.paymentType == 'offer_acceptance' && widget.taskId != null) {
              print('Creating payment record for offer acceptance...');
              final supabase = SupabaseService.client;
              
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
                'status': 'pending',
                'payment_status': 'pending', // Set initial payment status
                'stripe_payment_intent_id': paymentId,
                'platform_fee': widget.amount * 0.05, // 5% platform fee
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              }).select().single();
              
              print('Payment record created: ${paymentRecord['id']}');
              // Keep using the Stripe payment intent ID, not the database record ID
              // The payment authorization screen needs the Stripe ID
            }
          }
          
          // Go to card payment screen with valid PaymentIntent
          if (mounted) {
            context.push(
              '/payment/authorize',
              extra: {
                'paymentId': paymentId,
                'clientSecret': clientSecret,
                'amount': widget.amount,
                'taskTitle': widget.taskTitle,
                'paymentType': widget.paymentType,
                'applicationId': widget.applicationId,
                'taskId': widget.taskId,
                'taskerId': widget.taskerId,
                'offerPrice': widget.offerPrice,
              },
            );
          }
        } catch (e) {
          print('Error creating PaymentIntent: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to initialize payment: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          setState(() => _isProcessing = false);
        }
        break;
      case PaymentMethodType.fpx:
        // Go to FPX bank selection screen
        context.push(
          '/payment/fpx-banks',
          extra: {
            'paymentId': widget.paymentId,
            'amount': widget.amount,
            'taskTitle': widget.taskTitle,
            'paymentType': widget.paymentType,
            'applicationId': widget.applicationId,
            'taskId': widget.taskId,
            'taskerId': widget.taskerId,
            'offerPrice': widget.offerPrice,
          },
        );
        break;
      case PaymentMethodType.grabpay:
        // Go to GrabPay payment screen
        context.push(
          '/payment/grabpay',
          extra: {
            'paymentId': widget.paymentId,
            'amount': widget.amount,
            'taskTitle': widget.taskTitle,
            'paymentType': widget.paymentType,
            'applicationId': widget.applicationId,
            'taskId': widget.taskId,
            'taskerId': widget.taskerId,
            'offerPrice': widget.offerPrice,
          },
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(StyleConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment amount display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Total Amount',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM ${widget.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.taskTitle,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Choose how you want to pay',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Payment method options
              Expanded(
                child: ListView(
                  children: PaymentMethodType.values.map((method) {
                    final isSelected = _selectedMethod == method;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMethod = method;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(0.05)
                                : Colors.white,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Radio button
                              Radio<PaymentMethodType>(
                                value: method,
                                groupValue: _selectedMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMethod = value;
                                  });
                                },
                                activeColor: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              // Method details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method.displayName,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      method.description,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (method == PaymentMethodType.fpx) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        children: [
                                          _buildBankChip('Maybank'),
                                          _buildBankChip('CIMB'),
                                          _buildBankChip('Public Bank'),
                                          Text(
                                            '+9 more',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Payment method icon placeholder
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  method == PaymentMethodType.card
                                      ? Icons.credit_card
                                      : method == PaymentMethodType.fpx
                                          ? Icons.account_balance
                                          : Icons.account_balance_wallet,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Security notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your payment information is encrypted and secure',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Continue button
              ElevatedButton(
                onPressed: _selectedMethod != null && !_isProcessing 
                    ? _proceedWithPayment 
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankChip(String bankName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        bankName,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}