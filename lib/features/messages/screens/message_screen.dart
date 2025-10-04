import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taskaway/core/theme/app_colors.dart';
import 'package:taskaway/core/theme/app_typography.dart';
import 'package:taskaway/core/theme/app_spacing.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/channel.dart';
import '../models/message.dart';
import '../controllers/message_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/profile.dart';
import '../../tasks/controllers/task_controller.dart';
import '../../../core/utils/time_formatter.dart';

class MessageScreen extends ConsumerStatefulWidget {
  final Channel channel;

  const MessageScreen({
    super.key,
    required this.channel,
  });

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showSuggestions = true;
  late Channel _channel;
  int _selectedIndex = 3; // Message tab selected

  @override
  void initState() {
    super.initState();
    _channel = widget.channel;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final messageController = ref.read(messageControllerProvider);
      await messageController.sendMessage(
        channelId: _channel.id,
        content: text,
      );

      _messageController.clear();
      setState(() {
        _showSuggestions = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sendSuggestedMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  Widget _buildNavItem({
    required String iconPath,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              isSelected ? AppColors.navActive : AppColors.navInactive,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: isSelected ? AppColors.navActive : AppColors.navInactive,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterTaskawayButton({
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              border: Border.all(
                color: AppColors.primaryYellowDark,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: SvgPicture.asset(
              'assets/icons/nav_taskaway.svg',
              width: 15,
              height: 15,
              colorFilter: const ColorFilter.mode(
                AppColors.primaryBlack,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Taskaway',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: AppColors.navInactive,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id ?? '';
    final messagesAsync = ref.watch(channelMessagesProvider(_channel.id));
    final taskAsync = ref.watch(taskProvider(_channel.taskId));

    // Get the other user's ID to fetch their profile and online status
    final otherUserId = currentUserId == _channel.posterId
        ? _channel.taskerId
        : _channel.posterId;

    // Watch the other user's profile for their last sign in
    final otherUserProfileAsync = ref.watch(profileProvider(otherUserId));

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Column(
        children: [
              // Safe area spacer
              SafeArea(
                bottom: false,
                child: Container(),
              ),

              // Navigation bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: AppColors.primaryBlack,
                      ),
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentUserId == _channel.posterId
                                  ? _channel.taskerName
                                  : _channel.posterName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlack,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            // Online status
                            otherUserProfileAsync.when(
                              data: (profile) {
                                // Check if we have last sign-in info from profile
                                if (profile?.lastSignInAt != null) {
                                  final onlineStatus = TimeFormatter.formatOnlineStatus(profile!.lastSignInAt);
                                  return Text(
                                    onlineStatus,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                } else {
                                  // Fallback to using updatedAt if available
                                  final lastActivity = profile?.updatedAt;
                                  final onlineStatus = lastActivity != null
                                      ? TimeFormatter.formatOnlineStatus(lastActivity)
                                      : '';
                                  return onlineStatus.isNotEmpty
                                      ? Text(
                                          onlineStatus,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textSecondary,
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                }
                              },
                              loading: () => const SizedBox(
                                height: 10,
                                width: 60,
                                child: LinearProgressIndicator(
                                  color: Color(0xFF009178),
                                  backgroundColor: AppColors.borderDefault,
                                ),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 24,
                        color: AppColors.primaryBlack,
                      ),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.borderDefault, height: 1),
              const SizedBox(height: 12),

              // Task info
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: taskAsync.when(
                  data: (task) => Row(
                    children: [
                      // Task image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          color: AppColors.backgroundTertiary,
                          image: task != null && task.images != null && task.images!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(task.images!.first),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: task == null || task.images == null || task.images!.isEmpty
                            ? Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 32)
                            : null,
                      ),
                      SizedBox(width: AppSpacing.md),
                      // Task details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task?.title ?? _channel.taskTitle,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: AppTypography.semiBold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              task != null ? 'RM${task.price.toStringAsFixed(2)}' : 'RM--',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: AppTypography.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ),
                  error: (_, __) => Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.borderDefault,
                        ),
                        child: const Icon(Icons.error_outline, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _channel.taskTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.primaryBlack,
                                fontFamily: 'Instrument Sans',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Price unavailable',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textTertiary,
                                fontFamily: 'Instrument Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Action buttons
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.gray900,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Make Offer',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: AppTypography.semiBold,
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gray900,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          side: BorderSide(
                            color: AppColors.borderDark,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                        ),
                        child: Text(
                          'View Seller',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: AppTypography.semiBold,
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Date time header
              messagesAsync.when(
                data: (messages) {
                  if (messages.isNotEmpty) {
                    final latestMessage = messages.last;
                    final date = DateFormat('dd/MM/yy').format(latestMessage.createdAt);
                    final time = DateFormat('h:mm a').format(latestMessage.createdAt);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Chat messages
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: AppColors.borderDefault,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                fontFamily: 'Instrument Sans',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                                fontFamily: 'Instrument Sans',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: messages.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == currentUserId;
                        return _buildMessageBubble(message.content, isMe);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryYellow,
                    ),
                  ),
                  error: (error, __) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.errorRed,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load messages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Seen status
              messagesAsync.when(
                data: (messages) {
                  // Only show seen status if there are messages and last message is from current user
                  if (messages.isNotEmpty && messages.last.senderId == currentUserId) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16, top: 2, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.done_all,
                              size: 14,
                              color: AppColors.successGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Delivered',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Message suggestions
              if (_showSuggestions)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a message or type your own below.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _buildSuggestionChip("I'm interested!"),
                          _buildSuggestionChip("Hello! Could I get this please?"),
                          _buildSuggestionChip("Nice!"),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),

              // Input area
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.borderDefault,
                      width: 1,
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: AppColors.borderDefault,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: 'Text Message',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            isDense: true,
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          cursorColor: AppColors.textPrimary,
                          onChanged: (value) {
                            if (value.isNotEmpty && _showSuggestions) {
                              setState(() {
                                _showSuggestions = false;
                              });
                            }
                          },
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          size: AppSpacing.iconMd,
                          color: _isLoading ? AppColors.textTertiary : AppColors.primary,
                        ),
                        onPressed: _isLoading ? null : _sendMessage,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(width: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ],
          ),
      bottomNavigationBar: Container(
        color: AppColors.backgroundWhite,
        child: SafeArea(
          child: Container(
            height: 64,
            color: AppColors.backgroundWhite,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  iconPath: 'assets/icons/nav_home.svg',
                  label: 'Home',
                  isSelected: _selectedIndex == 0,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                    context.go('/home');
                  },
                ),
                _buildNavItem(
                  iconPath: 'assets/icons/nav_activity.svg',
                  label: 'Activity',
                  isSelected: _selectedIndex == 1,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                    // Navigate to activity
                  },
                ),
                _buildCenterTaskawayButton(
                  isSelected: _selectedIndex == 2,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                    context.go('/create-task');
                  },
                ),
                _buildNavItem(
                  iconPath: 'assets/icons/nav_message.svg',
                  label: 'Message',
                  isSelected: _selectedIndex == 3,
                  onTap: () {
                    // Already on message screen
                  },
                ),
                _buildNavItem(
                  iconPath: 'assets/icons/nav_profile.svg',
                  label: 'Profile',
                  isSelected: _selectedIndex == 4,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 4;
                    });
                    context.go('/home/profile');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.gray200,
              child: Icon(
                Icons.person,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () => _sendSuggestedMessage(text),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: AppColors.borderDefault,
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: AppTypography.medium,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}