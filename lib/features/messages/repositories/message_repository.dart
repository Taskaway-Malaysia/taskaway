import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/message.dart';
import '../models/channel.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(
    supabase: Supabase.instance.client,
  );
});

class MessageRepository {
  final SupabaseClient supabase;
  final String _tableName = AppConstants.messagesTable;
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
      
      return response != null 
          ? Channel.fromJson(response)
          : null;
    } catch (e) {
      print('Error getting channel: $e');
      return null;
    }
  }

  Stream<List<Channel>> watchUserChannels(String userId) {
    return supabase
        .from(_channelsTable)
        .stream(primaryKey: ['id'])
        .eq('poster_id', userId)
        .map((response) {
          // Filter for either poster_id or tasker_id matching
          final filteredResponse = response.where((row) => 
            row['poster_id'] == userId || row['tasker_id'] == userId
          ).toList();
          
          // Sort by last_message_at in descending order
          filteredResponse.sort((a, b) {
            final aTime = a['last_message_at'] != null 
              ? DateTime.parse(a['last_message_at'] as String)
              : DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b['last_message_at'] != null 
              ? DateTime.parse(b['last_message_at'] as String)
              : DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime); // Descending order
          });
          
          return filteredResponse
              .map((json) => Channel.fromJson(json))
              .toList();
        });
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

  Stream<List<Message>> watchChannelMessages(String channelId) {
    return supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at')
        .map((response) => response
            .map((json) => Message.fromJson(json))
            .toList());
  }

  Future<List<Message>> getChannelMessages(String channelId) async {
    final response = await supabase
        .from(_tableName)
        .select()
        .eq('channel_id', channelId)
        .order('created_at');
    
    return response
        .map((json) => Message.fromJson(json))
        .toList();
  }
} 