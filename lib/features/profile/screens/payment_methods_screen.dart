import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../payments/controllers/payment_method_controller.dart';
import '../../payments/models/payment_method.dart';
import 'add_payment_method_screen.dart';
import 'edit_payment_method_screen.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Purple header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF6C5CE7), // Purple color
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/payment-options');
                    }
                  },
                ),
                const Spacer(),
                const Text(
                  'Payment methods',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),

          // Tab bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Make payment'),
                  Tab(text: 'Receive payment'),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: const Color(0xFF6C5CE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
              ),
            ),
          ),

          // Content area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentMethodsList(),
                _buildPaymentMethodsList(), // Same content for both tabs
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    return ref.watch(paymentMethodsStreamProvider).when(
      data: (paymentMethods) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saved payment methods section
            if (paymentMethods.isNotEmpty) ...[
              const Text(
                'Saved payment method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ...paymentMethods.map((method) => _buildSavedPaymentMethod(method)).toList(),
              const SizedBox(height: 32),
            ],

            // Add new payment method section
            const Text(
              'Add new payment method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodOption(
              icon: Icons.credit_card_outlined,
              title: 'Credit / debit card',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPaymentMethodScreen(
                      type: PaymentMethodType.creditCard,
                    ),
                  ),
                );
              },
            ),
            _buildPaymentMethodOption(
              icon: Icons.account_balance_outlined,
              title: 'Online banking',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPaymentMethodScreen(
                      type: PaymentMethodType.onlineBanking,
                    ),
                  ),
                );
              },
            ),
            _buildPaymentMethodOption(
              icon: Icons.wallet_outlined,
              title: 'E-Wallet',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPaymentMethodScreen(
                      type: PaymentMethodType.eWallet,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(paymentMethodsStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPaymentMethod(PaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPaymentMethodScreen(paymentMethod: method),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Payment method icon
              Container(
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  color: method.type == PaymentMethodType.creditCard 
                      ? Colors.blue.shade700 
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: method.type == PaymentMethodType.creditCard
                      ? const Text(
                          'VISA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        )
                      : Icon(
                          method.type == PaymentMethodType.onlineBanking
                              ? Icons.account_balance
                              : Icons.wallet,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Payment method details
              Expanded(
                child: Text(
                  method.type == PaymentMethodType.creditCard
                      ? method.maskedCardNumber
                      : method.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 