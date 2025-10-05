import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/core/theme/app_typography.dart';
import 'package:taskaway/core/theme/app_colors.dart';
import 'package:taskaway/core/theme/app_spacing.dart';

class ChangePasswordSuccessScreen extends StatelessWidget {
  const ChangePasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: AppColors.textInverted, size: AppSpacing.iconHuge - 4),
              ),
              SizedBox(height: AppSpacing.xxxl),
              Text(
                'You have successfully reset your password!',
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall,
              ),
              const Spacer(),
              SizedBox(height: 250),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: Text('Login', style: AppTypography.labelLarge),
              ),
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
