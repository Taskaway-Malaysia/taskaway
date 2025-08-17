import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key for storing onboarding completion in SharedPreferences
const String _onboardingKey = 'onboarding_completed';

/// Provider to track whether the user has completed the onboarding flow
/// This provider reads from SharedPreferences to persist the state
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingKey) ?? false;
});

/// Method to mark onboarding as completed and persist it
Future<void> completeOnboarding(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingKey, true);
  // Invalidate the provider to force a refresh
  ref.invalidate(onboardingCompletedProvider);
}

/// Method to reset onboarding (useful for testing or app settings)
Future<void> resetOnboarding(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_onboardingKey);
  // Invalidate the provider to force a refresh
  ref.invalidate(onboardingCompletedProvider);
}