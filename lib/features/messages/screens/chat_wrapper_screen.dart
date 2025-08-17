import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/channel.dart';
import 'message_screen.dart';
import '../../auth/controllers/auth_controller.dart';

/// Wrapper screen that loads channel data before showing the message screen
class ChatWrapperScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChatWrapperScreen({
    super.key,
    required this.channelId,
  });

  @override
  ConsumerState<ChatWrapperScreen> createState() => _ChatWrapperScreenState();
}

class _ChatWrapperScreenState extends ConsumerState<ChatWrapperScreen> {
  final _supabase = Supabase.instance.client;
  Channel? _channel;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChannel();
  }

  Future<void> _loadChannel() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Parse channel ID to extract task ID
      // Channel ID format is typically "task_<taskId>"
      String taskId = widget.channelId;
      if (taskId.startsWith('task_')) {
        taskId = taskId.substring(5);
      }

      // Fetch task details
      final taskResponse = await _supabase
          .from('taskaway_tasks')
          .select('id, title, poster_id, tasker_id')
          .eq('id', taskId)
          .single();

      if (taskResponse == null) {
        setState(() {
          _error = 'Task not found';
          _isLoading = false;
        });
        return;
      }

      // Fetch poster profile
      final posterResponse = await _supabase
          .from('taskaway_profiles')
          .select('full_name')
          .eq('id', taskResponse['poster_id'])
          .single();

      // Fetch tasker profile if exists
      String taskerName = '';
      if (taskResponse['tasker_id'] != null) {
        final taskerResponse = await _supabase
            .from('taskaway_profiles')
            .select('full_name')
            .eq('id', taskResponse['tasker_id'])
            .single();
        taskerName = taskerResponse['full_name'] ?? '';
      }

      // Get last message info
      final messagesResponse = await _supabase
          .from('taskaway_messages')
          .select('message, created_at, sender_id')
          .eq('channel_id', widget.channelId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Count unread messages
      final unreadResponse = await _supabase
          .from('taskaway_messages')
          .select('id')
          .eq('channel_id', widget.channelId)
          .neq('sender_id', currentUser.id)
          .eq('is_read', false);

      final unreadCount = (unreadResponse as List).length;

      // Create channel object
      final channel = Channel(
        id: widget.channelId,
        taskId: taskResponse['id'],
        taskTitle: taskResponse['title'] ?? '',
        posterId: taskResponse['poster_id'] ?? '',
        posterName: posterResponse['full_name'] ?? '',
        taskerId: taskResponse['tasker_id'] ?? '',
        taskerName: taskerName,
        createdAt: DateTime.now(), // This could be fetched from the first message
        lastMessageAt: messagesResponse != null
            ? DateTime.parse(messagesResponse['created_at'])
            : null,
        lastMessageContent: messagesResponse?['message'],
        lastMessageSenderId: messagesResponse?['sender_id'],
        unreadCount: unreadCount,
      );

      setState(() {
        _channel = channel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load conversation: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6C5CE7),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_channel == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Not Found'),
          backgroundColor: const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Conversation not found',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return MessageScreen(channel: _channel!);
  }
}