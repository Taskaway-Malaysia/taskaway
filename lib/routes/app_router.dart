import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';
import '../features/tasks/screens/create_task_screen.dart';
import '../features/tasks/screens/task_details_screen.dart';
import '../features/tasks/screens/apply_task_screen.dart';
import '../features/payments/screens/payment_completion_screen.dart';
import '../features/messages/screens/chat_list_screen.dart';
import '../features/messages/screens/chat_screen.dart';
import '../features/messages/models/channel.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/payment/:id',
        name: 'payment-callback',
        builder: (context, state) {
          final paymentId = state.pathParameters['id']!;
          final queryParams = Map<String, String>.from(state.uri.queryParameters);
          return PaymentCompletionScreen(
            paymentId: paymentId,
            billplzParams: queryParams,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            redirect: (context, state) => '/home/browse',
          ),
          // Browse screen (index 0)
          GoRoute(
            path: '/home/browse',
            name: 'browse',
            builder: (context, state) => const TasksScreen(), // Reusing TasksScreen for now
          ),
          // My Tasks screen (index 1)
          GoRoute(
            path: '/home/tasks',
            name: 'tasks',
            builder: (context, state) => const TasksScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-task',
                builder: (context, state) => const CreateTaskScreen(),
              ),
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
          // Post Task screen (index 2)
          GoRoute(
            path: '/home/post',
            name: 'post-task',
            builder: (context, state) => const CreateTaskScreen(),
          ),
          // Messages screen (index 3)
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
          // Profile screen (index 4)
          GoRoute(
            path: '/home/profile',
            name: 'profile',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Profile Screen')),
            ),
          ),
        ],
      ),
    ],
  );
});