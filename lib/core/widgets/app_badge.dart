import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

/// AppBadge - Standardized badge component
///
/// A reusable badge widget for labels, status indicators, counts, and notifications.
///
/// Features:
/// - Multiple variants (primary, secondary, success, error, warning, info)
/// - Multiple sizes (small, medium, large)
/// - Dot badges for minimal indicators
/// - Count badges for notifications
/// - Label badges for status
/// - Icon support
/// - Customizable colors
/// - Rounded or pill shapes
///
/// Usage:
/// ```dart
/// // Status badge
/// AppBadge.label(
///   label: 'Active',
///   variant: AppBadgeVariant.success,
/// )
///
/// // Count badge
/// AppBadge.count(
///   count: 5,
///   variant: AppBadgeVariant.error,
/// )
///
/// // Dot badge
/// AppBadge.dot(
///   color: AppColors.statusOnline,
/// )
///
/// // With icon
/// AppBadge.label(
///   label: 'Verified',
///   icon: Icons.verified,
///   variant: AppBadgeVariant.primary,
/// )
/// ```
class AppBadge extends StatelessWidget {
  final String? label;
  final int? count;
  final IconData? icon;
  final AppBadgeVariant variant;
  final AppBadgeSize size;
  final AppBadgeShape shape;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final bool showBorder;
  final VoidCallback? onTap;

  const AppBadge({
    super.key,
    this.label,
    this.count,
    this.icon,
    this.variant = AppBadgeVariant.primary,
    this.size = AppBadgeSize.medium,
    this.shape = AppBadgeShape.rounded,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.showBorder = false,
    this.onTap,
  });

  /// Create a label badge
  const AppBadge.label({
    super.key,
    required this.label,
    this.icon,
    this.variant = AppBadgeVariant.primary,
    this.size = AppBadgeSize.medium,
    this.shape = AppBadgeShape.rounded,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.showBorder = false,
    this.onTap,
  }) : count = null;

  /// Create a count badge
  const AppBadge.count({
    super.key,
    required this.count,
    this.variant = AppBadgeVariant.error,
    this.size = AppBadgeSize.small,
    this.shape = AppBadgeShape.pill,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.showBorder = false,
    this.onTap,
  })  : label = null,
        icon = null;

  /// Create a dot badge (minimal indicator)
  const AppBadge.dot({
    super.key,
    this.variant = AppBadgeVariant.primary,
    this.backgroundColor,
    this.borderColor,
    this.showBorder = false,
    this.onTap,
  })  : label = null,
        count = null,
        icon = null,
        size = AppBadgeSize.small,
        shape = AppBadgeShape.pill,
        textColor = null;

  @override
  Widget build(BuildContext context) {
    final isDot = label == null && count == null && icon == null;

    Widget badge = Container(
      padding: _getPadding(isDot),
      decoration: BoxDecoration(
        color: backgroundColor ?? _getBackgroundColor(),
        borderRadius: _getBorderRadius(isDot),
        border: showBorder
            ? Border.all(
                color: borderColor ?? _getBorderColor(),
                width: 1.0,
              )
            : null,
      ),
      child: isDot ? null : _buildContent(),
    );

    if (onTap != null) {
      badge = InkWell(
        onTap: onTap,
        borderRadius: _getBorderRadius(isDot),
        child: badge,
      );
    }

    return badge;
  }

  Widget _buildContent() {
    final fontSize = _getFontSize();
    final iconSize = _getIconSize();

    final children = <Widget>[];

    // Add icon
    if (icon != null) {
      children.add(
        Icon(
          icon,
          size: iconSize,
          color: textColor ?? _getTextColor(),
        ),
      );
    }

    // Add spacing
    if (icon != null && (label != null || count != null)) {
      children.add(SizedBox(width: AppSpacing.xs));
    }

    // Add label or count
    if (count != null) {
      final displayCount = count! > 99 ? '99+' : count.toString();
      children.add(
        Text(
          displayCount,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor ?? _getTextColor(),
            fontFamily: AppTypography.fontFamily,
          ),
        ),
      );
    } else if (label != null) {
      children.add(
        Text(
          label!,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor ?? _getTextColor(),
            fontFamily: AppTypography.fontFamily,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  EdgeInsetsGeometry _getPadding(bool isDot) {
    if (isDot) {
      return EdgeInsets.zero;
    }

    switch (size) {
      case AppBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case AppBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case AppBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  BorderRadius _getBorderRadius(bool isDot) {
    if (isDot) {
      return AppRadius.sm;
    }

    switch (shape) {
      case AppBadgeShape.rounded:
        return AppRadius.sm;
      case AppBadgeShape.pill:
        return AppRadius.full;
      case AppBadgeShape.square:
        return BorderRadius.zero;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppBadgeSize.small:
        return 10.0;
      case AppBadgeSize.medium:
        return 12.0;
      case AppBadgeSize.large:
        return 14.0;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppBadgeSize.small:
        return 12.0;
      case AppBadgeSize.medium:
        return 14.0;
      case AppBadgeSize.large:
        return 16.0;
    }
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case AppBadgeVariant.primary:
        return AppColors.primary;
      case AppBadgeVariant.secondary:
        return AppColors.gray100;
      case AppBadgeVariant.success:
        return AppColors.successLight;
      case AppBadgeVariant.error:
        return AppColors.error;
      case AppBadgeVariant.warning:
        return AppColors.warningLight;
      case AppBadgeVariant.info:
        return AppColors.infoLight;
      case AppBadgeVariant.outline:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case AppBadgeVariant.primary:
        return AppColors.textPrimary;
      case AppBadgeVariant.secondary:
        return AppColors.textSecondary;
      case AppBadgeVariant.success:
        return AppColors.successDark;
      case AppBadgeVariant.error:
        return AppColors.white;
      case AppBadgeVariant.warning:
        return AppColors.warningDark;
      case AppBadgeVariant.info:
        return AppColors.infoDark;
      case AppBadgeVariant.outline:
        return AppColors.textPrimary;
    }
  }

  Color _getBorderColor() {
    switch (variant) {
      case AppBadgeVariant.primary:
        return AppColors.primary;
      case AppBadgeVariant.secondary:
        return AppColors.gray300;
      case AppBadgeVariant.success:
        return AppColors.success;
      case AppBadgeVariant.error:
        return AppColors.error;
      case AppBadgeVariant.warning:
        return AppColors.warning;
      case AppBadgeVariant.info:
        return AppColors.info;
      case AppBadgeVariant.outline:
        return AppColors.borderDefault;
    }
  }
}

/// Badge variant options
enum AppBadgeVariant {
  /// Primary brand color
  primary,

  /// Neutral gray
  secondary,

  /// Success/positive state
  success,

  /// Error/negative state
  error,

  /// Warning/caution state
  warning,

  /// Information state
  info,

  /// Outline only
  outline,
}

/// Badge size options
enum AppBadgeSize {
  /// Small - 10px text, compact padding
  small,

  /// Medium - 12px text, balanced padding
  medium,

  /// Large - 14px text, spacious padding
  large,
}

/// Badge shape options
enum AppBadgeShape {
  /// Slightly rounded corners (4px)
  rounded,

  /// Fully rounded (pill shape)
  pill,

  /// Square corners
  square,
}
