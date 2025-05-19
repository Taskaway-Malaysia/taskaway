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
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            redirect: (context, state) => '/home/tasks',
          ),
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
          GoRoute(
            path: '/home/chat',
            name: 'chat',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Chat List Screen')),
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'chat-room',
                builder: (context, state) => Scaffold(
                  body: Center(child: Text('Chat Room ${state.pathParameters['id']}')),
                ),
              ),
            ],
          ),
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