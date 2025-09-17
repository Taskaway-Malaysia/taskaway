import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  Widget _buildNavItem(dynamic iconData, String label, int index) {
    final isSelected = _selectedIndex == index;
    final isTaskaway = label == 'Taskaway';

    // Helper to build icon widget
    Widget buildIcon() {
      if (iconData is String) {
        // Single SVG icon
        return SvgPicture.asset(
          iconData,
          width: isTaskaway ? 16 : 24,
          height: isTaskaway ? 16 : 24,
          colorFilter: ColorFilter.mode(
            isTaskaway ? Colors.black : (isSelected ? const Color(0xFF202020) : const Color(0xFF575656)),
            BlendMode.srcIn,
          ),
        );
      } else if (iconData is List<String>) {
        // Composite SVG icon (for message and profile)
        return SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (label == 'Message') ...[
                // Message body (envelope rectangle)
                Positioned(
                  bottom: 2,
                  child: SvgPicture.asset(
                    iconData[1], // message_icon_body.svg
                    width: 22,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      isSelected ? const Color(0xFF202020) : const Color(0xFF575656),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                // Message top (envelope flap)
                Positioned(
                  top: 7,
                  child: SvgPicture.asset(
                    iconData[0], // message_icon_top.svg
                    width: 22,
                    height: 8,
                    colorFilter: ColorFilter.mode(
                      isSelected ? const Color(0xFF202020) : const Color(0xFF575656),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ] else if (label == 'Profile') ...[
                // Profile body (shoulders)
                Positioned(
                  bottom: 3,
                  child: SvgPicture.asset(
                    iconData[1], // profile_icon_body.svg
                    width: 19,
                    height: 8,
                    colorFilter: ColorFilter.mode(
                      isSelected ? const Color(0xFF202020) : const Color(0xFF575656),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                // Profile head (circle)
                Positioned(
                  top: 3,
                  child: SvgPicture.asset(
                    iconData[0], // profile_icon_head.svg
                    width: 11,
                    height: 11,
                    colorFilter: ColorFilter.mode(
                      isSelected ? const Color(0xFF202020) : const Color(0xFF575656),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      } else {
        // Material icon fallback
        return Icon(
          iconData as IconData,
          size: isTaskaway ? 16 : 24,
          color: isTaskaway ? Colors.black : (isSelected ? const Color(0xFF202020) : const Color(0xFF575656)),
        );
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // Navigate to appropriate screen
        if (index == 0) context.go('/home');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isTaskaway)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDB5B),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFFFFC333),
                  width: 0.5,
                ),
              ),
              child: Center(child: buildIcon()),
            )
          else
            buildIcon(),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
              color: isSelected ? const Color(0xFF202020) : const Color(0xFF575656),
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Purple header curve
          Positioned(
            top: 0,
            left: 662,
            child: Container(
              width: 396,
              height: 171,
              decoration: const BoxDecoration(
                color: Color(0xFF525DC0),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),

          Column(
            children: [
              // Safe area spacer
              SafeArea(
                bottom: false,
                child: Container(),
              ),

              // Navigation bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/back_arrow.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF050316),
                                fontFamily: 'Instrument Sans',
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
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF009178),
                                      fontFamily: 'Instrument Sans',
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
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF009178),
                                            fontFamily: 'Instrument Sans',
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
                                  backgroundColor: Color(0xFFE0E0E0),
                                ),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: SizedBox(
                        width: 24,
                        height: 24,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 4,
                              child: SvgPicture.asset(
                                'assets/icons/more_menu_dot1.svg',
                                width: 4,
                                height: 4,
                                colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              child: SvgPicture.asset(
                                'assets/icons/more_menu_dot2.svg',
                                width: 4,
                                height: 4,
                                colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              child: SvgPicture.asset(
                                'assets/icons/more_menu_dot3.svg',
                                width: 4,
                                height: 4,
                                colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Task info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: taskAsync.when(
                  data: (task) => Row(
                    children: [
                      // Task image
                      Container(
                        width: 49,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey.shade300,
                          image: task != null && task.images != null && task.images!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(task.images!.first),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 7),
                      // Task details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task?.title ?? _channel.taskTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF050316),
                                fontFamily: 'Instrument Sans',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              task != null ? 'RM${task.price.toStringAsFixed(2)}' : 'RM--',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF050316),
                                fontFamily: 'Instrument Sans',
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
                        color: Color(0xFFFFDB5B),
                      ),
                    ),
                  ),
                  error: (_, __) => Row(
                    children: [
                      Container(
                        width: 49,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey.shade300,
                        ),
                        child: const Icon(Icons.error_outline, color: Colors.grey),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _channel.taskTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF050316),
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
                                color: Color(0xFF8F9098),
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

              const SizedBox(height: 19),

              // Action buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDB5B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Make Offer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            fontFamily: 'Noto Sans',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    InkWell(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF606163),
                          ),
                        ),
                        child: const Text(
                          'View Seller',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            fontFamily: 'Noto Sans',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

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
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8F9098),
                            fontFamily: 'Instrument Sans',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8F9098),
                            fontFamily: 'Instrument Sans',
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

              const SizedBox(height: 42),

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
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontFamily: 'Instrument Sans',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
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
                      separatorBuilder: (context, index) => const SizedBox(height: 30),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == currentUserId;
                        return _buildMessageBubble(message.content, isMe);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFDB5B),
                    ),
                  ),
                  error: (error, __) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load messages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
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
                      padding: const EdgeInsets.only(right: 21, top: 10, bottom: 10),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Icon(
                              Icons.done_all,
                              size: 12,
                              color: Color(0xFF009178),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Delivered',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontFamily: 'Instrument Sans',
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
                  padding: const EdgeInsets.symmetric(horizontal: 19),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a message or type your own below.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF202020).withOpacity(0.34),
                          fontFamily: 'Noto Sans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildSuggestionChip("I'm interested!"),
                          const SizedBox(width: 14),
                          _buildSuggestionChip("Hello! Could I get this please?"),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),

              // Input area
              Container(
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFE8E8E8),
                      width: 1,
                    ),
                  ),
                ),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF606163),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 13),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFC5C6CC),
                            ),
                          ),
                          child: const Icon(
                            Icons.emoji_emotions_outlined,
                            size: 16,
                            color: Color(0xFFC5C6CC),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Text Message',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF575656),
                              fontFamily: 'Noto Sans',
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Noto Sans',
                            color: Colors.black,
                          ),
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
                        icon: const Icon(
                          Icons.send,
                          size: 17,
                          color: Color(0xFFC5C6CC),
                        ),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, -1),
              blurRadius: 4,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem('assets/icons/home_icon_outline.svg', 'Home', 0),
                _buildNavItem('assets/icons/activity_icon_outline.svg', 'Activity', 1),
                _buildNavItem('assets/icons/taskaway_icon_outline.svg', 'Taskaway', 2),
                _buildNavItem([
                  'assets/icons/message_icon_top.svg',
                  'assets/icons/message_icon_body.svg',
                ], 'Message', 3),
                _buildNavItem([
                  'assets/icons/profile_icon_head.svg',
                  'assets/icons/profile_icon_body.svg',
                ], 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            child: Icon(
              Icons.person,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2D),
                fontFamily: 'Instrument Sans',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () => _sendSuggestedMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF606163),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
            fontFamily: 'Noto Sans',
          ),
        ),
      ),
    );
  }
}