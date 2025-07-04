import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/mock_data_provider.dart'; // Import mock data provider

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final channelsList = ref.watch(mockChannelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: channelsList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: channelsList.length,
              itemBuilder: (context, index) {
                final channel = channelsList[index];
                final isCurrentUserPoster = channel.posterId == currentUserId;
                final otherPersonName = isCurrentUserPoster
                    ? channel.taskerName
                    : channel.posterName;

                return InkWell(
                  onTap: () {
                    // Navigate to chat screen with the channel object as extra data
                    context.push('/home/chat/${channel.id}', extra: channel);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade300,
                          child: Text(
                            otherPersonName.isNotEmpty
                                ? otherPersonName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Message content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Person name
                                  Text(
                                    otherPersonName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  // Time
                                  Text(
                                    _getFormattedTime(channel.lastMessageAt),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Task title
                              Text(
                                channel.taskTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Last message with unread indicator
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      channel.lastMessageContent ??
                                          'No messages yet',
                                      style: TextStyle(
                                        color: channel.unreadCount > 0
                                            ? Colors.black
                                            : Colors.grey.shade600,
                                        fontWeight: channel.unreadCount > 0
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (channel.unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        channel.unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _getFormattedTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Just now (less than 1 minute)
    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    // Minutes ago (less than 1 hour)
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }

    // Hours ago (less than 1 day)
    if (difference.inDays < 1) {
      return '${difference.inHours} h ago';
    }

    // Yesterday
    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    // Days of the week (less than 7 days)
    if (difference.inDays < 7) {
      final weekday = DateFormat('EEEE').format(dateTime);
      return weekday;
    }

    // Date format (more than 7 days)
    return DateFormat('d MMM').format(dateTime);
  }
}
