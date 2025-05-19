import 'package:flutter/foundation.dart';

@immutable
class Channel {
  final String id;
  final String taskId;
  final String taskTitle;
  final String posterId;
  final String posterName;
  final String taskerId;
  final String taskerName;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessageContent;
  final String? lastMessageSenderId;

  const Channel({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.posterId,
    required this.posterName,
    required this.taskerId,
    required this.taskerName,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessageContent,
    this.lastMessageSenderId,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      taskTitle: json['task_title'] as String,
      posterId: json['poster_id'] as String,
      posterName: json['poster_name'] as String,
      taskerId: json['tasker_id'] as String,
      taskerName: json['tasker_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessageContent: json['last_message_content'] as String?,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'task_title': taskTitle,
      'poster_id': posterId,
      'poster_name': posterName,
      'tasker_id': taskerId,
      'tasker_name': taskerName,
      'created_at': createdAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_content': lastMessageContent,
      'last_message_sender_id': lastMessageSenderId,
    };
  }

  Channel copyWith({
    String? id,
    String? taskId,
    String? taskTitle,
    String? posterId,
    String? posterName,
    String? taskerId,
    String? taskerName,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessageContent,
    String? lastMessageSenderId,
  }) {
    return Channel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      posterId: posterId ?? this.posterId,
      posterName: posterName ?? this.posterName,
      taskerId: taskerId ?? this.taskerId,
      taskerName: taskerName ?? this.taskerName,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
    );
  }
} 