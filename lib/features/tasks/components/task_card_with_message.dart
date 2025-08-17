import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/features/messages/controllers/message_controller.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/core/constants/style_constants.dart';

class TaskCardWithMessage extends ConsumerWidget {
  final Task task;

  const TaskCardWithMessage({super.key, required this.task});

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDay = DateTime(date.year, date.month, date.day);

    if (scheduledDay.isBefore(today)) {
      return 'Before ${DateFormat('E, d MMM').format(date)}';
    } else {
      return 'On ${DateFormat('E, d MMM').format(date)}';
    }
  }

  Future<void> _navigateToChat(BuildContext context, WidgetRef ref) async {
    try {
      final messageController = ref.read(messageControllerProvider);
      final channel = await messageController.getChannelByTaskId(task.id);
      
      if (channel != null && context.mounted) {
        await context.push('/home/chat/${channel.id}');
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No conversation found for this task')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat =
        NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);
    
    final currentUser = ref.watch(currentUserProvider);
    
    // Determine if message button should show
    final shouldShowMessage = (task.status == 'accepted' || 
                              task.status == 'in_progress' || 
                              task.status == 'pending_approval') &&
                             (currentUser?.id == task.posterId || 
                              currentUser?.id == task.taskerId);

    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/home/tasks/${task.id}'),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            // Top section: Title and Price
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add message button if applicable
                  if (shouldShowMessage) ...[
                    IconButton(
                      onPressed: () => _navigateToChat(context, ref),
                      icon: const Icon(Icons.message),
                      color: StyleConstants.primaryColor,
                      tooltip: 'Message',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    currencyFormat.format(task.price),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            // Bottom section with grid
            IntrinsicHeight(
              child: Row(
                children: [
                  // Status and Offers
                  SizedBox(
                    width: 90, // Fixed width for the first column
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            task.status.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF7B61FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 2,
                            width: 30,
                            color: const Color(0xFF7B61FF),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${task.offers?.length ?? 0} Offer${(task.offers?.length ?? 0) != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  // Date
                  Expanded(
                    child: Container(
                      color: Colors.grey.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                          const SizedBox(height: 4),
                          Text(
                            _getFormattedDate(task.scheduledTime),
                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  // Location or Remote
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            task.locationType == 'remote' ? Icons.home_work : Icons.location_on,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.locationType == 'remote' ? 'Remote' : task.location,
                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}