import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/style_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'dart:developer' as dev;

/// ChipPaymentScreen
///
/// Displays CHIP payment checkout page in a WebView
/// Handles payment callbacks (success, failure, cancel)
/// Deep link handling for taskaway:// URLs
class ChipPaymentScreen extends StatefulWidget {
  final String checkoutUrl;
  final String taskId;
  final double amount;
  final String taskTitle;

  const ChipPaymentScreen({
    super.key,
    required this.checkoutUrl,
    required this.taskId,
    required this.amount,
    required this.taskTitle,
  });

  @override
  State<ChipPaymentScreen> createState() => _ChipPaymentScreenState();
}

class _ChipPaymentScreenState extends State<ChipPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    if (kIsWeb) {
      // Web platform - WebView not supported
      setState(() {
        _errorMessage = 'WebView not supported on web platform. Please use a mobile device.';
        _isLoading = false;
      });
      return;
    }

    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              dev.log('[CHIP Payment] Loading progress: $progress%');
            },
            onPageStarted: (String url) {
              dev.log('[CHIP Payment] Page started: $url');
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            },
            onPageFinished: (String url) {
              dev.log('[CHIP Payment] Page finished: $url');
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              dev.log('[CHIP Payment] Resource error: ${error.description}');
              setState(() {
                _errorMessage = 'Failed to load payment page: ${error.description}';
                _isLoading = false;
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              final url = request.url;
              dev.log('[CHIP Payment] Navigation request: $url');

              // Handle new unified payment-return deep link
              if (url.startsWith('taskaway://payment-return')) {
                try {
                  final uri = Uri.parse(url);
                  final status = uri.queryParameters['status'];

                  dev.log('[CHIP Payment] Received callback with status: $status');

                  if (status == 'success') {
                    _handlePaymentSuccess();
                  } else if (status == 'failed') {
                    _handlePaymentFailure();
                  } else if (status == 'cancelled') {
                    _handlePaymentCancelled();
                  } else {
                    dev.log('[CHIP Payment] Unknown status: $status');
                    _handlePaymentFailure(); // Default to failure
                  }
                } catch (e) {
                  dev.log('[CHIP Payment] Error parsing callback URL: $e');
                  _handlePaymentFailure();
                }
                return NavigationDecision.prevent;
              }

              // Handle legacy deep link callbacks (for backward compatibility)
              if (url.startsWith('taskaway://payment/success')) {
                _handlePaymentSuccess();
                return NavigationDecision.prevent;
              } else if (url.startsWith('taskaway://payment/failed')) {
                _handlePaymentFailure();
                return NavigationDecision.prevent;
              } else if (url.startsWith('taskaway://payment/cancelled')) {
                _handlePaymentCancelled();
                return NavigationDecision.prevent;
              }

              // Allow all other navigation
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.checkoutUrl));

      setState(() {
        _isLoading = true;
      });
    } catch (e) {
      dev.log('[CHIP Payment] WebView initialization error: $e');
      setState(() {
        _errorMessage = 'Failed to initialize payment: $e';
        _isLoading = false;
      });
    }
  }

  void _handlePaymentSuccess() {
    dev.log('[CHIP Payment] Payment successful for task ${widget.taskId}');

    if (mounted) {
      // Navigate to success screen using route name
      context.goNamed('chip-success', extra: {
        'taskId': widget.taskId,
        'amount': widget.amount,
        'taskTitle': widget.taskTitle,
      });
    }
  }

  void _handlePaymentFailure() {
    dev.log('[CHIP Payment] Payment failed for task ${widget.taskId}');

    if (mounted) {
      // Show error and allow retry
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );

      // Navigate back after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.pop();
        }
      });
    }
  }

  void _handlePaymentCancelled() {
    dev.log('[CHIP Payment] Payment cancelled for task ${widget.taskId}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment cancelled.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back to task details
      context.go('/home/browse/${widget.taskId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Show confirmation dialog before closing
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Cancel Payment?'),
                content: Text(
                  'Are you sure you want to cancel this payment? Your task will not be posted.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Continue Payment'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      context.pop(); // Close payment screen
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // WebView or error message
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(StyleConstants.defaultPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Payment Error',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: AppSpacing.xxl),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          else if (kIsWeb)
            // Web platform - show message to use mobile
            Center(
              child: Padding(
                padding: const EdgeInsets.all(StyleConstants.defaultPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.smartphone,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Mobile Required',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Please complete payment on the mobile app.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.xxl),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          else
            // Mobile platform - show WebView
            WebViewWidget(controller: _controller),

          // Loading indicator
          if (_isLoading && _errorMessage == null && !kIsWeb)
            Container(
              color: AppColors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Loading payment page...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Payment info at bottom
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Task Payment',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'RM ${widget.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.taskTitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Secured by CHIP Payment Gateway',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade600,
                      fontSize: 11,
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
