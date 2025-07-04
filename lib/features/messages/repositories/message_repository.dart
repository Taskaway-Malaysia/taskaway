import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/db_constants.dart';
import '../models/message.dart';
import '../models/channel.dart';
import 'dart:async';
import 'dart:developer' as dev;

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(
    supabase: Supabase.instance.client,
  );
});

class MessageRepository {
  final SupabaseClient supabase;
  final String _tableName = DbConstants.messagesTable;
  final String _channelsTable = 'taskaway_channels';
  
  // Keep track of active subscriptions to avoid duplicates
  final Map<String, RealtimeChannel> _activeChannelSubscriptions = {};
  final Map<String, RealtimeChannel> _activeMessageSubscriptions = {};

  MessageRepository({required this.supabase});

  Future<Channel> createChannel({
    required String taskId,
    required String taskTitle,
    required String posterId,
    required String posterName,
    required String taskerId,
    required String taskerName,
  }) async {
    try {
      final response = await supabase
          .from(_channelsTable)
          .insert({
            'task_id': taskId,
            'task_title': taskTitle,
            'poster_id': posterId,
            'poster_name': posterName,
            'tasker_id': taskerId,
            'tasker_name': taskerName,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Channel.fromJson(response);
    } catch (e) {
      dev.log('Error creating channel: $e');
      throw Exception('Failed to create channel');
    }
  }

  Future<Channel?> getChannelByTaskId(String taskId) async {
    try {
      final response = await supabase
          .from(_channelsTable)
          .select()
          .eq('task_id', taskId)
          .single();
      
      return Channel.fromJson(response);
    } catch (e) {
      dev.log('Error getting channel: $e');
      return null;
    }
  }

  /// Enhanced real-time stream for user channels with better error handling
  Stream<List<Channel>> watchUserChannels(String userId) {
    // Create a stream controller for better error handling
    late StreamController<List<Channel>> controller;
    RealtimeChannel? subscription;

    controller = StreamController<List<Channel>>(
      onListen: () async {
        try {
          // Get initial data
          final initialData = await _getUserChannels(userId);
          if (!controller.isClosed) {
            controller.add(initialData);
          }

          // Set up real-time subscription
          subscription = supabase
              .channel('user_channels_$userId')
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: _channelsTable,
                callback: (payload) async {
                  try {
                    // Refresh data when channels change
                    final updatedData = await _getUserChannels(userId);
                    if (!controller.isClosed) {
                      controller.add(updatedData);
                    }
                  } catch (e) {
                    dev.log('Error handling channel change: $e');
                    if (!controller.isClosed) {
                      controller.addError(e);
                    }
                  }
                },
              )
              .subscribe();

          _activeChannelSubscriptions['user_$userId'] = subscription!;
        } catch (e) {
          dev.log('Error setting up channel subscription: $e');
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      },
      onCancel: () {
        subscription?.unsubscribe();
        _activeChannelSubscriptions.remove('user_$userId');
        controller.close();
      },
    );

    return controller.stream;
  }

  /// Helper method to get user channels
  Future<List<Channel>> _getUserChannels(String userId) async {
    final response = await supabase
        .from(_channelsTable)
        .select()
        .or('poster_id.eq.$userId,tasker_id.eq.$userId')
        .order('last_message_at', ascending: false);

    final channels = response.map((json) => Channel.fromJson(json)).toList();
    
    // Get unread counts
    for (final channel in channels) {
      final otherUserId = userId == channel.posterId ? channel.taskerId : channel.posterId;
      try {
        final unreadResponse = await supabase
            .from(_tableName)
            .select()
            .eq('channel_id', channel.id)
            .eq('sender_id', otherUserId)
            .eq('is_read', false);
        
        // Update channel with unread count (this creates a new instance)
        final index = channels.indexOf(channel);
        channels[index] = channel.copyWith(unreadCount: (unreadResponse as List).length);
      } catch (e) {
        dev.log('Error getting unread count for channel ${channel.id}: $e');
      }
    }

    return channels;
  }

  Future<Message> sendMessage({
    required String channelId,
    required String senderId,
    required String content,
  }) async {
    try {
      // Get sender profile information
      final senderProfile = await supabase
          .from('taskaway_profiles')
          .select('full_name, avatar_url')
          .eq('id', senderId)
          .single();

      // Insert the message
      final response = await supabase
          .from(_tableName)
          .insert({
            'channel_id': channelId,
            'sender_id': senderId,
            'content': content,
            'created_at': DateTime.now().toIso8601String(),
            'is_read': false,
          })
          .select()
          .single();

      // Update the channel's last message info
      await supabase
          .from(_channelsTable)
          .update({
            'last_message_at': DateTime.now().toIso8601String(),
            'last_message_content': content,
            'last_message_sender_id': senderId,
          })
          .eq('id', channelId);

      // Combine the message data with sender profile info
      final messageData = response;
      messageData['sender_name'] = senderProfile['full_name'];
      messageData['sender_avatar'] = senderProfile['avatar_url'];

      return Message.fromJson(messageData);
    } catch (e) {
      dev.log('Error sending message: $e');
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<int> getUnreadCount(String channelId, String userId) async {
    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .eq('channel_id', channelId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      dev.log('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> markChannelAsRead(String channelId, String userId) async {
    try {
      // Mark all messages in the channel that were NOT sent by the current user as read
      await supabase
          .from(_tableName)
          .update({'is_read': true})
          .eq('channel_id', channelId)
          .neq('sender_id', userId);
    } catch (e) {
      dev.log('Error marking channel as read: $e');
      throw Exception('Failed to mark channel as read');
    }
  }

  /// Enhanced real-time stream for channel messages
  Stream<List<Message>> watchChannelMessages(String channelId) {
    // Create a stream controller for better error handling
    late StreamController<List<Message>> controller;
    RealtimeChannel? subscription;

    controller = StreamController<List<Message>>(
      onListen: () async {
        try {
          // Get initial messages
          final initialMessages = await getChannelMessages(channelId);
          if (!controller.isClosed) {
            controller.add(initialMessages);
          }

          // Set up real-time subscription for new messages
          subscription = supabase
              .channel('messages_$channelId')
              .onPostgresChanges(
                event: PostgresChangeEvent.all, // Listen to INSERT, UPDATE, DELETE
                schema: 'public',
                table: _tableName,
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'channel_id',
                  value: channelId,
                ),
                callback: (payload) async {
                  try {
                    dev.log('Real-time message event: ${payload.eventType}');
                    
                    // Refresh messages when any change occurs
                    final updatedMessages = await getChannelMessages(channelId);
                    if (!controller.isClosed) {
                      controller.add(updatedMessages);
                    }
                  } catch (e) {
                    dev.log('Error handling message change: $e');
                    if (!controller.isClosed) {
                      controller.addError(e);
                    }
                  }
                },
              )
              .subscribe();

          _activeMessageSubscriptions[channelId] = subscription!;
        } catch (e) {
          dev.log('Error setting up message subscription: $e');
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      },
      onCancel: () {
        subscription?.unsubscribe();
        _activeMessageSubscriptions.remove(channelId);
        controller.close();
      },
    );

    return controller.stream;
  }

  /// Get a page of messages for a channel
  Future<List<Message>> getChannelMessages(String channelId, {
    int page = 0,
    int limit = 50, // Increased limit for better UX
  }) async {
    try {
      final offset = page * limit;
      
      final response = await supabase
          .from(_tableName)
          .select()
          .eq('channel_id', channelId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final messages = response.map((json) => Message.fromJson(json)).toList();
      
      // Get unique sender IDs
      final senderIds = messages.map((m) => m.senderId).toSet();
      
      if (senderIds.isEmpty) return [];

      // Fetch all sender profiles in one query
      final profiles = await supabase
          .from('taskaway_profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', senderIds.toList());
              
      // Create a map of profiles for quick lookup
      final profileMap = {
        for (var profile in profiles) 
          profile['id'] as String: profile
      };
      
      // Update messages with sender info
      final updatedMessages = messages.map((message) {
        final senderProfile = profileMap[message.senderId];
        return message.copyWith(
          senderName: senderProfile?['full_name'] as String?,
          senderAvatar: senderProfile?['avatar_url'] as String?,
        );
      }).toList();

      // Sort messages in ascending order for display (oldest first)
      updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return updatedMessages;
    } catch (e) {
      dev.log('Error getting channel messages: $e');
      throw Exception('Failed to load messages: ${e.toString()}');
    }
  }

  /// Check if there are more messages available
  Future<bool> hasMoreMessages(String channelId, int currentPage, int limit) async {
    try {
      final offset = (currentPage + 1) * limit;
      
      final response = await supabase
          .from(_tableName)
          .select('id')
          .eq('channel_id', channelId)
          .range(offset, offset)
          .limit(1);
      
      return (response as List).isNotEmpty;
    } catch (e) {
      dev.log('Error checking for more messages: $e');
      return false;
    }
  }

  Future<List<Message>> getOlderMessages({
    required String channelId,
    required DateTime beforeTimestamp,
    int limit = 20,
  }) async {
    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .eq('channel_id', channelId)
          .lt('created_at', beforeTimestamp.toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit);

      final messages = response.map((json) => Message.fromJson(json)).toList();
      
      // Get unique sender IDs
      final senderIds = messages.map((m) => m.senderId).toSet();
      
      if (senderIds.isEmpty) return [];

      // Fetch all sender profiles in one query
      final profiles = await supabase
          .from('taskaway_profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', senderIds.toList());
              
      // Create a map of profiles for quick lookup
      final profileMap = {
        for (var profile in profiles) 
          profile['id'] as String: profile
      };
      
      // Update messages with sender info
      final updatedMessages = messages.map((message) {
        final senderProfile = profileMap[message.senderId];
        return message.copyWith(
          senderName: senderProfile?['full_name'] as String?,
          senderAvatar: senderProfile?['avatar_url'] as String?,
        );
      }).toList();

      return updatedMessages;
    } catch (e) {
      dev.log('Error fetching older messages: $e');
      return [];
    }
  }

  /// Manually reconnect a channel subscription
  void reconnectChannel(String channelId) {
    final subscription = _activeMessageSubscriptions[channelId];
    subscription?.subscribe();
  }

  /// Clean up all subscriptions (call this when disposing)
  void dispose() {
    for (final subscription in _activeChannelSubscriptions.values) {
      subscription.unsubscribe();
    }
    for (final subscription in _activeMessageSubscriptions.values) {
      subscription.unsubscribe();
    }
    _activeChannelSubscriptions.clear();
    _activeMessageSubscriptions.clear();
  }
} 