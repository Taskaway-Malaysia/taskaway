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
    final currencyFormat =
        NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);

    // Format date based on task scheduled time
    String formattedDate = '';
    final now = DateTime.now();
    final scheduledDate = task.scheduledTime;

    if (scheduledDate.isBefore(now)) {
      formattedDate = 'Before ${DateFormat('E, d MMM').format(scheduledDate)}';
    } else {
      formattedDate = 'On ${DateFormat('E, d MMM').format(scheduledDate)}';
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade400, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Price row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Open',
                    style: TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Price
                Text(
                  currencyFormat.format(task.price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Task title
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            // Date and Location
            Row(
              children: [
                // Calendar icon and date
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  task.location,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Offers count and View button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Offers count
                Text(
                  _getOffersText(task),
                  style: const TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // View button
                TextButton(
                  onPressed: () => context.push('/home/tasks/${task.id}'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6C5CE7),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(60, 36),
                  ),
                  child: const Text('View'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getOffersText(Task task) {
    // This would normally come from the task data
    // For now using a placeholder based on task price
    final offersCount = task.price > 500 ? 1 : 3;
    return offersCount == 1 ? '1 Offer' : '$offersCount Offers';
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
