import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../payments/models/payment.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

// Provider for poster payments stream (payments where user is the payer)
final posterPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value([]);
  }

  return Supabase.instance.client
      .from('taskaway_payments')
      .stream(primaryKey: ['id'])
      .eq('payer_id', user.id)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => Payment.fromJson(json)).toList());
});

// Provider for tasker payments stream (payments where user is the payee)
final taskerPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value([]);
  }

  return Supabase.instance.client
      .from('taskaway_payments')
      .stream(primaryKey: ['id'])
      .eq('payee_id', user.id)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => Payment.fromJson(json)).toList());
});

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> 
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
                  'Payment history',
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
                  Tab(text: 'As Poster'),
                  Tab(text: 'As Tasker'),
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
                _buildPaymentListView(posterPaymentsProvider, isPoster: true),
                _buildPaymentListView(taskerPaymentsProvider, isPoster: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentListView(StreamProvider<List<Payment>> provider, {required bool isPoster}) {
    return ref.watch(provider).when(
      data: (payments) => payments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'No payment history',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    isPoster 
                        ? 'You haven\'t made any payments yet'
                        : 'You haven\'t received any payments yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(AppSpacing.lg),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _buildPaymentItem(payment, isPoster: isPoster);
              },
              separatorBuilder: (context, index) => SizedBox(height: AppSpacing.lg),
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
              onPressed: () => ref.invalidate(provider),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Payment payment, {required bool isPoster}) {
    final isCompleted = payment.status == 'completed';
    final amount = payment.amount;
    final sign = isPoster ? '-' : '+';
    
    return Row(
      children: [
        // Avatar placeholder
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade300,
          child: Text(
            isPoster ? 'TA' : 'IR', // Placeholder initials
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.lg),
        
        // Payment details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCompleted ? 'Completed' : 'Pending',
                style: TextStyle(
                  fontSize: 14,
                  color: isCompleted ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Task payment', // Simplified for now
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(payment.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
        // Amount
        Text(
          '$sign RM ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isPoster ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 