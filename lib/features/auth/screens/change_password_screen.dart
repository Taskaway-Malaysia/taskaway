import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import '../../../core/widgets/qwerty_overlay.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ChangePasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureRepeatPassword = true;
  final _newPasswordFocusNode = FocusNode();
  final _repeatPasswordFocusNode = FocusNode();

  void _showQwertyOverlay({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool obscureText = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return QwertyOverlay(
          previewController: controller,
          obscureText: obscureText,
          onCharacterPressed: (char) {
            // setState is not strictly needed here if the controller updates the UI
            // but can be kept if other UI elements depend on the text directly
            controller.text += char;
          },
          onBackspacePressed: () {
            if (controller.text.isNotEmpty) {
              controller.text =
                  controller.text.substring(0, controller.text.length - 1);
            }
          },
          onConfirmPressed: () {
            Navigator.pop(context);
            focusNode.unfocus(); // Ensure focus is removed
          },
          confirmButtonText: 'Done',
        );
      },
    ).whenComplete(() {
      // Ensure focus is removed if the sheet is dismissed by other means
      if (mounted) {
        focusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _repeatPasswordFocusNode.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authControllerProvider.notifier).updatePassword(_newPasswordController.text);
        // Sign out the user to terminate the recovery session
        await ref.read(authControllerProvider.notifier).signOut();
        if (mounted) {
          context.go('/change-password-success');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppSpacing.huge),
                  Text(
                    'Change Your Password',
                    style: AppTypography.headlineMedium,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Enter a new password below to change your password for ${widget.email}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.huge),
                  GestureDetector(
                    onTap: () {
                      _newPasswordFocusNode.requestFocus();
                      _showQwertyOverlay(
                        context: context,
                        controller: _newPasswordController,
                        focusNode: _newPasswordFocusNode,
                        obscureText: _obscureNewPassword,
                      );
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _newPasswordController,
                        focusNode: _newPasswordFocusNode,
                        readOnly: true,
                        obscureText: _obscureNewPassword,
                        decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Must include at least 8 characters';
                      }
                      return null;
                    },
                  ), // Closes TextFormField
                ), // Closes AbsorbPointer
              ), // Closes GestureDetector
                  SizedBox(height: AppSpacing.lg),
                  GestureDetector(
                    onTap: () {
                      _repeatPasswordFocusNode.requestFocus();
                      _showQwertyOverlay(
                        context: context,
                        controller: _repeatPasswordController,
                        focusNode: _repeatPasswordFocusNode,
                        obscureText: _obscureRepeatPassword,
                      );
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _repeatPasswordController,
                        focusNode: _repeatPasswordFocusNode,
                        readOnly: true,
                        obscureText: _obscureRepeatPassword,
                        decoration: InputDecoration(
                      labelText: 'Repeat Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureRepeatPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureRepeatPassword = !_obscureRepeatPassword),
                      ),
                    ),
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ), // Closes TextFormField
                ), // Closes AbsorbPointer
              ), // Closes GestureDetector
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Must include at least 8 characters',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.huge),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? SizedBox(
                            height: AppSpacing.xl,
                            width: AppSpacing.xl,
                            child: CircularProgressIndicator(
                              color: AppColors.textInverted,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Reset Password', style: AppTypography.labelLarge),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
