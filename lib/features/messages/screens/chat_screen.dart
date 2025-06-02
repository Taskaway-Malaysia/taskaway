import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/message_controller.dart';
import '../models/channel.dart';
import '../models/message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Channel channel;

  const ChatScreen({
    super.key,
    required this.channel,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Message> _messages = [];
  bool _hasReachedTop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initial data refresh
    ref.refresh(channelMessagesProvider(widget.channel.id));
    
    // Mark messages as read
    _markMessagesAsRead();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Schedule scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      ref.refresh(channelMessagesProvider(widget.channel.id));
      _markMessagesAsRead();
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    // Load more messages when reaching near the top (when scrolling up)
    if (_scrollController.position.pixels <= 50 && !_isLoadingMore && !_hasReachedTop) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_messages.isEmpty || _isLoadingMore || _hasReachedTop) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final oldestMessage = _messages.first;
      final olderMessages = await ref.read(messageControllerProvider).getOlderMessages(
        channelId: widget.channel.id,
        beforeTimestamp: oldestMessage.createdAt,
      );

      if (olderMessages.isEmpty) {
        setState(() {
          _hasReachedTop = true;
        });
      } else {
        setState(() {
          _messages = [...olderMessages, ..._messages];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading older messages: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    // Only refresh messages, don't auto-scroll
    await ref.refresh(channelMessagesProvider(widget.channel.id).future);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(messageControllerProvider).sendMessage(
        channelId: widget.channel.id,
        content: message,
      );
      
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Since we're using reverse: true, 0 is the bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await ref.read(messageControllerProvider).markChannelAsRead(widget.channel.id);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final messages = ref.watch(channelMessagesProvider(widget.channel.id));
    final dateFormat = DateFormat('MMM d, y h:mm a');
    final isPoster = user?.id == widget.channel.posterId;

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          ref.refresh(channelMessagesProvider(widget.channel.id));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isPoster 
              ? theme.colorScheme.primary // Blue for poster
              : theme.colorScheme.tertiary, // Orange for tasker
          foregroundColor: isPoster
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onTertiary,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.channel.taskTitle,
                style: TextStyle(
                  color: isPoster
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onTertiary,
                ),
              ),
              Text(
                isPoster
                  ? 'Chatting with ${widget.channel.taskerName}'
                  : 'Chatting with ${widget.channel.posterName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: (isPoster
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onTertiary)
                      .withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: messages.when(
                  data: (messagesList) {
                    // Update local messages list
                    if (_messages.isEmpty) {
                      // Only auto-scroll on initial load
                      _messages = messagesList;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });
                    } else if (messagesList.length > _messages.length) {
                      // Only auto-scroll for new messages
                      final isAtBottom = _scrollController.position.pixels == 0;
                      _messages = messagesList;
                      if (isAtBottom) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });
                      }
                    } else {
                      _messages = messagesList;
                    }
                    
                    if (messagesList.isEmpty) {
                      return Center(
                        child: Text(
                          'No messages yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          reverse: true, // Display messages from bottom to top
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppConstants.defaultPadding),
                          itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isLoadingMore && index == 0) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final message = _messages[_isLoadingMore ? index - 1 : index];
                            final isCurrentUser = message.senderId == user?.id;

                            return Align(
                              alignment: isCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isCurrentUser && message.senderName != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          message.senderName!,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: isCurrentUser
                                                ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                                : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    Text(
                                      message.content,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: isCurrentUser
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateFormat.format(message.createdAt),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isCurrentUser
                                            ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                            : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (_hasReachedTop)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'No more messages',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error loading messages: $error',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
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