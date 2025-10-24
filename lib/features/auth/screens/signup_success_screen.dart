import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/style_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'dart:developer' as dev;

class SignupSuccessScreen extends ConsumerWidget {
  const SignupSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Success icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: StyleConstants.taskerColorPrimary,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.white,
                    size: 40,
                  ),
                ),
              ),
              
              SizedBox(height: AppSpacing.xxl),
              
              // Success message
              Text(
                'You have successfully signed up!',
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall,
              ),
              
              const Spacer(),
              
              // Get Started button
              ElevatedButton(
                onPressed: () {
                  
                  print('Navigating from signup success to home');
                  // Navigate to home screen
                  context.go('/home');
                },
                child: Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
