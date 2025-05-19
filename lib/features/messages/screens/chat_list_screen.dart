import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/message_controller.dart';
import 'chat_screen.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final channels = ref.watch(userChannelsProvider);
    final dateFormat = DateFormat('MMM d, y h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: channels.when(
        data: (channelsList) {
          if (channelsList.isEmpty) {
            return Center(
              child: Text(
                'No chats yet',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: channelsList.length,
            itemBuilder: (context, index) {
              final channel = channelsList[index];
              final isTaskPoster = user?.id == channel.posterId;
              final otherUserName = isTaskPoster
                  ? channel.taskerName
                  : channel.posterName;

              return Card(
                child: ListTile(
                  title: Text(
                    channel.taskTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'With $otherUserName',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (channel.lastMessageContent != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          channel.lastMessageContent!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: channel.lastMessageAt != null
                      ? Text(
                          dateFormat.format(channel.lastMessageAt!),
                          style: theme.textTheme.bodySmall,
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(channel: channel),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading chats: $error',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
    );
  }
} 