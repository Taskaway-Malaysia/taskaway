import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/auth/screens/change_password_screen.dart';
import 'package:taskaway/features/auth/screens/change_password_success_screen.dart';
import 'package:taskaway/features/auth/screens/forgot_password_screen.dart';
import 'package:taskaway/features/auth/widgets/guest_prompt_overlay.dart';
import 'package:taskaway/features/onboarding/screens/onboarding_screen.dart';
import 'package:taskaway/core/providers/deep_link_provider.dart';
import 'package:taskaway/core/providers/router_refresh_notifier.dart';
import 'dart:developer' as dev; // For logging
import '../features/landing/screens/landing_screen.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/create_account_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/create_profile_screen.dart';
import '../features/auth/screens/signup_success_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/map_home_screen.dart';
import '../features/tasks/screens/create_task_screen.dart';
import '../features/tasks/screens/create_task_single_page_screen.dart';
import '../features/tasks/screens/task_details_screen_new.dart';
import '../features/tasks/screens/apply_task_screen.dart';
import '../features/tasks/screens/offer_accepted_success_screen.dart';
import '../features/tasks/screens/map_location_picker_screen.dart';
import '../features/tasks/screens/waiting_for_tasker_screen.dart';
import '../features/payments/screens/payment_success_screen.dart';
import '../features/payments/screens/chip_payment_screen.dart';
import '../features/payments/screens/chip_success_screen.dart';
import '../features/tasks/screens/find_tasker_map_screen.dart';
import '../features/tasks/screens/tasker_details_screen.dart';
import '../features/home/screens/activity_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/admin/screens/admin_tools_screen.dart';
import '../core/services/analytics_service.dart';
import '../core/widgets/responsive_layout.dart';
import 'profile_router.dart';
import 'chat_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final analytics = ref.read(analyticsServiceProvider);
  final routerRefresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    observers: [analytics.observer],
    initialLocation: '/',
    refreshListenable: routerRefresh,
    redirect: (BuildContext context, GoRouterState state) async {
      final String location = state.uri.toString(); // Use full URI

      // CHIP payment returns are handled by WebView in chip_payment_screen.dart
      // No router redirect needed - WebView handles navigation directly

      // Check for pending deep links from our service
      final pendingDeepLink = ref.read(deepLinkProvider);
      if (pendingDeepLink != null && location != pendingDeepLink) {
        print('GoRouter Redirect: Processing pending deep link: $pendingDeepLink');
        // Clear the pending deep link to avoid infinite redirects
        ref.read(deepLinkProvider.notifier).clearPendingDeepLink();
        // Navigate to the deep link URL
        return pendingDeepLink;
      }
      
      // Use ref.read for providers within redirect to avoid assertion errors
      final authValue =
          ProviderScope.containerOf(context).read(authStateProvider);
      final user = authValue.asData?.value.session?.user;
      final bool isLoggedIn = user != null;
      final bool isGuest =
          ProviderScope.containerOf(context).read(isGuestModeProvider);

      print(
          'GoRouter Redirect: Loc: $location, User: ${user?.id}, LoggedIn: $isLoggedIn, Guest: $isGuest');

      // Base public routes accessible to anyone, including guests if not specifically redirected elsewhere
      final basePublicRoutes = [
        '/',
        '/login',
        '/create-account',
        '/otp-verification',
        '/signup-success',
        '/guest-prompt',
        '/forgot-password',
        '/change-password',
        '/change-password-success',
        '/onboarding'
      ];

      // Profile editing routes for authenticated users
      final profileEditingRoutes = [
        '/edit-profile',
        '/edit-skills',
        '/edit-works',
        '/settings',
        '/my-reviews',
        '/payment-options',
        '/payment-history',
        '/payment-methods'
      ];
      // Define routes that are part of the profile creation flow
      final profileCreationRoutes = ['/create-profile', '/signup-success'];
      // Define routes for password recovery flow
      final passwordRecoveryRoutes = [
        '/change-password',
        '/change-password-success'
      ];

      // Guest mode logic
      if (isGuest && isLoggedIn) {
        print(
            'GoRouter Redirect: User is logged in while in guest mode. Turning off guest mode.');
        // Schedule as a microtask to avoid modifying state during build/redirect.
        await Future.microtask(
            () => ref.read(isGuestModeProvider.notifier).state = false);
        // Redirect will re-run due to authState change or next navigation attempt.
        // For this run, let it proceed; the state will be updated for the next evaluation.
      } else if (isGuest && !isLoggedIn) {
        // APPLE-REVIEW: Allow guests to browse home page
        // Only prompt login when they try to add/view tasks

        // Define guest-allowed routes
        final guestAllowedRoutes = [
          ...basePublicRoutes, // Landing, login, signup, etc.
          '/home/browse', // Browse/map home screen
        ];

        // Routes that require login (show guest prompt)
        final loginRequiredRoutes = [
          '/create-task', // Creating a task requires login
        ];

        // Check if guest is trying to access an allowed location
        if (guestAllowedRoutes.contains(location)) {
          print('GoRouter Redirect: Guest accessing allowed area $location.');
          return null; // Allow access
        }

        // Block task details (any path like /home/browse/123 or /home/tasks/456)
        if (location.startsWith('/home/browse/') || location.startsWith('/home/tasks/')) {
          print('GoRouter Redirect: Guest trying to view task details $location. Redirecting to /guest-prompt.');
          return '/guest-prompt';
        }

        // Block explicit login-required routes
        if (loginRequiredRoutes.any((route) => location.startsWith(route))) {
          print('GoRouter Redirect: Guest trying to create task $location. Redirecting to /guest-prompt.');
          return '/guest-prompt';
        }

        // Any other restricted area
        print('GoRouter Redirect: Guest trying to access restricted area $location. Redirecting to /guest-prompt.');
        return '/guest-prompt';
      }

      // ---- If not a guest (or guest mode was just turned off and isGuest will be false on next run) ----

      // Authenticated user logic (or user who just logged in, causing guest mode to turn off)
      if (isLoggedIn) {
        // User is logged in
        bool hasProfile = false;
        // Ensure user is not null before trying to fetch profile
        try {
          // Use the profile provider instead of direct query to leverage caching
          final profileAsync = ProviderScope.containerOf(context).read(currentProfileProvider);

          // If profile data is available, use it
          if (profileAsync.hasValue) {
            hasProfile = profileAsync.value != null;
            print('GoRouter Redirect: User ${user.id} hasProfile from cache: $hasProfile');
          } else {
            // Fallback to direct query only if profile provider hasn't loaded yet
            final profileResponse = await Supabase.instance.client
                .from('taskaway_profiles')
                .select('id')
                .eq('id', user.id) // Use user.id from auth
                .maybeSingle();
            hasProfile = profileResponse != null;
            print('GoRouter Redirect: User ${user.id} hasProfile from query: $hasProfile');
          }
        } catch (e) {
          print(
              'GoRouter Redirect: Error checking profile for ${user.id}: $e. Allowing navigation to continue.');
          // On error, assume profile exists to avoid redirect loops
          // The app will handle missing profile when actually needed
          hasProfile = true;
        }

        // TASK-187 FIX: Re-enabled profile check after implementing auto-profile trigger
        // The trigger ensures all users have profiles, so this check now safely handles edge cases
        if (!hasProfile &&
            !profileCreationRoutes.contains(location) &&
            location != '/login') {
          print(
              'GoRouter Redirect: Logged in, no profile. Redirecting to /create-profile.');
          return '/create-profile';
        }

        // If logged in and has profile, but on a public route (like /login) or profile creation route
        // (excluding '/', which is LandingScreen, and auth in-progress routes like OTP)
        final isOnPasswordRecoveryRoute =
            passwordRecoveryRoutes.contains(location);
        print(
            'GoRouter Redirect: Check passwordRecoveryRoutes.contains($location): $isOnPasswordRecoveryRoute. Routes: $passwordRecoveryRoutes');

        if (hasProfile &&
                basePublicRoutes
                    .contains(location) && // Is it a general public route?
                !profileCreationRoutes
                    .contains(location) && // Not part of profile creation flow?
                !isOnPasswordRecoveryRoute && // Not part of password recovery flow?
                !profileEditingRoutes
                    .contains(location) && // Not part of profile editing flow?
                !location
                    .startsWith('/home') // Not already in a /home section?
            ) {
          print(
              'GoRouter Redirect: Logged in with profile, on a generic public page ($location) that is not home, profile, or recovery flow. Redirecting to /home/browse.');
          return '/home/browse';
        }
      } else {
        // Not logged in (and not a guest, or guest logic already handled returning null)
        if (!basePublicRoutes.contains(location) &&
            !profileEditingRoutes.contains(location) &&
            location != '/guest-prompt') {
          print(
              'GoRouter Redirect: Not logged in (and not guest), trying to access $location. Redirecting to /.');
          return '/';
        }

        // If not logged in but trying to access profile editing routes, redirect to landing
        if (profileEditingRoutes.contains(location)) {
          print(
              'GoRouter Redirect: Not logged in, trying to access profile editing route $location. Redirecting to /.');
          return '/';
        }
      }
      print('GoRouter Redirect: No redirect needed for $location.');
      return null;
    },
    routes: [
      // Routes that should not have the boxed layout.
      GoRoute(
        path: '/',
        name: 'landing',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LandingScreen(),
      ),
      // All other routes will be placed inside this ShellRoute for the boxed layout.
      ShellRoute(
        builder: (context, state, child) {
          return ResponsiveLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/guest-prompt',
            name: 'guest-prompt',
            builder: (context, state) => const GuestPromptOverlay(),
          ),
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/create-account',
            name: 'create-account',
            builder: (context, state) => const CreateAccountScreen(),
          ),
          GoRoute(
            path: '/otp-verification',
            name: 'otp-verification',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>? ?? {};
              return OtpVerificationScreen(
                email: args['email'] as String? ?? 'no-email-provided',
                type: args['type'] as OtpType? ?? OtpType.signup,
              );
            },
          ),
          GoRoute(
            path: '/create-profile',
            name: 'create-profile',
            builder: (context, state) => const CreateProfileScreen(),
          ),
          GoRoute(
            path: '/signup-success',
            name: 'signup-success',
            builder: (context, state) => const SignupSuccessScreen(),
          ),
          GoRoute(
            path: '/forgot-password',
            name: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/change-password',
            name: 'change-password',
            builder: (context, state) {
              final email = state.extra as String? ?? 'no-email-provided';
              return ChangePasswordScreen(email: email);
            },
          ),
          GoRoute(
            path: '/change-password-success',
            name: 'change-password-success',
            builder: (context, state) => const ChangePasswordSuccessScreen(),
          ),
          GoRoute(
            path: '/onboarding',
            name: 'onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/payment/success',
            name: 'payment-success',
            builder: (context, state) {
              final extra = (state.extra as Map?) ?? {};
              return PaymentSuccessScreen(
                amount: (extra['amount'] as num).toDouble(),
                taskTitle: extra['taskTitle'] as String,
              );
            },
          ),
          // CHIP payment success - must be before wildcard /payment/:id
          GoRoute(
            path: '/payment/chip-success',
            name: 'chip-success',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return ChipSuccessScreen(
                taskId: extra['taskId'] as String,
                amount: extra['amount'] as double,
                taskTitle: extra['taskTitle'] as String,
                paymentType: extra['paymentType'] as String?,
              );
            },
          ),
          // Find tasker map screen
          GoRoute(
            path: '/tasks/:taskId/find-tasker',
            name: 'find-tasker',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              return FindTaskerMapScreen(taskId: taskId);
            },
          ),
          // Tasker details screen
          GoRoute(
            path: '/tasks/:taskId/tasker/:taskerId',
            name: 'tasker-details',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              final taskerId = state.pathParameters['taskerId']!;
              return TaskerDetailsScreen(
                taskId: taskId,
                taskerId: taskerId,
              );
            },
          ),
          // Payment callback routes removed - using CHIPP payment flow with deep links instead
          GoRoute(
            path: '/admin-tools',
            name: 'admin-tools',
            builder: (context, state) => const AdminToolsScreen(),
          ),
          ShellRoute(
            builder: (context, state, child) => HomeScreen(child: child),
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                redirect: (context, state) => '/home/browse',
              ),
              GoRoute(
                path: '/home/browse',
                name: 'browse',
                builder: (context, state) => const MapHomeScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'task-details',
                    builder: (context, state) => TaskDetailsScreenNew(
                      taskId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'apply',
                        name: 'apply-task',
                        builder: (context, state) => ApplyTaskScreen(
                          taskId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'offer-accepted-success/:price',
                        builder: (context, state) {
                          final price = double.tryParse(
                                  state.pathParameters['price'] ?? '0.0') ??
                              0.0;
                          // Get taskId from the parent route
                          final taskId = state.pathParameters['id'];
                          return OfferAcceptedSuccessScreen(
                            price: price,
                            taskId: taskId,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/home/activity',
                name: 'activity',
                builder: (context, state) => const ActivityScreen(),
              ),
              GoRoute(
                path: '/home/tasks',
                name: 'tasks',
                builder: (context, state) => const MapHomeScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'task-details-from-tasks',
                    builder: (context, state) => TaskDetailsScreenNew(
                      taskId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'apply',
                        name: 'apply-task-from-tasks',
                        builder: (context, state) => ApplyTaskScreen(
                          taskId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/create-task',
                name: 'create-task',
                builder: (context, state) => const CreateTaskSinglePageScreen(),
              ),
              GoRoute(
                path: '/map-picker',
                name: 'map-picker',
                builder: (context, state) {
                  final initialLocation = state.extra as LatLng?;
                  return MapLocationPickerScreen(
                    initialLocation: initialLocation,
                  );
                },
              ),
              GoRoute(
                path: '/waiting-for-tasker/:taskId',
                name: 'waiting-for-tasker',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId']!;
                  return WaitingForTaskerScreen(taskId: taskId);
                },
              ),
              GoRoute(
                path: '/chip-payment',
                name: 'chip-payment',
                builder: (context, state) {
                  if (state.extra == null) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: const Center(
                        child: Text('Missing payment data. Please try again.'),
                      ),
                    );
                  }
                  final extra = state.extra as Map<String, dynamic>;
                  return ChipPaymentScreen(
                    checkoutUrl: extra['checkoutUrl'] as String,
                    taskId: extra['taskId'] as String,
                    amount: extra['amount'] as double,
                    taskTitle: extra['taskTitle'] as String,
                    paymentType: extra['paymentType'] as String?,
                    applicationId: extra['applicationId'] as String?,
                    taskerId: extra['taskerId'] as String?,
                    chipPaymentId: extra['chipPaymentId'] as String?,
                  );
                },
              ),
              ...ProfileRouter.routes,
              ...ChatRouter.routes,
              GoRoute(
                path: '/notifications',
                name: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: '/home/post-task',
                name: 'post-task',
                builder: (context, state) =>
                    const SizedBox(), // Placeholder, will be handled by HomeScreen
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
