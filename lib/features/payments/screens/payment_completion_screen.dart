import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/style_constants.dart';
import '../controllers/payment_controller.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class PaymentCompletionScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final Map<String, String> billplzParams;

  const PaymentCompletionScreen({
    super.key,
    required this.paymentId,
    required this.billplzParams,
  });

  @override
  ConsumerState<PaymentCompletionScreen> createState() => _PaymentCompletionScreenState();
}

class _PaymentCompletionScreenState extends ConsumerState<PaymentCompletionScreen> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processPayment();
  }

  Future<void> _processPayment() async {
    try {
      await ref.read(paymentControllerProvider).getPaymentStatus(
        widget.paymentId,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuccessful = widget.billplzParams['billplz[paid]'] == 'true';

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Status'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(StyleConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                const CircularProgressIndicator(),
                SizedBox(height: AppSpacing.lg),
                Text('Processing payment...'),
              ] else if (_errorMessage != null) ...[
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 64,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Payment Error',
                  style: theme.textTheme.headlineSmall,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ] else if (isSuccessful) ...[
                Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.primary,
                  size: 64,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Payment Successful',
                  style: theme.textTheme.headlineSmall,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Your payment has been processed successfully.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Transaction ID: ${widget.billplzParams['billplz[transaction_id]']}',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Icon(
                  Icons.cancel_outlined,
                  color: theme.colorScheme.error,
                  size: 64,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Payment Failed',
                  style: theme.textTheme.headlineSmall,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Your payment was not successful. Please try again.',
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: AppSpacing.xxxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: Text('Return to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 