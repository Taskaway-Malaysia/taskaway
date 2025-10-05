import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../controllers/message_controller.dart';
import '../models/channel.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class MessageListScreen extends ConsumerWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final channelsAsync = ref.watch(userChannelsProvider);

    return channelsAsync.when(
      data: (channels) => _buildChatList(context, theme, channels, ref),
      loading: () => _buildLoadingScaffold(theme),
      error: (error, stackTrace) => _buildErrorScaffold(theme, error),
    );
  }

  Widget _buildChatList(BuildContext context, ThemeData theme, List<Channel> channelsList, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id ?? '';

    // Mock data for demo - map channel IDs to profile images
    final profileImages = {
      0: 'assets/images/profile_siti.png',
      1: 'assets/images/profile_junior.png',
      2: 'assets/images/profile_qistina.png',
      3: 'assets/images/profile_mike.png',
    };

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
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
                  'Message',
                  style: AppTypography.headlineMedium,
                ),
              ),
            ),
          ),
          Expanded(
            child: channelsList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'No conversations yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Start by accepting a task offer',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: channelsList.length,
              separatorBuilder: (context, index) => Container(
                height: 1,
                color: const Color(0xFFE8E9F1),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              itemBuilder: (context, index) {
                final channel = channelsList[index];
                final isCurrentUserPoster = channel.posterId == currentUserId;
                final otherPersonName = isCurrentUserPoster
                    ? channel.taskerName
                    : channel.posterName;

                // Get profile image based on index (cycling through available images)
                final profileImage = profileImages[index % profileImages.length];

                return InkWell(
                  onTap: () {
                    context.pushNamed(
                      'chat-room',
                      pathParameters: {'id': channel.id},
                      extra: channel,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade300,
                            image: profileImage != null
                                ? DecorationImage(
                                    image: AssetImage(profileImage),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: profileImage == null
                              ? Center(
                                  child: Text(
                                    otherPersonName.isNotEmpty
                                        ? otherPersonName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 7),
                        // Message content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Person name and time
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    otherPersonName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      color: Color(0xFF050316),
                                    ),
                                  ),
                                  Text(
                                    _getFormattedTime(channel.lastMessageAt),
                                    style: const TextStyle(
                                      color: Color(0xFF8F9098),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              // Task title
                              Text(
                                channel.taskTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color(0xFF050316),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Last message with status indicator
                              Row(
                                children: [
                                  // Message status icon (for sent messages)
                                  if (channel.lastMessageSenderId == currentUserId) ...[
                                    Icon(
                                      Icons.done_all,
                                      size: 20,
                                      color: channel.unreadCount == 0
                                          ? const Color(0xFFFDAB2F) // Read (yellow)
                                          : const Color(0xFF8F9098), // Sent (gray)
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      channel.lastMessageContent ?? 'No messages yet',
                                      style: const TextStyle(
                                        color: Color(0xFF8F9098),
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Unread count badge
                                  if (channel.unreadCount > 0 && channel.lastMessageSenderId != currentUserId)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFDAB2F),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          channel.unreadCount.toString(),
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
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
          ),
        ],
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

    // Today - show time
    if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(dateTime);
    }

    // Yesterday
    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    // Days of the week (less than 7 days)
    if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    }

    // Date format (more than 7 days)
    return DateFormat('d MMM').format(dateTime);
  }

  Widget _buildLoadingScaffold(ThemeData theme) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
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
                  'Message',
                  style: AppTypography.headlineMedium,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFDAB2F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScaffold(ThemeData theme, Object error) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
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
                  'Message',
                  style: AppTypography.headlineMedium,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.6),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Failed to load messages',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}