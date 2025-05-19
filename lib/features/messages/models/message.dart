import 'package:flutter/foundation.dart';

@immutable
class Message {
  final String id;
  final String channelId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatar;

  const Message({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
    };
  }

  Message copyWith({
    String? id,
    String? channelId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    String? senderName,
    String? senderAvatar,
  }) {
    return Message(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }
} 