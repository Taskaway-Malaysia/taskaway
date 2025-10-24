import 'package:flutter/material.dart';
import '../../tasks/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class ServiceCard extends StatelessWidget {
  final Task task;
  final String distance;
  final VoidCallback onViewDetails;
  final bool isFocused;

  const ServiceCard({
    super.key,
    required this.task,
    required this.distance,
    required this.onViewDetails,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    final posterName = task.posterProfile?['full_name'] as String? ?? 'Unknown User';

    return Container(
      decoration: BoxDecoration(
        color: isFocused ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: const Color(0xFFFCC133),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              task.title,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.gray900,
                fontWeight: AppTypography.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.xs),

            // Distance
            Text(
              distance,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray900,
              ),
            ),
            SizedBox(height: 2),

            // Posted by (without "By" prefix)
            Text(
              'By $posterName',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.gray900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.sm),

            // Price
            Text(
              'RM ${task.price.toStringAsFixed(2)}',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: AppTypography.bold,
                color: AppColors.gray900,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // View Details Button
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: onViewDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gray900,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  elevation: 0,
                  minimumSize: Size(0, 32),
                ),
                child: Text(
                  'View Details',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: AppTypography.bold,
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