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
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              task.title,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.gray900,
                fontWeight: AppTypography.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.sm),

            // Distance
            Text(
              distance,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray900,
              ),
            ),
            SizedBox(height: AppSpacing.xs),

            // Posted by (without "By" prefix)
            Text(
              'By $posterName',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.md),

            // Price
            Text(
              'RM ${task.price.toStringAsFixed(2)}',
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: AppTypography.bold,
                color: AppColors.gray900,
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // View Details Button
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightLg,
              child: ElevatedButton(
                onPressed: onViewDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gray900,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'View Details',
                  style: AppTypography.titleMedium.copyWith(
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