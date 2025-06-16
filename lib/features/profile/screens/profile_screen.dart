import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).signOut();
            if (context.mounted) {
              // GoRouter's redirect logic should handle this, 
              // but explicit navigation ensures it if redirect is not immediate.
              context.go('/login'); 
            }
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
