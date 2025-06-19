import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/auth/screens/change_password_screen.dart';
import 'package:taskaway/features/auth/screens/change_password_success_screen.dart';
import 'package:taskaway/features/auth/screens/forgot_password_screen.dart';
import 'package:taskaway/features/auth/widgets/guest_prompt_overlay.dart';
import 'package:taskaway/features/onboarding/screens/onboarding_screen.dart';
import 'dart:developer' as dev; // For logging
import '../features/splash/screens/splash_screen.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/auth/screens/create_account_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/create_profile_screen.dart';
import '../features/auth/screens/signup_success_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/tasks/screens/my_task_screen.dart';
import '../features/tasks/screens/my_task_screen.dart';
import '../features/tasks/screens/create_task_screen.dart';
import '../features/tasks/screens/task_details_screen.dart';
import '../features/tasks/screens/apply_task_screen.dart';
import '../features/payments/screens/payment_completion_screen.dart';
import '../features/messages/screens/chat_list_screen.dart';
import '../features/messages/screens/chat_screen.dart';
import '../features/messages/models/channel.dart';
import '../features/profile/screens/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: ref.watch(authNotifierProvider),
    redirect: (BuildContext context, GoRouterState state) async {
      // Use ref.read for providers within redirect to avoid assertion errors
      final authValue =
          ProviderScope.containerOf(context).read(authStateProvider);
      final user = authValue.asData?.value.session?.user;
      final bool isLoggedIn = user != null;
      final bool isGuest =
          ProviderScope.containerOf(context).read(isGuestModeProvider);
      final String location = state.uri.toString(); // Use full URI

      dev.log(
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
      // Define routes that are part of the profile creation flow
      final profileCreationRoutes = ['/create-profile', '/signup-success'];
      // Define routes for password recovery flow
      final passwordRecoveryRoutes = [
        '/change-password',
        '/change-password-success'
      ];

      // Guest mode logic
      if (isGuest && isLoggedIn) {
        dev.log(
            'GoRouter Redirect: User is logged in while in guest mode. Turning off guest mode.');
        // Schedule as a microtask to avoid modifying state during build/redirect.
        await Future.microtask(
            () => ref.read(isGuestModeProvider.notifier).state = false);
        // Redirect will re-run due to authState change or next navigation attempt.
        // For this run, let it proceed; the state will be updated for the next evaluation.
      } else if (isGuest && !isLoggedIn) {
        // Check if guest is trying to access an allowed location
        if (basePublicRoutes.contains(location) ||
            location.startsWith('/home/browse')) {
          dev.log('GoRouter Redirect: Guest accessing allowed area $location.');
          return null; // Allow access
        } else {
          dev.log(
              'GoRouter Redirect: Guest trying to access restricted area $location. Redirecting to /guest-prompt.');
          return '/guest-prompt'; // Redirect to guest prompt
        }
      }

      // ---- If not a guest (or guest mode was just turned off and isGuest will be false on next run) ----

      // Authenticated user logic (or user who just logged in, causing guest mode to turn off)
      if (isLoggedIn) {
        // User is logged in
        bool hasProfile = false;
        // Ensure user is not null before trying to fetch profile
        try {
          final profileResponse = await Supabase.instance.client
              .from('taskaway_profiles')
              .select('id')
              .eq('id', user.id) // Use user.id from auth
              .maybeSingle();
          hasProfile = profileResponse != null;
          dev.log('GoRouter Redirect: User ${user.id} hasProfile: $hasProfile');
        } catch (e) {
          dev.log(
              'GoRouter Redirect: Error checking profile for ${user.id}: $e. Assuming no profile.');
        }

        if (!hasProfile &&
            !profileCreationRoutes.contains(location) &&
            location != '/login') {
          dev.log(
              'GoRouter Redirect: Logged in, no profile. Redirecting to /create-profile.');
          return '/create-profile';
        }

        // If logged in and has profile, but on a public route (like /login) or profile creation route
        // (excluding '/', which is SplashScreen, and auth in-progress routes like OTP)
        final isOnPasswordRecoveryRoute =
            passwordRecoveryRoutes.contains(location);
        dev.log(
            'GoRouter Redirect: Check passwordRecoveryRoutes.contains($location): $isOnPasswordRecoveryRoute. Routes: $passwordRecoveryRoutes');

        if (hasProfile &&
                basePublicRoutes
                    .contains(location) && // Is it a general public route?
                !profileCreationRoutes
                    .contains(location) && // Not part of profile creation flow?
                !isOnPasswordRecoveryRoute && // Not part of password recovery flow?
                !location
                    .startsWith('/home') && // Not already in a /home section?
                location != '/' // Not the splash screen itself?
            ) {
          dev.log(
              'GoRouter Redirect: Logged in with profile, on a generic public page ($location) that is not home, profile, or recovery flow. Redirecting to /home.');
          return '/home';
        }
      } else {
        // Not logged in (and not a guest, or guest logic already handled returning null)
        if (!basePublicRoutes.contains(location) &&
            location != '/guest-prompt') {
          dev.log(
              'GoRouter Redirect: Not logged in (and not guest), trying to access $location. Redirecting to /login.');
          return '/login';
        }
      }
      dev.log('GoRouter Redirect: No redirect needed for $location.');
      return null;
    },
    routes: [
      GoRoute(
        path: '/guest-prompt',
        name: 'guest-prompt',
        builder: (context, state) => const GuestPromptOverlay(),
      ),
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const AuthScreen(),
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
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final email = extra['email'] as String? ?? 'no-email-provided';
          final type = extra['type'] as OtpType? ?? OtpType.signup;
          return OtpVerificationScreen(email: email, type: type);
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
        path: '/payment/:id',
        name: 'payment-callback',
        builder: (context, state) {
          final paymentId = state.pathParameters['id']!;
          final queryParams =
              Map<String, String>.from(state.uri.queryParameters);
          return PaymentCompletionScreen(
            paymentId: paymentId,
            billplzParams: queryParams,
          );
        },
      ),
      GoRoute(
        path: '/create-task',
        name: 'create-task',
        builder: (context, state) => const CreateTaskScreen(),
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
            builder: (context, state) => const MyTaskScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'task-details',
                builder: (context, state) => TaskDetailsScreen(
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
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/home/post',
            name: 'post-task',
            builder: (context, state) => const CreateTaskScreen(),
            redirect: (context, state) => '/create-task',
          ),
          GoRoute(
            path: '/home/chat',
            name: 'chat',
            builder: (context, state) => const ChatListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'chat-room',
                builder: (context, state) => ChatScreen(
                  channel: state.extra as Channel,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/home/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
