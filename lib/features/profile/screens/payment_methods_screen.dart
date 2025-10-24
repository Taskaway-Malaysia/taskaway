import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../payments/controllers/payment_method_controller.dart';
import '../../payments/models/payment_method.dart';
import 'add_payment_method_screen.dart';
import 'edit_payment_method_screen.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

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
              color: AppColors.posterPrimary, // Purple color
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: AppColors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/payment-options');
                    }
                  },
                ),
                const Spacer(),
                Text(
                  'Payment methods',
                  style: AppTypography.headlineSmall.copyWith(color: AppColors.white),
                ),
                const Spacer(),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),

          // Tab bar
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            color: AppColors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: AppRadius.md,
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Make payment'),
                  Tab(text: 'Receive payment'),
                ],
                labelColor: AppColors.white,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.posterPrimary,
                  borderRadius: AppRadius.md,
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
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saved payment methods section
            if (paymentMethods.isNotEmpty) ...[
              Text(
                'Saved payment method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              ...paymentMethods.map((method) => _buildSavedPaymentMethod(method)).toList(),
              SizedBox(height: AppSpacing.xxxl),
            ],

            // Add new payment method section
            Text(
              'Add new payment method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
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
            SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => ref.invalidate(paymentMethodsStreamProvider),
              child: Text('Retry'),
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
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: AppRadius.md,
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
                  borderRadius: AppRadius.sm,
                ),
                child: Center(
                  child: method.type == PaymentMethodType.creditCard
                      ? Text(
                          'VISA',
                          style: TextStyle(
                            color: AppColors.white,
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
              SizedBox(width: AppSpacing.md),
              
              // Payment method details
              Expanded(
                child: Text(
                  method.type == PaymentMethodType.creditCard
                      ? method.maskedCardNumber
                      : method.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
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
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: AppRadius.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: Colors.grey.shade700,
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
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