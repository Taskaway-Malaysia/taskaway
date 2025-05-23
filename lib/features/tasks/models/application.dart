class Application {
  final String id;
  final String taskId;
  final String taskerId;
  final String taskerName;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Application({
    String? id,
    required this.taskId,
    required this.taskerId,
    required this.taskerName,
    required this.message,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? '',
    status = status ?? 'pending',
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      taskerId: json['tasker_id'] as String,
      taskerName: json['profiles']?['full_name'] as String? ?? 'Unknown Tasker',
      message: json['message'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'tasker_id': taskerId,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Application copyWith({
    String? id,
    String? taskId,
    String? taskerId,
    String? taskerName,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Application(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskerId: taskerId ?? this.taskerId,
      taskerName: taskerName ?? this.taskerName,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Application &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          taskId == other.taskId &&
          taskerId == other.taskerId &&
          taskerName == other.taskerName &&
          message == other.message &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      taskId.hashCode ^
      taskerId.hashCode ^
      taskerName.hashCode ^
      message.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
} 