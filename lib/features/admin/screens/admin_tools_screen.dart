import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskaway/features/payments/utils/payment_fix_utility.dart';

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
        title: const Text('Admin Tools'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Status Fix',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool will fix tasks that have successful payments but incorrect status in the database.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _runPaymentFix,
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Run Payment Fix'),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _statusMessage!.contains('Error')
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
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