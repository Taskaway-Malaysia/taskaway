import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/db_constants.dart';
import '../models/message.dart';
import '../models/channel.dart';
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
      print('Error creating channel: $e');
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
      print('Error getting channel: $e');
      return null;
    }
  }

  /// Creates or gets existing channel and sends welcome message for task confirmation
  Future<Channel> initiateTaskConversation({
    required String taskId,
    required String taskTitle,
    required String posterId,
    required String posterName,
    required String taskerId,
    required String taskerName,
    String? welcomeMessage,
  }) async {
    try {
      // Check if channel already exists
      Channel? existingChannel = await getChannelByTaskId(taskId);
      
      if (existingChannel != null) {
        return existingChannel;
      }

      // Create new channel
      final channel = await createChannel(
        taskId: taskId,
        taskTitle: taskTitle,
        posterId: posterId,
        posterName: posterName,
        taskerId: taskerId,
        taskerName: taskerName,
      );

      // Send welcome message from poster
      final message = welcomeMessage ?? 
          "Hi $taskerName! I've confirmed you for the task '$taskTitle'. Looking forward to working with you! 🎉";
      
      await sendMessage(
        channelId: channel.id,
        senderId: posterId,
        content: message,
      );

      return channel;
    } catch (e) {
      print('Error initiating task conversation: $e');
      throw Exception('Failed to initiate conversation');
    }
  }

  Stream<List<Channel>> watchUserChannels(String userId, {int limit = 50}) {
    dev.log('[MessageRepository] Watching channels for user: $userId with limit: $limit');

    return supabase
        .from(_channelsTable)
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .limit(limit)  // Limit at database level - only fetch first N channels
        .map((response) async {
          dev.log('[MessageRepository] Received ${response.length} channels from database');

          // Filter channels where user is either poster or tasker (in memory, but on limited dataset)
          final userChannels = response.where((row) {
            return row['poster_id'] == userId || row['tasker_id'] == userId;
          }).toList();

          dev.log('[MessageRepository] Filtered to ${userChannels.length} user channels');

          // Convert to Channel objects
          final channels = userChannels.map((json) => Channel.fromJson(json)).toList();

          if (channels.isEmpty) return channels;

          // Batch query for unread counts - get all in one query instead of N queries
          final channelIds = channels.map((c) => c.id).toList();
          final unreadCounts = await _getUnreadCountsBatch(channelIds, userId);

          // Apply unread counts to channels
          for (final channel in channels) {
            channel.copyWith(unreadCount: unreadCounts[channel.id] ?? 0);
          }

          dev.log('[MessageRepository] Returning ${channels.length} channels with unread counts');
          return channels;
        }).asyncMap((future) => future);
  }

  /// Efficiently get unread counts for multiple channels in a single query
  Future<Map<String, int>> _getUnreadCountsBatch(List<String> channelIds, String currentUserId) async {
    if (channelIds.isEmpty) return {};

    try {
      // Single query to get all unread messages for all channels
      final response = await supabase
          .from(_tableName)
          .select('channel_id')
          .inFilter('channel_id', channelIds)
          .neq('sender_id', currentUserId)  // Only messages from other users
          .eq('is_read', false);

      // Count unread messages per channel
      final Map<String, int> counts = {};
      for (final row in response) {
        final channelId = row['channel_id'] as String;
        counts[channelId] = (counts[channelId] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      dev.log('[MessageRepository] Error getting unread counts: $e');
      return {};
    }
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
      print('Error sending message: $e');
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
      print('Error getting unread count: $e');
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
      print('Error marking channel as read: $e');
      throw Exception('Failed to mark channel as read');
    }
  }

  /// Get a page of messages for a channel
  Future<List<Message>> getChannelMessages(String channelId, {
    int page = 0,
    int limit = 5,  // Increased from 10 to 50
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
        .limit(50)  // Increased from 10 to 50
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
    int limit = 50,  // Increased from 10 to 50
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
      print('Error fetching older messages: $e');
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