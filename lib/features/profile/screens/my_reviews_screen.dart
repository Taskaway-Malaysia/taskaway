import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class MyReviewsScreen extends ConsumerStatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  ConsumerState<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends ConsumerState<MyReviewsScreen>
    with TickerProviderStateMixin {
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
              color: AppColors.posterPrimary,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: AppColors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/settings');
                    }
                  },
                ),
                const Spacer(),
                Text(
                  'My Reviews',
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
                _buildReviewsTab(isPoster: true),
                _buildReviewsTab(isPoster: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab({required bool isPoster}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: AppRadius.lg,
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                // Overall rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall rating',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(4 reviews)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[300],
                ),

                // Completed tasks
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completed tasks',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '4 tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppSpacing.xxl),

          // Completed tasks section
          Text(
            'Completed tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          // Reviews list
          ...mockReviews.map((review) => _buildReviewCard(review)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewItem review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lg,
        border: Border.all(color: Colors.grey[400]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(
                  review.day,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: review.isOrange ? Colors.orange : AppColors.posterPrimary,
                  ),
                ),
                Text(
                  review.month,
                  style: TextStyle(
                    fontSize: 14,
                    color: review.isOrange ? Colors.orange : AppColors.posterPrimary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: AppSpacing.lg),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.taskTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        review.reviewText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Mock data model
class ReviewItem {
  final String day;
  final String month;
  final String taskTitle;
  final String reviewText;
  final bool isOrange;

  const ReviewItem({
    required this.day,
    required this.month,
    required this.taskTitle,
    required this.reviewText,
    this.isOrange = false,
  });
}

// Mock data
const List<ReviewItem> mockReviews = [
  ReviewItem(
    day: '03',
    month: 'Feb',
    taskTitle: 'I am in need of maid services',
    reviewText: 'Very responsible. It was a pleasure working with you!',
  ),
  ReviewItem(
    day: '18',
    month: 'Feb',
    taskTitle: 'Paint my gate',
    reviewText: 'Very responsible. It was a pleasure working with you!',
    isOrange: true,
  ),
  ReviewItem(
    day: '02',
    month: 'Mar',
    taskTitle: 'Need someone to fold my clothes',
    reviewText: 'Very responsible. It was a pleasure working with you!',
    isOrange: true,
  ),
  ReviewItem(
    day: '30',
    month: 'Mar',
    taskTitle: 'Help walk my dog',
    reviewText: 'Very responsible. It was a pleasure working with you!',
    isOrange: true,
  ),
]; 