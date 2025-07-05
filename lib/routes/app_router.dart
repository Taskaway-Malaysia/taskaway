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
import '../features/tasks/screens/browse_tasks_screen.dart';
import '../features/tasks/screens/post_task_screen.dart';
import '../features/tasks/screens/create_task_screen.dart';
import '../features/tasks/screens/task_details_screen.dart';
import '../features/tasks/screens/apply_task_screen.dart';
import '../features/tasks/screens/report_screen.dart';
import '../features/payments/screens/payment_completion_screen.dart';
import '../features/messages/screens/chat_list_screen.dart';
import '../features/messages/screens/chat_screen.dart';
import '../features/messages/models/channel.dart';
import '../features/messages/controllers/message_controller.dart';
import '../features/tasks/screens/review_tasker_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authController = ref.watch(authControllerProvider);
  final messageController = ref.watch(messageControllerProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/auth/create-account',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: '/auth/create-profile',
        builder: (context, state) => const CreateProfileScreen(),
      ),
      GoRoute(
        path: '/auth/signup-success',
        builder: (context, state) => const SignupSuccessScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/otp-verification',
        builder: (context, state) => const OTPVerificationScreen(),
      ),
      GoRoute(
        path: '/auth/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/auth/change-password-success',
        builder: (context, state) => const ChangePasswordSuccessScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) {
          final Map<String, dynamic> params = state.extra as Map<String, dynamic>;
          return ReviewTaskerScreen(
            taskerId: params['taskerId'],
            taskId: params['taskId'],
            taskerName: params['taskerName'],
            taskerAvatarUrl: params['taskerAvatarUrl'],
            totalPaid: params['totalPaid'],
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const MyTaskScreen(),
            routes: [
              GoRoute(
                path: 'post',
                builder: (context, state) => const PostTaskScreen(),
              ),
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateTaskScreen(),
              ),
              GoRoute(
                path: 'browse',
                builder: (context, state) => const BrowseTasksScreen(),
              ),
              GoRoute(
                path: 'tasks/:taskId',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId']!;
                  return TaskDetailsScreen(taskId: taskId);
                },
                routes: [
                  GoRoute(
                    path: 'apply',
                    builder: (context, state) {
                      final taskId = state.pathParameters['taskId']!;
                      final Map<String, dynamic>? params = state.extra as Map<String, dynamic>?;
                      return ApplyTaskScreen(
                        taskId: taskId,
                        offerPrice: params?['offerPrice'],
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'chat',
                builder: (context, state) => const ChatListScreen(),
              ),
              GoRoute(
                path: 'chat/:channelId',
                builder: (context, state) {
                  final channelId = state.pathParameters['channelId']!;
                  return ChatScreen(channelId: channelId);
                },
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) {
          final Map<String, dynamic> params = state.extra as Map<String, dynamic>;
          return ReportScreen(
            userId: params['userId'],
            userName: params['userName'],
            userAvatarUrl: params['userAvatarUrl'],
          );
        },
      ),
      GoRoute(
        path: '/payment/completion',
        builder: (context, state) {
          final Map<String, dynamic> params = state.extra as Map<String, dynamic>;
          return PaymentCompletionScreen(
            billplzId: params['billplz_id'],
            transactionId: params['transaction_id'],
            paid: params['paid'] ?? false,
          );
        },
      ),
    ],
    redirect: (context, state) async {
      final isLoggedIn = await authController.isLoggedIn();
      final isOnboardingCompleted = await authController.isOnboardingCompleted();

      // Get the current location
      final location = state.matchedLocation;

      // Paths that don't require authentication
      final publicPaths = [
        '/',
        '/onboarding',
        '/auth',
        '/auth/create-account',
        '/auth/forgot-password',
        '/auth/otp-verification',
        '/auth/change-password',
        '/auth/change-password-success',
      ];

      // If not logged in and trying to access protected route
      if (!isLoggedIn && !publicPaths.contains(location)) {
        return '/auth';
      }

      // If logged in but trying to access auth routes
      if (isLoggedIn && (location.startsWith('/auth') || location == '/')) {
        return '/home';
      }

      // If logged in but hasn't completed onboarding
      if (isLoggedIn && !isOnboardingCompleted && location != '/onboarding') {
        return '/onboarding';
      }

      // If logged in and completed onboarding but still on onboarding screen
      if (isLoggedIn && isOnboardingCompleted && location == '/onboarding') {
        return '/home';
      }

      return null;
    },
  );
});
