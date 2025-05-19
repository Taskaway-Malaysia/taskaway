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

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailsScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAccepting = false;
  String? _acceptError;

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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(taskControllerProvider).deleteTask(widget.taskId);
      if (success && mounted) {
        context.pop(); // Return to tasks list
      } else {
        throw Exception('Failed to delete task');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete task: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() {
        _errorMessage = 'You must be logged in to update the task status.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(taskControllerProvider).updateTask(
        widget.taskId,
        {
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      
      if (!success && mounted) {
        setState(() {
          _errorMessage = 'Failed to update task status. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error updating status: ${e.toString()}';
        });
        print('Error updating task status: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y h:mm a');
    final user = ref.watch(currentUserProvider);
    final isClient = user?.userMetadata?['role'] == 'client';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else if (isClient)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTask,
            ),
        ],
      ),
      body: StreamBuilder<Task>(
        stream: ref.watch(taskControllerProvider).watchTask(widget.taskId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final task = snapshot.data!;
          final isTaskPoster = user?.id == task.posterId;

          return SingleChildScrollView(
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

                // Title
                Text(
                  task.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Price
                Text(
                  'RM ${task.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Category and Location
                Row(
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
                ),
                const SizedBox(height: 8),

                // Scheduled Time
                Row(
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
                ),
                const SizedBox(height: 24),

                // Assigned Tasker (for poster)
                if (isTaskPoster && task.taskerId != null && task.status != 'open') ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Assigned to: ',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        FutureBuilder<List<Application>>(
                          future: ref.read(applicationControllerProvider).getApplications(
                            taskId: task.id,
                            status: 'accepted',
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
                            }
                            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('Unknown');
                            }
                            final application = snapshot.data!.first;
                            return Text(
                              application.taskerName,
                              style: theme.textTheme.bodyMedium,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                // Description
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // Applications Section (for task poster)
                if (isTaskPoster && task.status == 'open') ...[
                  Text(
                    'Applications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Application>>(
                    stream: ref.watch(taskApplicationsProvider(widget.taskId).stream),
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
                              trailing: _isAccepting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : TextButton(
                                      onPressed: () async {
                                        setState(() {
                                          _isAccepting = true;
                                          _acceptError = null;
                                        });
                                        final success = await ref.read(applicationControllerProvider).acceptApplication(application.id);
                                        if (!mounted) return;
                                        setState(() {
                                          _isAccepting = false;
                                          if (!success) {
                                            _acceptError = 'Failed to accept application.';
                                          }
                                        });
                                      },
                                      child: const Text('Accept'),
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Error Message
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // Accept Error Message
                if (_acceptError != null) ...[
                  Text(
                    _acceptError!,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],

                // Action Buttons
                if (task.taskerId == user?.id && task.status == 'in_progress') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _updateTaskStatus('pending_approval'),
                      child: const Text('Mark as Completed'),
                    ),
                  ),
                ] else if (isTaskPoster && task.status == 'pending_approval') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _updateTaskStatus('completed'),
                      child: const Text('Approve Completion'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _updateTaskStatus('in_progress'),
                      child: Text(
                        'Request Revision',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ] else if (!isTaskPoster && task.status == 'open') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.push('/home/tasks/${task.id}/apply'),
                      child: const Text('Apply for Task'),
                    ),
                  ),
                ],

                if (isTaskPoster && task.status == 'open') ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _updateTaskStatus('cancelled'),
                      child: Text(
                        'Cancel Task',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],

                // Chat button (show only for poster and assigned tasker)
                if ((isTaskPoster || task.taskerId == user?.id) && task.status != 'open') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
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
                        try {
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
                                content: Text('Failed to create chat: ${e.toString()}'),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
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