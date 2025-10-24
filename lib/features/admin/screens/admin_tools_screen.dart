import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskaway/features/payments/utils/payment_fix_utility.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class AdminToolsScreen extends ConsumerStatefulWidget {
  const AdminToolsScreen({super.key});

  @override
  ConsumerState<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends ConsumerState<AdminToolsScreen> {
  bool _isProcessing = false;
  String? _statusMessage;

  Future<void> _runPaymentFix() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Running payment fix...';
    });

    try {
      await PaymentFixUtility.fixPendingPayments();
      
      if (mounted) {
        setState(() {
          _statusMessage = 'Payment fix completed successfully!';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: $e';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Tools'),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Status Fix',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'This tool will fix tasks that have successful payments but incorrect status in the database.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _runPaymentFix,
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text('Run Payment Fix'),
                    ),
                    if (_statusMessage != null) ...[
                      SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _statusMessage!.contains('Error')
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: AppRadius.md,
                          border: Border.all(
                            color: _statusMessage!.contains('Error')
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _statusMessage!.contains('Error')
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}