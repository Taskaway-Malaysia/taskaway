import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Hero Image Section - extends to top of screen
          Container(
            width: double.infinity,
            height: screenHeight * 0.46, // Approximately 393px on standard screen
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/landing_hero.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSpacing.xxl), // Small spacing from image
                    // Title
                    Text(
                      'Find the perfect freelance services for your business',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202020),
                        height: 1.22,
                        letterSpacing: 0.24,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      'Explore a vast marketplace of talented freelancers offering a wide range of services to help your business thrive.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF575656),
                        height: 1.22,
                        letterSpacing: 0.14,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: AppSpacing.xxl),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFDB5B),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.smMd,
                            side: const BorderSide(
                              color: Color(0xFFFFC333),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          context.go('/create-account');
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: Colors.black,
                          side: const BorderSide(
                            color: Color(0xFFE4E4E4),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.smMd,
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 19),

                    // Explore as guest
                    GestureDetector(
                      onTap: () {
                        // Set guest mode and navigate to home
                        ref.read(isGuestModeProvider.notifier).state = true;
                        context.go('/home');
                      },
                      child: Text(
                        'Explore as guest',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFC333),
                          letterSpacing: 0.14,
                        ),
                      ),
                    ),
                  ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}