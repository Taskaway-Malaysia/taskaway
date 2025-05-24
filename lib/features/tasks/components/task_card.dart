import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => context.push('/home/tasks/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskCardHeader(task: task),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              TaskCardInfo(task: task),
              const SizedBox(height: 4),
              TaskCardFooter(task: task),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskCardHeader extends StatelessWidget {
  final Task task;

  const TaskCardHeader({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            task.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TaskStatusBadge(status: task.status),
      ],
    );
  }
}

class TaskStatusBadge extends StatelessWidget {
  final String status;

  const TaskStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status, theme),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
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

class TaskCardInfo extends StatelessWidget {
  final Task task;

  const TaskCardInfo({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.category_outlined,
          size: 16,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 4),
        Text(
          task.category,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.location_on_outlined,
          size: 16,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            task.location,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class TaskCardFooter extends StatelessWidget {
  final Task task;

  const TaskCardFooter({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y h:mm a');

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 4),
        Text(
          dateFormat.format(task.scheduledTime),
          style: theme.textTheme.bodySmall,
        ),
        const Spacer(),
        Text(
          'RM ${task.price.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 