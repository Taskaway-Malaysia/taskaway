import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/features/messages/controllers/message_controller.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class TaskCardWithMessage extends ConsumerWidget {
  final Task task;

  const TaskCardWithMessage({super.key, required this.task});

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDay = DateTime(date.year, date.month, date.day);

    if (scheduledDay.isBefore(today)) {
      return 'Before ${DateFormat('E, d MMM').format(date)}';
    } else {
      return 'On ${DateFormat('E, d MMM').format(date)}';
    }
  }

  Future<void> _navigateToChat(BuildContext context, WidgetRef ref) async {
    try {
      final messageController = ref.read(messageControllerProvider);
      final channel = await messageController.getChannelByTaskId(task.id);
      
      if (channel != null && context.mounted) {
        await context.push('/home/chat/${channel.id}');
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No conversation found for this task')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat =
        NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);
    
    final currentUser = ref.watch(currentUserProvider);
    
    // Determine if message button should show
    final shouldShowMessage = (task.status == 'accepted' || 
                              task.status == 'in_progress' || 
                              task.status == 'pending_approval') &&
                             (currentUser?.id == task.posterId || 
                              currentUser?.id == task.taskerId);

    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/home/tasks/${task.id}'),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            // Top section: Title and Price
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: AppTypography.semiBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  // Add message button if applicable
                  if (shouldShowMessage) ...[
                    IconButton(
                      onPressed: () => _navigateToChat(context, ref),
                      icon: const Icon(Icons.message),
                      color: StyleConstants.primaryColor,
                      tooltip: 'Message',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    currencyFormat.format(task.price),
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            // Bottom section with grid
            IntrinsicHeight(
              child: Row(
                children: [
                  // Status and Offers
                  SizedBox(
                    width: 90, // Fixed width for the first column
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            task.status.toUpperCase(),
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xxs),
                          Container(
                            height: 2,
                            width: 30,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            '${task.offers?.length ?? 0} Offer${(task.offers?.length ?? 0) != 1 ? 's' : ''}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  // Date
                  Expanded(
                    child: Container(
                      color: AppColors.backgroundSecondary,
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            _getFormattedDate(task.scheduledTime),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  // Location or Remote
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            task.locationType == 'remote' ? Icons.home_work : Icons.location_on,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            task.locationType == 'remote' ? 'Remote' : task.location,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}