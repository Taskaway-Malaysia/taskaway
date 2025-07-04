import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/features/onboarding/controllers/onboarding_controller.dart';
import 'package:taskaway/features/onboarding/models/onboarding_page_model.dart';
import 'dart:developer' as dev;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: StyleConstants.defaultAnimationDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    dev.log('Onboarding completed');
    // Mark onboarding as completed
    ref.read(onboardingCompletedProvider.notifier).state = true;
    // Navigate to login screen
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The background color for the area behind the content
      backgroundColor: _currentPage == 1
          ? const Color(0xFFFEF9E7) // Light yellow for second page
          : const Color(0xFFEFEEFC), // Light purple for first and third pages
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingPages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return OnboardingPageContent(
                    page: onboardingPages[index],
                  );
                },
              ),
            ),
            // White container for bottom content
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 30, bottom: 20, left: 24, right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    onboardingPages[_currentPage].title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    onboardingPages[_currentPage].description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Pagination indicators
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        onboardingPages.length,
                        (index) => AnimatedContainer(
                          duration: StyleConstants.defaultAnimationDuration,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? _currentPage == 1
                                    ? StyleConstants.taskerColorPrimary // Orange for second page
                                    : StyleConstants.posterColorPrimary // Purple for first and third pages
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Skip button
                        TextButton(
                          onPressed: _skipOnboarding,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Next/Get Started button
                        ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentPage == 1
                                ? StyleConstants.taskerColorPrimary // Orange for second page
                                : StyleConstants.posterColorPrimary, // Purple for first and third pages
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
                            ),
                            minimumSize: const Size(0, 48), // Keep the height from the theme
                          ),
                          child: Text(
                            _currentPage == onboardingPages.length - 1 ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageContent extends StatelessWidget {
  final OnboardingPageModel page;

  const OnboardingPageContent({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image only - takes most of the space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
              child: Image.asset(
                page.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Empty space where the white container will be
          const SizedBox(height: 120), // This will be covered by the white container
        ],
      ),
    );
  }
}
