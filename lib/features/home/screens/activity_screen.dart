import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/applications/repositories/application_repository.dart';
import 'package:taskaway/features/tasks/repositories/task_repository.dart';
import 'package:taskaway/features/tasks/models/task.dart';

final userAcceptedTasksProvider = FutureProvider<List<Task>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final applicationRepo = ref.watch(applicationRepositoryProvider);
  final taskRepo = ref.watch(taskRepositoryProvider);

  final acceptedApplications = await applicationRepo.getUserApplications(
    user.id,
    statuses: ['accepted'],
  );

  if (acceptedApplications.isEmpty) return [];

  final taskIds = acceptedApplications.map((app) => app.taskId).toList();
  final tasks = await taskRepo.getTasksByIds(taskIds);

  // Sort tasks by status priority: pending_approval > in_progress > completed > cancelled
  tasks.sort((a, b) {
    final statusOrder = {
      'pending_approval': 1,
      'in_progress': 2,
      'accepted': 2,
      'completed': 3,
      'cancelled': 4,
      'rejected': 4,
    };

    final aOrder = statusOrder[a.status.toLowerCase()] ?? 5;
    final bOrder = statusOrder[b.status.toLowerCase()] ?? 5;

    return aOrder.compareTo(bOrder);
  });

  return tasks;
});

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(userAcceptedTasksProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE8E9F1),
                    width: 1,
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  'Activity',
                  style: TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.48,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ),
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Center(
                      child: Text(
                        'No active tasks',
                        style: TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 16,
                          color: Color(0xFF788494),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(22),
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 26),
                    itemBuilder: (context, index) {
                      return _TaskCard(task: tasks[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading tasks',
                    style: TextStyle(
                      fontFamily: 'Instrument Sans',
                      fontSize: 16,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'open':
        return const Color(0xFFFFC333);
      case 'accepted':
      case 'in_progress':
        return const Color(0xFF2ECC71);
      case 'completed':
        return const Color(0xFF2ECC71);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFCC2E2E);
      default:
        return const Color(0xFF788494);
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancel';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMM yyyy');
    final dueDate = dateFormat.format(task.scheduledTime);
    final posterName = task.posterName ?? 'Unknown';

    return InkWell(
      onTap: () {
        context.push('/home/tasks/${task.id}');
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 77),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontFamily: 'Instrument Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.22,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'RM ${task.budget.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.22,
                    color: Color(0xFF000000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'By $posterName',
                    style: const TextStyle(
                      fontFamily: 'Instrument Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.22,
                      letterSpacing: 0.24,
                      color: Color(0xFF788494),
                    ),
                  ),
                ),
                Text(
                  _getStatusLabel(task.status),
                  style: TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.22,
                    letterSpacing: 0.24,
                    color: _getStatusColor(task.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Due date $dueDate',
              style: const TextStyle(
                fontFamily: 'Instrument Sans',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                height: 1.22,
                letterSpacing: 0.2,
                color: Color(0xFF788494),
              ),
            ),
          ],
        ),
      ),
    );
  }
}