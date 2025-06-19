import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/channel.dart';
import '../models/message.dart';
import 'package:logger/logger.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Channel channel;

  const ChatScreen({
    super.key,
    required this.channel,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  late Channel _channel;
  late List<Message> _messages;

  @override
  void initState() {
    super.initState();

    // Set channel from widget
    _channel = widget.channel;

    // Initialize with hardcoded messages
    _initializeHardcodedMessages();

    // Schedule scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _initializeHardcodedMessages() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    _messages = [
      Message(
        id: '1',
        channelId: _channel.id,
        senderId: _channel.posterId,
        content:
            'Hi, thank you for accepting my task! I\'m really glad to have your help.',
        createdAt: yesterday.add(const Duration(hours: 10)),
        senderName: _channel.posterName,
      ),
      Message(
        id: '2',
        channelId: _channel.id,
        senderId: _channel.taskerId,
        content: 'you\'re welcome! So, do you still have all the parts?',
        createdAt: yesterday.add(const Duration(hours: 10)),
        senderName: _channel.taskerName,
      ),
      Message(
        id: '3',
        channelId: _channel.id,
        senderId: _channel.posterId,
        content:
            'Yes, I still have all the parts? Do you think you\'ll be available to start tomorrow?',
        createdAt: now.add(const Duration(hours: 10)),
        senderName: _channel.posterName,
      ),
      Message(
        id: '4',
        channelId: _channel.id,
        senderId: _channel.taskerId,
        content: 'Absolutely, I can definitely start tomorrow.',
        createdAt: now.add(const Duration(hours: 10)),
        senderName: _channel.taskerName,
      ),
      Message(
        id: '5',
        channelId: _channel.id,
        senderId: _channel.posterId,
        content: 'I\'ll be available to assist if needed.',
        createdAt: now.add(const Duration(hours: 10, minutes: 1)),
        senderName: _channel.posterName,
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _messages.isNotEmpty) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Create a new message and add it to the list
    final newMessage = Message(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      channelId: _channel.id,
      senderId: _channel.taskerId, // Assuming current user is the tasker
      content: text,
      createdAt: DateTime.now(),
      senderName: _channel.taskerName,
    );

    setState(() {
      _messages = [..._messages, newMessage];
      _isLoading = false;
      _messageController.clear();
    });

    // Schedule scroll to bottom after the message is added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Assuming current user is the tasker for this example
    final currentUserId = _channel.taskerId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                _channel.posterName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Color(0xFF6C5CE7)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _channel.posterName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _channel.taskTitle,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date separators and messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + 2, // +2 for date separators
              itemBuilder: (context, index) {
                // Add date separators
                if (index == 0) {
                  return _buildDateSeparator('Yesterday');
                } else if (index == 3) {
                  return _buildDateSeparator('Today');
                }

                // Adjust index for actual messages
                final messageIndex = index < 3 ? index - 1 : index - 2;
                if (messageIndex < 0 || messageIndex >= _messages.length) {
                  return const SizedBox.shrink();
                }

                final message = _messages[messageIndex];
                final isCurrentUser = message.senderId == currentUserId;

                return _buildMessageBubble(message, isCurrentUser);
              },
            ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Text Message',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6C5CE7),
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            date,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                message.senderName?.isNotEmpty == true
                    ? message.senderName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          if (!isCurrentUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? const Color(0xFFE9ECEF) // Light gray for current user
                        : const Color(
                            0xFFFFF8E1), // Light yellow for other user
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '10:00 AM',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600),
                      ),
                      if (isCurrentUser)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.done_all,
                              size: 14, color: Colors.orange.shade300),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
