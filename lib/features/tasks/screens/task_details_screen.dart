import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/application_controller.dart';
import '../models/task.dart';
import '../models/application.dart';
import '../../messages/controllers/message_controller.dart';
import '../../messages/screens/chat_screen.dart';
import '../../payments/controllers/payment_controller.dart';

// State provider for task loading status
final taskLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

// State provider for task error messages
final taskErrorProvider = StateProvider.autoDispose<String?>((ref) => null);

// Provider for the current task
final currentTaskProvider = StreamProvider.autoDispose.family<Task, String>((ref, taskId) {
  return ref.watch(taskControllerProvider).watchTask(taskId);
});

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailsScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> with WidgetsBindingObserver {
  bool _isAccepting = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  void _initializeData() {
    ref.read(taskLoadingProvider.notifier).state = false;
    ref.read(taskErrorProvider.notifier).state = null;
    ref.refresh(currentTaskProvider(widget.taskId));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(currentTaskProvider(widget.taskId));
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      ref.read(taskLoadingProvider.notifier).state = true;
      ref.read(taskErrorProvider.notifier).state = null;

      final success = await ref.read(taskControllerProvider).deleteTask(widget.taskId);
      if (success && mounted) {
        context.pop();
      } else {
        throw Exception('Failed to delete task');
      }
    } catch (e) {
      ref.read(taskErrorProvider.notifier).state = 'Failed to delete task: ${e.toString()}';
    } finally {
      if (mounted) {
        ref.read(taskLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    final isLoading = ref.read(taskLoadingProvider);
    if (isLoading) return;

    try {
      ref.read(taskLoadingProvider.notifier).state = true;
      ref.read(taskErrorProvider.notifier).state = null;

      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      final taskSnapshot = await ref.read(taskControllerProvider).watchTask(widget.taskId).first;

      if (newStatus == 'completed') {
        await _handleCompletionApproval(taskSnapshot, user.id);
      } else {
        await ref.read(taskControllerProvider).updateTask(
          widget.taskId,
          {'status': newStatus},
        );
      }
    } catch (e) {
      ref.read(taskErrorProvider.notifier).state = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(taskLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _handleCompletionApproval(Task task, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to approve this task and initiate payment:'),
            const SizedBox(height: 8),
            Text(
              'Amount: RM ${task.price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('You will be redirected to Billplz to complete the payment.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(paymentControllerProvider).handleTaskApproval(
      taskId: widget.taskId,
      posterId: userId,
      taskerId: task.taskerId!,
      amount: task.price,
      taskTitle: task.title,
    );
  }

  Future<void> _handleChatNavigation(Task task) async {
    try {
      // Try to get existing channel
      final channel = await ref
          .read(messageControllerProvider)
          .getChannelByTaskId(task.id);

      if (channel != null) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(channel: channel),
            ),
          );
        }
        return;
      }

      // Create new channel
      final newChannel = await ref
          .read(messageControllerProvider)
          .createChannel(
            taskId: task.id,
            taskTitle: task.title,
            posterId: task.posterId,
            posterName: task.posterName ?? 'Unknown',
            taskerId: task.taskerId!,
            taskerName: task.taskerName ?? 'Unknown',
          );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(channel: newChannel),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isClient = user?.userMetadata?['role'] == 'client';
    final isLoading = ref.watch(taskLoadingProvider);

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          _initializeData();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isClient 
              ? theme.colorScheme.primary // Blue for poster
              : theme.colorScheme.tertiary, // Orange for tasker
          foregroundColor: isClient
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onTertiary,
          title: Text(
            'Task Details',
            style: TextStyle(
              color: isClient
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onTertiary,
            ),
          ),
          actions: [
            if (isLoading)
              Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isClient
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onTertiary,
                  ),
                ),
              )
            else if (isClient)
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: theme.colorScheme.onPrimary,
                ),
                onPressed: _deleteTask,
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ref.watch(currentTaskProvider(widget.taskId)).when(
            data: (task) => TaskDetailsContent(
              task: task,
              onUpdateStatus: _updateTaskStatus,
              onChatNavigation: () => _handleChatNavigation(task),
              isAccepting: _isAccepting,
              onAcceptApplication: (applicationId) async {
                setState(() => _isAccepting = true);
                try {
                  await ref.read(applicationControllerProvider).acceptApplication(applicationId);
                } finally {
                  if (mounted) {
                    setState(() => _isAccepting = false);
                  }
                }
              },
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $error',
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _handleRefresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Separate widget for task details content
class TaskDetailsContent extends ConsumerWidget {
  final Task task;
  final Function(String) onUpdateStatus;
  final VoidCallback onChatNavigation;
  final bool isAccepting;
  final Function(String) onAcceptApplication;

  const TaskDetailsContent({
    super.key,
    required this.task,
    required this.onUpdateStatus,
    required this.onChatNavigation,
    required this.isAccepting,
    required this.onAcceptApplication,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y h:mm a');
    final user = ref.watch(currentUserProvider);
    final isTaskPoster = user?.id == task.posterId;
    final isLoading = ref.watch(taskLoadingProvider);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(task.status, theme),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              task.status.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title and basic info
          TaskBasicInfo(task: task, dateFormat: dateFormat),

          // Assigned Tasker section
          if (isTaskPoster && task.taskerId != null && task.status != 'open')
            AssignedTaskerSection(taskId: task.id),

          // Description
          TaskDescription(description: task.description),

          // Applications Section
          if (isTaskPoster && task.status == 'open')
            ApplicationsSection(
              taskId: task.id,
              isAccepting: isAccepting,
              onAccept: onAcceptApplication,
            ),

          // Error Messages
          ErrorMessages(),

          // Action Buttons
          TaskActionButtons(
            task: task,
            isLoading: isLoading,
            onUpdateStatus: onUpdateStatus,
            onChatNavigation: onChatNavigation,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'open':
        return theme.colorScheme.primary;
      case 'in_progress':
        return theme.colorScheme.tertiary;
      case 'pending_approval':
        return Colors.orange;
      case 'completed':
        return theme.colorScheme.secondary;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }
}

// Add these widget classes at the bottom of the file
class TaskBasicInfo extends StatelessWidget {
  final Task task;
  final DateFormat dateFormat;

  const TaskBasicInfo({
    super.key,
    required this.task,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'RM ${task.price.toStringAsFixed(2)}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(theme),
        const SizedBox(height: 8),
        _buildScheduleRow(theme),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.category_outlined,
          size: 20,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        Text(
          task.category,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(width: 24),
        Icon(
          Icons.location_on_outlined,
          size: 20,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            task.location,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 20,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        Text(
          dateFormat.format(task.scheduledTime),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class AssignedTaskerSection extends ConsumerWidget {
  final String taskId;

  const AssignedTaskerSection({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Application>>(
      future: ref.read(applicationControllerProvider).getApplications(
        taskId: taskId,
        status: 'accepted',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Unknown');
        }
        final application = snapshot.data!.first;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Icon(Icons.person, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Assigned to: ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                application.taskerName,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class TaskDescription extends StatelessWidget {
  final String description;

  const TaskDescription({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class ApplicationsSection extends ConsumerWidget {
  final String taskId;
  final bool isAccepting;
  final Function(String) onAccept;

  const ApplicationsSection({
    super.key,
    required this.taskId,
    required this.isAccepting,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Applications',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Application>>(
          stream: ref.watch(taskApplicationsProvider(taskId).stream),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Error loading applications: ${snapshot.error}',
                style: TextStyle(color: theme.colorScheme.error),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final applications = snapshot.data!;
            if (applications.isEmpty) {
              return const Text('No applications yet');
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: applications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final application = applications[index];
                return ApplicationCard(
                  application: application,
                  isAccepting: isAccepting,
                  onAccept: onAccept,
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class ApplicationCard extends StatelessWidget {
  final Application application;
  final bool isAccepting;
  final Function(String) onAccept;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.isAccepting,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        title: Text(
          'Application from ${application.taskerName}',
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          application.message,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isAccepting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: () => onAccept(application.id),
                child: const Text('Accept'),
              ),
      ),
    );
  }
}

class ErrorMessages extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final errorMessage = ref.watch(taskErrorProvider);

    if (errorMessage == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          errorMessage,
          style: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class TaskActionButtons extends ConsumerWidget {
  final Task task;
  final bool isLoading;
  final Function(String) onUpdateStatus;
  final VoidCallback onChatNavigation;

  const TaskActionButtons({
    super.key,
    required this.task,
    required this.isLoading,
    required this.onUpdateStatus,
    required this.onChatNavigation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isTaskPoster = user?.id == task.posterId;
    final isTasker = task.taskerId == user?.id;

    // Determine if we should show the chat button
    final shouldShowChat = (isTaskPoster || isTasker) && task.status != 'open';

    return Column(
      children: [
        // Action buttons based on role and status
        if (isTasker && task.status == 'in_progress')
          _buildTaskerInProgressButtons()
        else if (isTaskPoster && task.status == 'pending_approval')
          _buildPosterApprovalButtons()
        else if (!isTaskPoster && task.status == 'open')
          _buildOpenTaskButtons(context, ref)
        else if (isTaskPoster && task.status == 'open')
          _buildPosterOpenButtons(),

        // Chat button if applicable
        if (shouldShowChat) ...[
          const SizedBox(height: 16),
          _buildChatButton(theme),
        ],
      ],
    );
  }

  Widget _buildTaskerInProgressButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => onUpdateStatus('pending_approval'),
        child: const Text('Mark as Completed'),
      ),
    );
  }

  Widget _buildPosterApprovalButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => onUpdateStatus('completed'),
            child: const Text('Approve Completion'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading ? null : () => onUpdateStatus('in_progress'),
            child: const Text('Request Revision'),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenTaskButtons(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Application>>(
      stream: ref.watch(taskApplicationsProvider(task.id).stream),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final applications = snapshot.data!;
        final user = ref.read(currentUserProvider);
        final hasApplied = applications.any((app) => app.taskerId == user?.id);

        if (hasApplied) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have already applied for this task',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () => context.push('/home/tasks/${task.id}/apply'),
            child: const Text('Apply for Task'),
          ),
        );
      },
    );
  }

  Widget _buildPosterOpenButtons() {
    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading ? null : () => onUpdateStatus('cancelled'),
            child: const Text('Cancel Task'),
          ),
        ),
      ],
    );
  }

  Widget _buildChatButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onChatNavigation,
        icon: const Icon(Icons.chat),
        label: const Text('Chat'),
      ),
    );
  }
} 