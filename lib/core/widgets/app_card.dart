import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Standardized card component for consistent containers
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final double? elevation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.elevation,
    this.onTap,
    this.onLongPress,
  });

  /// Card with default padding
  const AppCard.padded({
    super.key,
    required this.child,
    this.margin,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.elevation,
    this.onTap,
    this.onLongPress,
  }) : padding = const EdgeInsets.all(AppSpacing.cardPadding);

  /// Outlined card variant
  const AppCard.outlined({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
  })  : borderColor = AppColors.borderDefault,
        borderWidth = 1.0,
        elevation = 0;

  /// Elevated card variant
  const AppCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
  }) : elevation = AppSpacing.elevation2;

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd),
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: borderWidth ?? 1.0,
              )
            : null,
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: elevation! * 2,
                  offset: Offset(0, elevation! / 2),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      return Container(
        margin: margin ?? EdgeInsets.all(AppSpacing.cardMargin),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd),
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin: margin ?? EdgeInsets.all(AppSpacing.cardMargin),
      child: cardContent,
    );
  }
}

/// Info card for displaying informational messages
class AppInfoCard extends StatelessWidget {
  final String message;
  final IconData? icon;
  final AppInfoCardType type;
  final VoidCallback? onClose;

  const AppInfoCard({
    super.key,
    required this.message,
    this.icon,
    this.type = AppInfoCardType.info,
    this.onClose,
  });

  const AppInfoCard.info({
    super.key,
    required this.message,
    this.icon,
    this.onClose,
  }) : type = AppInfoCardType.info;

  const AppInfoCard.success({
    super.key,
    required this.message,
    this.icon,
    this.onClose,
  }) : type = AppInfoCardType.success;

  const AppInfoCard.warning({
    super.key,
    required this.message,
    this.icon,
    this.onClose,
  }) : type = AppInfoCardType.warning;

  const AppInfoCard.error({
    super.key,
    required this.message,
    this.icon,
    this.onClose,
  }) : type = AppInfoCardType.error;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: _getBackgroundColor(),
      borderColor: _getBorderColor(),
      borderWidth: 1.0,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(
            icon ?? _getDefaultIcon(),
            color: _getIconColor(),
            size: AppSpacing.iconLg,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 14,
              ),
            ),
          ),
          if (onClose != null) ...[
            SizedBox(width: AppSpacing.md),
            IconButton(
              icon: Icon(
                Icons.close,
                size: AppSpacing.iconMd,
                color: _getIconColor(),
              ),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case AppInfoCardType.success:
        return AppColors.successExtraLight;
      case AppInfoCardType.warning:
        return AppColors.warningExtraLight;
      case AppInfoCardType.error:
        return AppColors.errorExtraLight;
      case AppInfoCardType.info:
        return AppColors.infoExtraLight;
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case AppInfoCardType.success:
        return AppColors.success;
      case AppInfoCardType.warning:
        return AppColors.warning;
      case AppInfoCardType.error:
        return AppColors.error;
      case AppInfoCardType.info:
        return AppColors.info;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case AppInfoCardType.success:
        return AppColors.success;
      case AppInfoCardType.warning:
        return AppColors.warning;
      case AppInfoCardType.error:
        return AppColors.error;
      case AppInfoCardType.info:
        return AppColors.info;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case AppInfoCardType.success:
        return AppColors.successDark;
      case AppInfoCardType.warning:
        return AppColors.warningDark;
      case AppInfoCardType.error:
        return AppColors.errorDark;
      case AppInfoCardType.info:
        return AppColors.infoDark;
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case AppInfoCardType.success:
        return Icons.check_circle_outline;
      case AppInfoCardType.warning:
        return Icons.warning_amber_outlined;
      case AppInfoCardType.error:
        return Icons.error_outline;
      case AppInfoCardType.info:
        return Icons.info_outline;
    }
  }
}

enum AppInfoCardType {
  info,
  success,
  warning,
  error,
}
