import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/auth/models/profile.dart';
import 'package:taskaway/features/profile/controllers/profile_controller.dart';
import 'package:taskaway/features/tasks/components/task_card_with_message.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/features/applications/repositories/application_repository.dart';
import 'package:taskaway/features/applications/models/application.dart';
import 'package:taskaway/features/tasks/repositories/task_repository.dart';
import 'dart:developer' as dev;

// Provider for managing the role filter state (UI-only, not stored in profile)
final roleFilterProvider = StateProvider<String>((ref) => 'As Poster');

// Provider for managing the status filter state
final statusProvider = StateProvider<String>((ref) => 'Upcoming tasks');

// Provider to get tasks where user has made applications (for taskers)
final tasksWithUserApplicationsProvider =
    FutureProvider.autoDispose<List<Task>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  print('tasksWithUserApplicationsProvider called');
  print('currentUser: ${currentUser?.id}');

  if (currentUser == null) {
    print('currentUser is null, returning empty list');
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
    print('No user applications found');
    return [];
  }

  final taskIds = {for (final a in pendingApplications) a.taskId}.toList();

  // 2) Fetch corresponding tasks that are still open
  final taskRepo = ref.read(taskRepositoryProvider);
  final tasks = await taskRepo.getTasksByIds(taskIds, status: 'open');

  print('Returning ${tasks.length} tasks with user applications');
  return tasks;
});

// Provider to get tasks where user is the assigned tasker (for accepted/in-progress tasks)
final taskerAssignedTasksProvider =
    FutureProvider.autoDispose<List<Task>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  print('taskerAssignedTasksProvider called');
  print('currentUser: ${currentUser?.id}');

  if (currentUser == null) {
    print('currentUser is null, returning empty list');
    return [];
  }

  // Fetch all tasks where the user is the assigned tasker
  final taskRepo = ref.read(taskRepositoryProvider);
  final allTasks = await taskRepo.getTasks();

  // Filter for tasks where user is the tasker
  final taskerTasks = allTasks.where((task) =>
    task.taskerId == currentUser.id &&
    ['accepted', 'in_progress', 'pending_approval'].contains(task.status.toLowerCase())
  ).toList();

  print('Found ${taskerTasks.length} assigned tasks for tasker');
  for (var task in taskerTasks) {
    print('  - ${task.title}: ${task.status}');
  }

  return taskerTasks;
});

// Provider to get ALL tasks posted by the current user (for poster's "My Tasks" view)
// Returns tasks with ALL statuses: open, accepted, in_progress, pending_approval, completed, cancelled
final myPostedTasksProvider =
    FutureProvider.autoDispose<List<Task>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);

  print('[MyPostedTasks] Provider called');
  print('[MyPostedTasks] Current user: ${currentUser?.id}');

  if (currentUser == null) {
    print('[MyPostedTasks] No current user, returning empty list');
    return [];
  }

  // Fetch ALL tasks posted by this user
  final taskRepo = ref.read(taskRepositoryProvider);
  final myTasks = await taskRepo.getMyPostedTasks(currentUser.id);

  print('[MyPostedTasks] Found ${myTasks.length} tasks posted by user');
  for (var task in myTasks) {
    print('[MyPostedTasks] - Task: ${task.title}, Status: ${task.status}');
  }

  return myTasks;
});

// Provider to filter tasks based on the current role filter and status filter
final selectedTasksProvider = Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(taskStreamProvider);
  final status = ref.watch(statusProvider);
  final role = ref.watch(roleFilterProvider); // Use UI filter instead of profile.role
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return const AsyncValue.loading();
  }

      if (role == 'As Poster') {
        // For posters, use dedicated provider that fetches ALL posted tasks (all statuses)
        return ref.watch(myPostedTasksProvider).when(
          data: (tasks) {
            // Filter by status
            final filteredTasks = tasks.where((task) {
              final mappedStatus = _mapTaskStatusToUiStatus(task.status);
              return mappedStatus == status;
            }).toList();

            print('[MyTaskScreen] Poster view - Total posted tasks: ${tasks.length}');
            print('[MyTaskScreen] Poster view - Filtered by "$status": ${filteredTasks.length}');

            return AsyncValue.data(filteredTasks);
          },
          loading: () => const AsyncValue.loading(),
          error: (err, stack) => AsyncValue.error(err, stack),
        );
      } else if (role == 'As Tasker' && status == 'Awaiting offers') {
        // For taskers viewing "Awaiting offers", show tasks they have applied to
        return ref.watch(tasksWithUserApplicationsProvider).when(
          data: (tasks) => AsyncValue.data(tasks),
          loading: () => const AsyncValue.loading(),
          error: (err, stack) => AsyncValue.error(err, stack),
        );
      } else if (role == 'As Tasker' && status == 'Upcoming tasks') {
        // For taskers viewing "Upcoming tasks", use dedicated provider to ensure we get assigned tasks
        return ref.watch(taskerAssignedTasksProvider).when(
          data: (tasks) => AsyncValue.data(tasks),
          loading: () => const AsyncValue.loading(),
          error: (err, stack) {
            // Fallback to original stream-based logic if provider fails
            print('[MyTaskScreen] taskerAssignedTasksProvider error: $err');
            return tasksAsync.whenData((tasks) {
              return tasks.where((task) {
                return task.taskerId == currentUser.id &&
                       _mapTaskStatusToUiStatus(task.status) == 'Upcoming tasks';
              }).toList();
            });
          },
        );
      } else {
        // Fallback logic for other cases
        return tasksAsync.whenData((tasks) {
          // Debug logging
          print('[MyTaskScreen] Total tasks available: ${tasks.length}');
          print('[MyTaskScreen] Current user ID: ${currentUser.id}');
          print('[MyTaskScreen] Current role filter: $role');
          print('[MyTaskScreen] Current status filter: $status');
          
          // Log tasks where user is the tasker
          final taskerTasks = tasks.where((task) => task.taskerId == currentUser.id).toList();
          print('[MyTaskScreen] Tasks where user is tasker: ${taskerTasks.length}');
          for (var task in taskerTasks) {
            print('[MyTaskScreen] - Task: ${task.title}, Status: ${task.status}, Mapped Status: ${_mapTaskStatusToUiStatus(task.status)}');
          }
          
          return tasks.where((task) {
            final isCorrectRole = (role == 'As Poster' && task.posterId == currentUser.id) ||
                (role == 'As Tasker' && task.taskerId == currentUser.id);

            final mappedStatus = _mapTaskStatusToUiStatus(task.status);
            final isCorrectStatus = mappedStatus == status;
            
            // Debug log for each task
            if (task.taskerId == currentUser.id || task.posterId == currentUser.id) {
              print('[MyTaskScreen] Filtering task: ${task.title}');
              print('  - TaskerId: ${task.taskerId}, PosterId: ${task.posterId}');
              print('  - IsCorrectRole: $isCorrectRole (role=$role)');
              print('  - Status: ${task.status} -> Mapped: $mappedStatus');
              print('  - IsCorrectStatus: $isCorrectStatus (filter=$status)');
              print('  - Will include: ${isCorrectRole && isCorrectStatus}');
            }

            return isCorrectRole && isCorrectStatus;
          }).toList();
        });
      }
});

// Helper to map database status to UI filter category
String _mapTaskStatusToUiStatus(String dbStatus) {
  switch (dbStatus.toLowerCase()) {
    case 'open':
      return 'Awaiting offers';
    case 'accepted':
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
    final profileAsync = ref.watch(currentProfileProvider);
    final currentRoleFilter = ref.watch(roleFilterProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Profile not available.')),
          );
        }

        // Derive color from UI role filter, not from profile.role
        final primaryColor = currentRoleFilter == 'As Tasker' ? const Color(0xFFF39C12) : const Color(0xFF7B61FF);

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
              _buildRoleFilter(context, ref, primaryColor),
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
                              child: TaskCardWithMessage(task: tasks[index]),
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

  Widget _buildRoleFilter(BuildContext context, WidgetRef ref, Color primaryColor) {
    final currentRole = ref.watch(roleFilterProvider);
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
                // Update UI-only role filter state
                ref.read(roleFilterProvider.notifier).state = role;
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