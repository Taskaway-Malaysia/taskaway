import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/style_constants.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../models/payment_method_type.dart';
import '../services/stripe_service.dart';
import '../controllers/payment_controller.dart';
import '../../applications/controllers/application_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class FPXBankSelectionScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final double amount;
  final String taskTitle;
  final String paymentType;
  final String? applicationId;
  final String? taskId;
  final String? taskerId;
  final double? offerPrice;

  const FPXBankSelectionScreen({
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
  ConsumerState<FPXBankSelectionScreen> createState() =>
      _FPXBankSelectionScreenState();
}

class _FPXBankSelectionScreenState
    extends ConsumerState<FPXBankSelectionScreen> with WidgetsBindingObserver {
  FPXBank? _selectedBank;
  bool _isProcessing = false;
  String? _errorMessage;
  final _searchController = TextEditingController();
  List<FPXBank> _filteredBanks = fpxBanks;
  String? _pendingPaymentIntentId;
  bool _isWaitingForPayment = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterBanks);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground and we're waiting for payment
    if (state == AppLifecycleState.resumed && _isWaitingForPayment && _pendingPaymentIntentId != null) {
      print('[FPX] App resumed, payment intent: $_pendingPaymentIntentId');
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

  void _filterBanks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = fpxBanks;
      } else {
        _filteredBanks = fpxBanks
            .where((bank) =>
                bank.name.toLowerCase().contains(query) ||
                bank.shortName.toLowerCase().contains(query))
            .toList();
      }
    });
  }


  Future<void> _processPayment() async {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bank'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Create FPX payment intent
      final stripeService = StripeService();
      
      if (ApiConstants.mockPayments) {
        // Mock mode - simulate success
        await Future.delayed(const Duration(seconds: 2));
        
        if (widget.paymentType == 'offer_acceptance') {
          await ref.read(applicationControllerProvider.notifier).completeOfferAcceptance(
            applicationId: widget.applicationId!,
            taskId: widget.taskId!,
            taskerId: widget.taskerId!,
            paymentIntentId: widget.paymentId,
            offerPrice: widget.offerPrice!,
          );
          
          if (mounted) {
            context.go('/home/browse/${widget.taskId}/offer-accepted-success/${widget.offerPrice}');
          }
        } else {
          if (mounted) {
            context.go('/payment/success', extra: {
              'amount': widget.amount,
              'taskTitle': widget.taskTitle,
            });
          }
        }
      } else {
        // Real FPX payment
        // Get current user email
        final currentUser = ref.read(currentUserProvider);
        final customerEmail = currentUser?.email ?? '';
        
        if (customerEmail.isEmpty) {
          throw Exception('User email not found. Please ensure you are logged in.');
        }
        
        print('Creating FPX payment for email: $customerEmail');
        
        final paymentResult = await stripeService.createFPXPayment(
          amountMYR: widget.amount,
          bankCode: _selectedBank!.code,
          taskId: widget.taskId ?? '',
          customerEmail: customerEmail,
          posterId: widget.taskId != null ? currentUser?.id : null,
          taskerId: widget.taskerId,
        );
        
        print('FPX Payment created: ${paymentResult['payment_intent_id']}');
        
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
            print('Creating payment record for FPX offer acceptance...');
            
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
              'status': 'completed', // FPX is automatically captured
              'payment_status': 'succeeded', // FPX doesn't support manual capture
              'payment_method_type': 'fpx', // Set as FPX payment
              'stripe_payment_intent_id': paymentResult['payment_intent_id'],
              'platform_fee': widget.amount * 0.05, // 5% platform fee
              'net_amount': widget.amount * 0.95, // 95% to tasker
              'payment_type': 'offer_acceptance',
              'capture_method': 'automatic', // FPX uses automatic capture
              'currency': 'myr',
              'captured_at': DateTime.now().toIso8601String(), // Captured immediately
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }).select().single();
            
            print('Payment record created for FPX: ${paymentRecord['id']}');
          }
        }
        
        // Check if we got a redirect URL for FPX
        final redirectUrl = paymentResult['redirect_url'];
        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          // Real FPX payment - redirect to bank website
          print('Redirecting to FPX URL: $redirectUrl');
          
          // Store payment intent ID for lifecycle handling
          _pendingPaymentIntentId = paymentResult['payment_intent_id'];
          _isWaitingForPayment = true;
          
          // Store payment intent in shared preferences for cross-platform support
          if (kIsWeb) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_payment_intent', _pendingPaymentIntentId!);
            print('Stored payment intent in SharedPreferences: $_pendingPaymentIntentId');
          }
          
          final uri = Uri.parse(redirectUrl);
          if (await canLaunchUrl(uri)) {
            // Platform-specific launch mode
            final launchMode = kIsWeb 
              ? LaunchMode.platformDefault      // Web: Navigate in same tab
              : LaunchMode.externalApplication; // Mobile: Opens in external browser
            
            // Launch payment URL with platform-specific mode
            await launchUrl(
              uri,
              mode: launchMode,
            );
            
            print('User redirected to bank for payment. Waiting for return...');
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
            throw Exception('Could not launch FPX payment URL');
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
        title: const Text('Select Your Bank'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Payment amount header
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.primary.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount to Pay',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'RM ${widget.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Image.asset(
                    'assets/images/fpx_logo.png',
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[900],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FPX',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search bank name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Bank list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredBanks.length,
                itemBuilder: (context, index) {
                  final bank = _filteredBanks[index];
                  final isSelected = _selectedBank == bank;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedBank = bank;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.05)
                              : Colors.white,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Radio<FPXBank>(
                              value: bank,
                              groupValue: _selectedBank,
                              onChanged: (value) {
                                setState(() {
                                  _selectedBank = value;
                                });
                              },
                              activeColor: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                bank.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
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

            // Continue button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing || _selectedBank == null
                      ? null
                      : _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue with FPX',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}