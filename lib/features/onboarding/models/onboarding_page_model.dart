import 'package:taskaway/core/constants/asset_constants.dart';
/// Model class for onboarding page content
class OnboardingPageModel {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingPageModel({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

/// List of onboarding pages with their content
final List<OnboardingPageModel> onboardingPages = [
  const OnboardingPageModel(
    imagePath: AssetConstants.onboarding_1,
    title: 'Task outsourcing made easy',
    description: 'Choose your task from our many different categories.',
  ),
  const OnboardingPageModel(
    imagePath: AssetConstants.onboarding_2,
    title: 'Browse our app for all sorts of tasks',
    description: 'From housekeeping to pet care, we\'ve got you covered.',
  ),
  const OnboardingPageModel(
    imagePath: AssetConstants.onboarding_3,
    title: 'Switch effortlessly between Poster & Tasker',
    description: 'Alternate between getting your tasks done and earning money.',
  ),
];
