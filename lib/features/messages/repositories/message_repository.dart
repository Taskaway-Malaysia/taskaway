import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/db_constants.dart';
import '../models/message.dart';
import '../models/channel.dart';
import 'package:logger/logger.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(
    supabase: Supabase.instance.client,
  );
});

class MessageRepository {
  final SupabaseClient supabase;
  final String _tableName = DbConstants.messagesTable;
  final String _channelsTable = 'taskaway_channels';
  final _logger = Logger();

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
      _logger.e('Error creating channel: $e');
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
      _logger.e('Error getting channel: $e');
      return null;
    }
  }

  Stream<List<Channel>> watchUserChannels(String userId) {
    return supabase
        .from(_channelsTable)
        .stream(primaryKey: ['id'])
        .map((response) async {
          // Filter channels where user is either poster or tasker
          final userChannels = response.where((row) =>
            row['poster_id'] == userId || row['tasker_id'] == userId
          ).toList();
          
          // Sort by last_message_at in descending order
          userChannels.sort((a, b) {
            final aTime = a['last_message_at'] != null 
              ? DateTime.parse(a['last_message_at'] as String)
              : DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b['last_message_at'] != null 
              ? DateTime.parse(b['last_message_at'] as String)
              : DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime); // Descending order
          });
          
          // Convert to Channel objects
          final channels = userChannels.map((json) => Channel.fromJson(json)).toList();
          
          if (channels.isEmpty) return channels;

          // Get unread counts for each channel
          for (final channel in channels) {
            final otherUserId = userId == channel.posterId ? channel.taskerId : channel.posterId;
            final unreadResponse = await supabase
                .from(_tableName)
                .select()
                .eq('channel_id', channel.id)
                .eq('sender_id', otherUserId)
                .eq('is_read', false);
            channel.copyWith(unreadCount: (unreadResponse as List).length);
          }
          
          return channels;
        }).asyncMap((future) => future);
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

      // Update the message
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
      _logger.e('Error sending message: $e');
      throw Exception('Failed to send message');
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
      _logger.e('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> markChannelAsRead(String channelId, String userId) async {
    try {
      // First get the channel to determine user's role
      final channel = await supabase
          .from(_channelsTable)
          .select()
          .eq('id', channelId)
          .single();

      final isPoster = channel['poster_id'] == userId;
      
      // Mark messages as read based on user's role
      await supabase
          .from(_tableName)
          .update({ 'is_read': true })
          .eq('channel_id', channelId)
          .eq('sender_id', isPoster ? channel['tasker_id'] : channel['poster_id']);
    } catch (e) {
      _logger.e('Error marking channel as read: $e');
      throw Exception('Failed to mark channel as read');
    }
  }

  /// Get a page of messages for a channel
  Future<List<Message>> getChannelMessages(String channelId, {
    int page = 0,
    int limit = 10,
  }) async {
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

    // Sort messages in ascending order for display
    updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return updatedMessages;
  }

  /// Watch for new messages in a channel
  Stream<List<Message>> watchChannelMessages(String channelId) {
    return supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at', ascending: false)
        .limit(10)
        .asyncMap((response) async {
          final messages = response.map((json) => Message.fromJson(json)).toList();
          
          // Get unique sender IDs
          final senderIds = messages.map((m) => m.senderId).toSet();
          
          // Fetch all sender profiles in one query
          if (senderIds.isNotEmpty) {
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
          }
          
          return messages;
        });
  }

  /// Check if there are more messages available
  Future<bool> hasMoreMessages(String channelId, int currentPage, int limit) async {
    final offset = (currentPage + 1) * limit;
    
    final response = await supabase
        .from(_tableName)
        .select('id')
        .eq('channel_id', channelId)
        .range(offset, offset)
        .limit(1);
    
    return (response as List).isNotEmpty;
  }

  Future<List<Message>> getOlderMessages({
    required String channelId,
    required DateTime beforeTimestamp,
    int limit = 10,
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
      _logger.e('Error fetching older messages: $e');
      return [];
    }
  }

  Stream<List<Message>> watchNewChannelMessages(String channelId) {
    return supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at', ascending: false)
        .limit(10)
        .asyncMap((response) async {
          final messages = response.map((json) => Message.fromJson(json)).toList();
          
          // Get unique sender IDs
          final senderIds = messages.map((m) => m.senderId).toSet();
          
          // Fetch all sender profiles in one query
          if (senderIds.isNotEmpty) {
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

            // Sort messages back to ascending order for display
            updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            return updatedMessages;
          }
          
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return messages;
        });
  }
} 