import 'package:go_router/go_router.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/profile/screens/payment_options_screen.dart';
import '../features/profile/screens/payment_history_screen.dart';
import '../features/profile/screens/payment_methods_screen.dart';
import '../features/profile/screens/my_reviews_screen.dart';

/// Profile-related routes for the app
class ProfileRouter {
  static List<RouteBase> get routes => [
    GoRoute(
      path: '/home/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    // Profile edit routes (these were originally standalone in the redirect logic)
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/my-reviews',
      name: 'my-reviews',
      builder: (context, state) => const MyReviewsScreen(),
    ),
    GoRoute(
      path: '/payment-options',
      name: 'payment-options',
      builder: (context, state) => const PaymentOptionsScreen(),
    ),
    GoRoute(
      path: '/payment-history',
      name: 'payment-history',
      builder: (context, state) => const PaymentHistoryScreen(),
    ),
    GoRoute(
      path: '/payment-methods',
      name: 'payment-methods',
      builder: (context, state) => const PaymentMethodsScreen(),
    ),
  ];
}
