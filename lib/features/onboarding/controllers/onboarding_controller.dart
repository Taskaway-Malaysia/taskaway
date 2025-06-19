import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track whether the user has completed the onboarding flow
final onboardingCompletedProvider = StateProvider<bool>((ref) => false);
