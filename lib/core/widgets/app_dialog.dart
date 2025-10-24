import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import '../theme/app_radius.dart';

/// AppDialog - Standardized dialog component
///
/// A reusable dialog widget with consistent styling and behavior.
///
/// Features:
/// - Multiple variants (info, success, warning, error, confirmation)
/// - Title and message support
/// - Custom content support
/// - Primary and secondary actions
/// - Icon support
/// - Dismissible/non-dismissible
/// - Loading state
/// - Custom width
///
/// Usage:
/// ```dart
/// // Simple confirmation
/// AppDialog.show(
///   context: context,
///   title: 'Delete Task?',
///   message: 'This action cannot be undone.',
///   variant: AppDialogVariant.warning,
///   primaryButtonText: 'Delete',
///   secondaryButtonText: 'Cancel',
///   onPrimaryPressed: () => deleteTask(),
/// );
///
/// // Success dialog
/// AppDialog.showSuccess(
///   context: context,
///   title: 'Task Created!',
///   message: 'Your task has been posted successfully.',
/// );
///
/// // Custom content
/// AppDialog.show(
///   context: context,
///   title: 'Custom Dialog',
///   content: YourCustomWidget(),
/// );
/// ```
class AppDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final AppDialogVariant variant;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final bool barrierDismissible;
  final bool isLoading;
  final double? width;

  const AppDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.icon,
    this.variant = AppDialogVariant.info,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.barrierDismissible = true,
    this.isLoading = false,
    this.width,
  });

  /// Show a dialog
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? message,
    Widget? content,
    IconData? icon,
    AppDialogVariant variant = AppDialogVariant.info,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
    bool isLoading = false,
    double? width,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppDialog(
        title: title,
        message: message,
        content: content,
        icon: icon,
        variant: variant,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        barrierDismissible: barrierDismissible,
        isLoading: isLoading,
        width: width,
      ),
    );
  }

  /// Show a success dialog
  static Future<T?> showSuccess<T>({
    required BuildContext context,
    String? title,
    String? message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return show<T>(
      context: context,
      title: title ?? 'Success',
      message: message,
      variant: AppDialogVariant.success,
      icon: Icons.check_circle,
      primaryButtonText: buttonText ?? 'OK',
      onPrimaryPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }

  /// Show an error dialog
  static Future<T?> showError<T>({
    required BuildContext context,
    String? title,
    String? message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return show<T>(
      context: context,
      title: title ?? 'Error',
      message: message ?? 'Something went wrong. Please try again.',
      variant: AppDialogVariant.error,
      icon: Icons.error,
      primaryButtonText: buttonText ?? 'OK',
      onPrimaryPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }

  /// Show a warning dialog
  static Future<T?> showWarning<T>({
    required BuildContext context,
    String? title,
    String? message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return show<T>(
      context: context,
      title: title ?? 'Warning',
      message: message,
      variant: AppDialogVariant.warning,
      icon: Icons.warning,
      primaryButtonText: buttonText ?? 'OK',
      onPrimaryPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }

  /// Show a confirmation dialog
  static Future<bool?> showConfirmation({
    required BuildContext context,
    String? title,
    String? message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show<bool>(
      context: context,
      title: title ?? 'Confirm',
      message: message ?? 'Are you sure?',
      variant: AppDialogVariant.confirmation,
      icon: Icons.help_outline,
      primaryButtonText: confirmText ?? 'Confirm',
      secondaryButtonText: cancelText ?? 'Cancel',
      onPrimaryPressed: () {
        Navigator.of(context).pop(true);
        onConfirm?.call();
      },
      onSecondaryPressed: () {
        Navigator.of(context).pop(false);
        onCancel?.call();
      },
    );
  }

  /// Show a loading dialog
  static Future<T?> showLoading<T>({
    required BuildContext context,
    String? message,
  }) {
    return show<T>(
      context: context,
      message: message ?? 'Loading...',
      isLoading: true,
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xl,
      ),
      child: Container(
        width: width ?? 320,
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            if (icon != null || isLoading) ...[
              isLoading
                  ? const CircularProgressIndicator()
                  : Icon(
                      icon,
                      size: 48,
                      color: _getIconColor(),
                    ),
              SizedBox(height: AppSpacing.lg),
            ],

            // Title
            if (title != null) ...[
              Text(
                title!,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.md),
            ],

            // Message
            if (message != null) ...[
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.lg),
            ],

            // Custom content
            if (content != null) ...[
              content!,
              SizedBox(height: AppSpacing.lg),
            ],

            // Actions
            if (!isLoading) _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (primaryButtonText == null && secondaryButtonText == null) {
      return const SizedBox.shrink();
    }

    // Single button
    if (secondaryButtonText == null) {
      return SizedBox(
        width: double.infinity,
        child: AppButton(
          text: primaryButtonText ?? 'OK',
          onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
          variant: _getPrimaryButtonVariant(),
        ),
      );
    }

    // Two buttons
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: secondaryButtonText!,
            onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
            variant: AppButtonVariant.secondary,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppButton(
            text: primaryButtonText ?? 'OK',
            onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
            variant: _getPrimaryButtonVariant(),
          ),
        ),
      ],
    );
  }

  Color _getIconColor() {
    switch (variant) {
      case AppDialogVariant.success:
        return AppColors.success;
      case AppDialogVariant.error:
        return AppColors.error;
      case AppDialogVariant.warning:
        return AppColors.warning;
      case AppDialogVariant.info:
      case AppDialogVariant.confirmation:
        return AppColors.info;
    }
  }

  AppButtonVariant _getPrimaryButtonVariant() {
    switch (variant) {
      case AppDialogVariant.error:
        return AppButtonVariant.danger;
      case AppDialogVariant.warning:
      case AppDialogVariant.confirmation:
        return AppButtonVariant.primary;
      case AppDialogVariant.success:
      case AppDialogVariant.info:
        return AppButtonVariant.primary;
    }
  }
}

/// Dialog variant options
enum AppDialogVariant {
  /// Information dialog
  info,

  /// Success dialog
  success,

  /// Warning dialog
  warning,

  /// Error dialog
  error,

  /// Confirmation dialog
  confirmation,
}
