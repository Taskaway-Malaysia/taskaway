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
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    task.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.gray900,
                      fontWeight: AppTypography.bold,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),

                  // Distance
                  Text(
                    distance,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.gray900,
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 1),

                  // Posted by (without "By" prefix)
                  Text(
                    'By $posterName',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.gray900,
                      fontSize: 10,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),

            // Right side - Price and Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price
                Text(
                  'RM ${task.price.toStringAsFixed(2)}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: AppTypography.bold,
                    color: AppColors.gray900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4),

                // View Details Button
                SizedBox(
                  height: 24,
                  child: ElevatedButton(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gray900,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                      minimumSize: const Size(0, 24),
                    ),
                    child: Text(
                      'View Details',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: AppTypography.semiBold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}