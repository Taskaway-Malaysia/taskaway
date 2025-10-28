// Task Comment class for task Q&A and comments
class TaskComment {
  final String id;
  final String taskId;
  final String userId;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? userProfile;

  // Getter for user's name from profile
  String? get userName => userProfile?['full_name'] as String?;

  // Getter for user's avatar from profile
  String? get userAvatar => userProfile?['avatar_url'] as String?;

  TaskComment({
    String? id,
    required this.taskId,
    required this.userId,
    required this.comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.userProfile,
  })  : id = id ?? '',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create TaskComment from JSON (from Supabase)
  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'] as String? ?? '',
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      comment: json['comment'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      userProfile: json['user_profile'] as Map<String, dynamic>?,
    );
  }

  // Convert TaskComment to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'task_id': taskId,
      'user_id': userId,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // CopyWith method for creating modified copies
  TaskComment copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? userProfile,
  }) {
    return TaskComment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userProfile: userProfile ?? this.userProfile,
    );
  }

  @override
  String toString() {
    return 'TaskComment(id: $id, taskId: $taskId, userId: $userId, userName: $userName, comment: ${comment.substring(0, comment.length > 50 ? 50 : comment.length)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaskComment &&
        other.id == id &&
        other.taskId == taskId &&
        other.userId == userId &&
        other.comment == comment;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        taskId.hashCode ^
        userId.hashCode ^
        comment.hashCode;
  }
}
