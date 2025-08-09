import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/auth/models/profile.dart';
import 'package:taskaway/features/profile/controllers/profile_controller.dart';
import 'package:taskaway/features/tasks/components/task_card.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/features/applications/repositories/application_repository.dart';
import 'package:taskaway/features/applications/models/application.dart';
import 'package:taskaway/features/tasks/repositories/task_repository.dart';
import 'dart:developer' as dev;

// Provider for managing the status filter state
final statusProvider = StateProvider<String>((ref) => 'Upcoming tasks');

// Provider to get tasks where user has made applications (for taskers)
final tasksWithUserApplicationsProvider =
    FutureProvider.autoDispose<List<Task>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  dev.log('tasksWithUserApplicationsProvider called');
  dev.log('currentUser: ${currentUser?.id}');

  if (currentUser == null) {
    dev.log('currentUser is null, returning empty list');
    return [];
  }

  // 1) Get user's applications and filter in Dart to include legacy rows
  // with null status which should be treated as pending
  final applicationRepo = ref.read(applicationRepositoryProvider);
  final applications = await applicationRepo.getUserApplications(currentUser.id);
  final pendingApplications = applications
      .where((a) => a.status == ApplicationStatus.pending)
      .toList();

  if (pendingApplications.isEmpty) {
    dev.log('No user applications found');
    return [];
  }

  final taskIds = {for (final a in pendingApplications) a.taskId}.toList();

  // 2) Fetch corresponding tasks that are still open
  final taskRepo = ref.read(taskRepositoryProvider);
  final tasks = await taskRepo.getTasksByIds(taskIds, status: 'open');

  dev.log('Returning ${tasks.length} tasks with user applications');
  return tasks;
});

// Provider to filter tasks based on the current profile's role and status filter
final selectedTasksProvider = Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(taskStreamProvider);
  final status = ref.watch(statusProvider);
  final profileAsync = ref.watch(currentProfileProvider);

  return profileAsync.when(
    data: (profile) {
      final currentUser = ref.watch(currentUserProvider);
      if (currentUser == null || profile == null) {
        return const AsyncValue.loading();
      }

      final role = profile.role == 'tasker' ? 'As Tasker' : 'As Poster';

      if (role == 'As Tasker' && status == 'Awaiting offers') {
        // For taskers viewing "Awaiting offers", show tasks they have applied to
        return ref.watch(tasksWithUserApplicationsProvider).when(
          data: (tasks) => AsyncValue.data(tasks),
          loading: () => const AsyncValue.loading(),
          error: (err, stack) => AsyncValue.error(err, stack),
        );
      } else {
        // Original logic for other cases
        return tasksAsync.whenData((tasks) {
          return tasks.where((task) {
            final isCorrectRole = (role == 'As Poster' && task.posterId == currentUser.id) ||
                (role == 'As Tasker' && task.taskerId == currentUser.id);

            final mappedStatus = _mapTaskStatusToUiStatus(task.status);
            final isCorrectStatus = mappedStatus == status;

            return isCorrectRole && isCorrectStatus;
          }).toList();
        });
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// Helper to map database status to UI filter category
String _mapTaskStatusToUiStatus(String dbStatus) {
  switch (dbStatus.toLowerCase()) {
    case 'open':
      return 'Awaiting offers';
    case 'pending':
    case 'in_progress':
    case 'pending_approval':
    case 'pending_payment':
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
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Profile not available.')),
          );
        }

        final primaryColor = profile.role == 'tasker' ? const Color(0xFFF39C12) : const Color(0xFF7B61FF);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('My Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: primaryColor),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: primaryColor),
                onPressed: () {
                  context.push('/notifications');
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildRoleFilter(context, ref, profile, primaryColor),
              const SizedBox(height: 16),
              _buildStatusFilter(context, ref, primaryColor),
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
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildRoleFilter(BuildContext context, WidgetRef ref, Profile profile, Color primaryColor) {
    final profileController = ref.read(profileControllerProvider);
    final currentUser = ref.watch(currentUserProvider);
    final currentRole = profile.role == 'tasker' ? 'As Tasker' : 'As Poster';
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
              onTap: () {
                if (currentUser != null) {
                  profileController.updateUserRole(
                    userId: currentUser.id,
                    role: role,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
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

  Widget _buildStatusFilter(BuildContext context, WidgetRef ref, Color primaryColor) {
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
                  color: isSelected ? primaryColor : Colors.transparent,
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