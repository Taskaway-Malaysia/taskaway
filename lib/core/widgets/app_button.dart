import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Standardized button component for consistent UI across the app
///
/// Variants:
/// - Primary: Main call-to-action buttons (orange background)
/// - Secondary: Outlined buttons for secondary actions
/// - Text: Minimal text-only buttons
/// - Danger: Destructive actions (red)
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leftIcon,
    this.rightIcon,
    this.padding,
  });

  /// Primary button (Orange background)
  const AppButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leftIcon,
    this.rightIcon,
    this.padding,
  }) : variant = AppButtonVariant.primary;

  /// Secondary button (Outlined)
  const AppButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leftIcon,
    this.rightIcon,
    this.padding,
  }) : variant = AppButtonVariant.secondary;

  /// Text button (Minimal)
  const AppButton.text({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leftIcon,
    this.rightIcon,
    this.padding,
  }) : variant = AppButtonVariant.text;

  /// Danger button (Destructive actions)
  const AppButton.danger({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leftIcon,
    this.rightIcon,
    this.padding,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final buttonWidget = _buildButton();

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }

  Widget _buildButton() {
    switch (variant) {
      case AppButtonVariant.primary:
        return _buildPrimaryButton();
      case AppButtonVariant.secondary:
        return _buildSecondaryButton();
      case AppButtonVariant.text:
        return _buildTextButton();
      case AppButtonVariant.danger:
        return _buildDangerButton();
    }
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.backgroundDisabled,
        disabledForegroundColor: AppColors.textDisabled,
        elevation: 0,
        minimumSize: Size(0, _getButtonHeight()),
        padding: padding ?? _getButtonPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: _buildButtonContent(AppColors.white),
    );
  }

  Widget _buildSecondaryButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.textDisabled,
        side: const BorderSide(color: AppColors.borderDefault, width: 1.5),
        minimumSize: Size(0, _getButtonHeight()),
        padding: padding ?? _getButtonPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: _buildButtonContent(AppColors.textPrimary),
    );
  }

  Widget _buildTextButton() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textDisabled,
        minimumSize: Size(0, _getButtonHeight()),
        padding: padding ?? EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: _buildButtonContent(AppColors.primary),
    );
  }

  Widget _buildDangerButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.backgroundDisabled,
        disabledForegroundColor: AppColors.textDisabled,
        elevation: 0,
        minimumSize: Size(0, _getButtonHeight()),
        padding: padding ?? _getButtonPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: _buildButtonContent(AppColors.white),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: _getTextStyle().copyWith(color: textColor),
    );

    if (leftIcon == null && rightIcon == null) {
      return textWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leftIcon != null) ...[
          Icon(leftIcon, size: _getIconSize(), color: textColor),
          SizedBox(width: AppSpacing.sm),
        ],
        textWidget,
        if (rightIcon != null) ...[
          SizedBox(width: AppSpacing.sm),
          Icon(rightIcon, size: _getIconSize(), color: textColor),
        ],
      ],
    );
  }

  double _getButtonHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.buttonHeightSm;
      case AppButtonSize.medium:
        return AppSpacing.buttonHeightMd;
      case AppButtonSize.large:
        return AppSpacing.buttonHeightLg;
      case AppButtonSize.extraLarge:
        return AppSpacing.buttonHeightXl;
    }
  }

  EdgeInsets _getButtonPadding() {
    switch (size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        );
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        );
      case AppButtonSize.large:
      case AppButtonSize.extraLarge:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonPaddingHorizontal,
          vertical: AppSpacing.buttonPaddingVertical,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.labelSmall;
      case AppButtonSize.medium:
        return AppTypography.labelMedium;
      case AppButtonSize.large:
      case AppButtonSize.extraLarge:
        return AppTypography.buttonPrimary;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.iconSm;
      case AppButtonSize.medium:
        return AppSpacing.iconMd;
      case AppButtonSize.large:
      case AppButtonSize.extraLarge:
        return AppSpacing.iconLg;
    }
  }
}

enum AppButtonVariant {
  primary,
  secondary,
  text,
  danger,
}

enum AppButtonSize {
  small,
  medium,
  large,
  extraLarge,
}
