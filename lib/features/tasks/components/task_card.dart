import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/core/theme/app_colors.dart';
import 'package:taskaway/core/theme/app_typography.dart';
import 'package:taskaway/core/theme/app_spacing.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

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

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);

    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/home/tasks/${task.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderDefault,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Poster information section
            if (task.posterProfile != null) ...[
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                ),
                child: Row(
                  children: [
                    // Poster avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.backgroundTertiary,
                      backgroundImage: task.posterProfile?['avatar_url'] != null
                          ? CachedNetworkImageProvider(
                              task.posterProfile!['avatar_url'] as String,
                            )
                          : null,
                      child: task.posterProfile?['avatar_url'] == null
                          ? Text(
                              (task.posterProfile?['full_name'] as String? ?? 'U')[0].toUpperCase(),
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: AppTypography.bold,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    // Poster name and badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Posted by ',
                                style: AppTypography.captionMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                task.posterProfile?['full_name'] as String? ?? 'Unknown',
                                style: AppTypography.captionMedium.copyWith(
                                  fontWeight: AppTypography.semiBold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (task.posterProfile?['rating'] != null) ...[
                            SizedBox(height: AppSpacing.xxs),
                            Row(
                              children: [
                                Icon(Icons.star, size: AppSpacing.iconSm, color: AppColors.star),
                                SizedBox(width: AppSpacing.xxs),
                                Text(
                                  '${(task.posterProfile!['rating'] as num).toStringAsFixed(1)}',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  '(${task.posterProfile!['review_count'] ?? 0} reviews)',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Verified badge if applicable
                    if (task.posterProfile?['is_verified'] == true)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successExtraLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: AppColors.successLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: AppSpacing.iconSm, color: AppColors.success),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'Verified',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
            ],
            // Top section: Title and Price
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppTypography.titleMedium,
                    ),
                  ),
                  SizedBox(width: AppSpacing.lg),
                  Text(
                    currencyFormat.format(task.price),
                    style: AppTypography.titleLarge.copyWith(
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
                    width: 90,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            task.status.toUpperCase(),
                            style: AppTypography.captionMedium.copyWith(
                              color: AppColors.accent,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xxs),
                          Container(
                            height: 2,
                            width: 30,
                            color: AppColors.accent,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            '${task.offers?.length ?? 0} Offer${(task.offers?.length ?? 0) != 1 ? 's' : ''}',
                            style: AppTypography.captionMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  // Image, Details, and View button
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  child: (task.images != null && task.images!.isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: task.images!.first,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Shimmer.fromColors(
                                            baseColor: AppColors.gray300,
                                            highlightColor: AppColors.gray100,
                                            child: Container(
                                              color: AppColors.white,
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.error_outline, color: AppColors.error, size: AppSpacing.iconMd),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.backgroundTertiary,
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                          ),
                                          child: Icon(Icons.image_outlined, color: AppColors.textTertiary, size: AppSpacing.iconMd),
                                        ),
                                ),
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: AppSpacing.iconSm, color: AppColors.textSecondary),
                                      SizedBox(width: AppSpacing.xs),
                                      Text(
                                        _getFormattedDate(task.scheduledTime),
                                        style: AppTypography.captionMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: AppSpacing.iconSm, color: AppColors.textSecondary),
                                      SizedBox(width: AppSpacing.xs),
                                      Text(
                                        task.location,
                                        style: AppTypography.captionMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            'View',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.accent,
                              fontWeight: AppTypography.bold,
                            ),
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