import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/applications/repositories/application_repository.dart';
import 'package:taskaway/features/tasks/repositories/task_repository.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/core/theme/app_colors.dart';
import 'package:taskaway/core/theme/app_typography.dart';
import 'package:taskaway/core/theme/app_spacing.dart';

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

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final ScrollController _scrollController = ScrollController();
  int _displayLimit = 10; // Start with 10 tasks

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = maxScroll * 0.8;

      if (currentScroll >= threshold) {
        _loadMoreTasks();
      }
    }
  }

  void _loadMoreTasks() {
    setState(() {
      _displayLimit += 10; // Load 10 more tasks
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userAcceptedTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderDefault,
                    width: 1,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  'Activity',
                  style: AppTypography.headlineMedium,
                ),
              ),
            ),
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        'No active tasks',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  // Apply pagination - show only first N tasks
                  final paginatedTasks = tasks.take(_displayLimit).toList();

                  return ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: paginatedTasks.length,
                    separatorBuilder: (context, index) => Container(
                      height: 1,
                      color: const Color(0xFFE8E9F1),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    itemBuilder: (context, index) {
                      return _TaskCard(task: paginatedTasks[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading tasks',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.error,
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
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
        ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.lg),
                Text(
                  'RM ${task.budget.toStringAsFixed(0)}',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: AppTypography.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'By $posterName',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(task.status).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(task.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Due date $dueDate',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}