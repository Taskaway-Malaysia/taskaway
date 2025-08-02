class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? taskId;
  final String? applicationId;
  final String? paymentId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.taskId,
    this.applicationId,
    this.paymentId,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: _typeFromString(json['type'] as String),
      taskId: json['task_id'] as String?,
      applicationId: json['application_id'] as String?,
      paymentId: json['payment_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.dbValue,
      'task_id': taskId,
      'application_id': applicationId,
      'payment_id': paymentId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'task_posted':
        return NotificationType.taskPosted;
      case 'offer_received':
        return NotificationType.offerReceived;
      case 'offer_accepted':
        return NotificationType.offerAccepted;
      case 'task_completed':
        return NotificationType.taskCompleted;
      case 'payment_received':
        return NotificationType.paymentReceived;
      default:
        return NotificationType.taskPosted;
    }
  }
}

enum NotificationType {
  taskPosted,
  offerReceived,
  offerAccepted,
  taskCompleted,
  paymentReceived,
}

extension NotificationTypeExtension on NotificationType {
  String get dbValue {
    switch (this) {
      case NotificationType.taskPosted:
        return 'task_posted';
      case NotificationType.offerReceived:
        return 'offer_received';
      case NotificationType.offerAccepted:
        return 'offer_accepted';
      case NotificationType.taskCompleted:
        return 'task_completed';
      case NotificationType.paymentReceived:
        return 'payment_received';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.taskPosted:
        return 'New Task Available';
      case NotificationType.offerReceived:
        return 'New Offer Received';
      case NotificationType.offerAccepted:
        return 'Offer Accepted';
      case NotificationType.taskCompleted:
        return 'Task Completed';
      case NotificationType.paymentReceived:
        return 'Payment Received';
    }
  }

  String get iconName {
    switch (this) {
      case NotificationType.taskPosted:
        return 'work';
      case NotificationType.offerReceived:
        return 'local_offer';
      case NotificationType.offerAccepted:
        return 'check_circle';
      case NotificationType.taskCompleted:
        return 'task_alt';
      case NotificationType.paymentReceived:
        return 'payment';
    }
  }
} 