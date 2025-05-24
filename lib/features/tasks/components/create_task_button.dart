import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/controllers/auth_controller.dart';

class CreateTaskButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClient = ref.watch(currentUserProvider)?.userMetadata?['role'] == 'client';
    
    if (!isClient) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => context.push('/home/tasks/create'),
      icon: const Icon(Icons.add),
      label: const Text('Post Task'),
    );
  }
} 