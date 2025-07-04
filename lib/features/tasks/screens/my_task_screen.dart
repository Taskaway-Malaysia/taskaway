import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/tasks/components/task_card.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/tasks/models/task.dart';

// Providers for managing the filter state
final roleProvider = StateProvider<String>((ref) => 'As Poster');
final statusProvider = StateProvider<String>((ref) => 'Upcoming tasks');

// Provider to filter tasks based on role and status
final selectedTasksProvider = Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(taskStreamProvider);
  final role = ref.watch(roleProvider);
  final status = ref.watch(statusProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return const AsyncValue.loading();
  }

  return tasksAsync.whenData((tasks) {
    return tasks.where((task) {
      final isCorrectRole = (role == 'As Poster' && task.posterId == currentUser.id) ||
          (role == 'As Tasker' && task.taskerId == currentUser.id);

      final mappedStatus = _mapTaskStatusToUiStatus(task.status);
      final isCorrectStatus = mappedStatus == status;

      return isCorrectRole && isCorrectStatus;
    }).toList();
  });
});

// Helper to map database status to UI filter category
String _mapTaskStatusToUiStatus(String dbStatus) {
  switch (dbStatus.toLowerCase()) {
    case 'open':
      return 'Awaiting offers';
    case 'assigned':
    case 'in_progress':
    case 'pending_approval':
      return 'Upcoming tasks';
    case 'completed':
    case 'cancelled':
      return 'Completed';
    default:
      return 'Awaiting offers';
  }
}

class MyTaskScreen extends ConsumerWidget {
  const MyTaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRoleFilter(context, ref),
          const SizedBox(height: 16),
          _buildStatusFilter(context, ref),
          const SizedBox(height: 16),
          Expanded(
            child: ref.watch(selectedTasksProvider).when(
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return const Center(child: Text('No tasks for this category.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TaskCard(task: tasks[index]),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilter(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(roleProvider);
    final roles = ['As Poster', 'As Tasker'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: roles.map((role) {
          final isSelected = currentRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(roleProvider.notifier).state = role,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7B61FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    role,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context, WidgetRef ref) {
    final currentStatus = ref.watch(statusProvider);
    final statuses = ['Awaiting offers', 'Upcoming tasks', 'Completed'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: statuses.map((status) {
          final isSelected = currentStatus == status;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(statusProvider.notifier).state = status,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7B61FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}