import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Standardized text field component for consistent form inputs
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final EdgeInsets? contentPadding;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.contentPadding,
  });

  /// Email input field
  factory AppTextField.email({
    Key? key,
    String? label,
    String? hintText,
    String? helperText,
    String? errorText,
    TextEditingController? controller,
    String? initialValue,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    FormFieldValidator<String>? validator,
  }) {
    return AppTextField(
      key: key,
      label: label ?? 'Email',
      hintText: hintText ?? 'Enter your email',
      helperText: helperText,
      errorText: errorText,
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      textCapitalization: TextCapitalization.none,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      prefixIcon: const Icon(Icons.email_outlined),
    );
  }

  /// Password input field
  factory AppTextField.password({
    Key? key,
    String? label,
    String? hintText,
    String? helperText,
    String? errorText,
    TextEditingController? controller,
    String? initialValue,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
  }) {
    return AppTextField(
      key: key,
      label: label ?? 'Password',
      hintText: hintText ?? 'Enter your password',
      helperText: helperText,
      errorText: errorText,
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: suffixIcon,
    );
  }

  /// Phone number input field
  factory AppTextField.phone({
    Key? key,
    String? label,
    String? hintText,
    String? helperText,
    String? errorText,
    TextEditingController? controller,
    String? initialValue,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    FormFieldValidator<String>? validator,
  }) {
    return AppTextField(
      key: key,
      label: label ?? 'Phone Number',
      hintText: hintText ?? 'Enter your phone number',
      helperText: helperText,
      errorText: errorText,
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      prefixIcon: const Icon(Icons.phone_outlined),
    );
  }

  /// Search input field
  factory AppTextField.search({
    Key? key,
    String? hintText,
    TextEditingController? controller,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
  }) {
    return AppTextField(
      key: key,
      hintText: hintText ?? 'Search...',
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: onClear != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
            )
          : null,
    );
  }

  /// Multiline text area
  factory AppTextField.multiline({
    Key? key,
    String? label,
    String? hintText,
    String? helperText,
    String? errorText,
    TextEditingController? controller,
    String? initialValue,
    FocusNode? focusNode,
    int maxLines = 5,
    int? minLines,
    int? maxLength,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      maxLines: maxLines,
      minLines: minLines ?? 3,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      onChanged: onChanged,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.inputLabel,
          ),
          SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          validator: validator,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          autocorrect: autocorrect,
          style: AppTypography.input,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.inputHint,
            helperText: helperText,
            helperStyle: AppTypography.inputHelper,
            errorText: errorText,
            errorStyle: AppTypography.inputError,
            filled: true,
            fillColor: enabled ? AppColors.backgroundTertiary : AppColors.backgroundDisabled,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            prefixText: prefixText,
            suffixText: suffixText,
            contentPadding: contentPadding ?? EdgeInsets.all(AppSpacing.inputPadding),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.borderFocus, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.borderError),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.borderError, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
          ),
        ),
      ],
    );
  }
}
