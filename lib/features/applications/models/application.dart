enum ApplicationStatus {
  pending,   // Offer submitted, awaiting response
  accepted,  // Offer accepted by poster
  rejected;  // Offer rejected by poster
  
  static ApplicationStatus fromString(String? value) {
    if (value == null) return ApplicationStatus.pending;
    
    switch (value.toLowerCase()) {
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.pending;
    }
  }
  
  String toJson() => name;
}

class Application {
  final String? id;
  final String taskId;
  final String taskerId;
  final ApplicationStatus status;
  final double offerPrice;
  final String? message;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? taskerProfile;

  Application({
    this.id,
    required this.taskId,
    required this.taskerId,
    this.status = ApplicationStatus.pending,
    required this.offerPrice,
    this.message,
    this.createdAt,
    this.updatedAt,
    this.taskerProfile,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as String?,
      taskId: json['task_id'] as String,
      taskerId: json['tasker_id'] as String,
      status: ApplicationStatus.fromString(json['status'] as String?),
      offerPrice: json['offer_price'] != null ? (json['offer_price'] as num).toDouble() : 0.0,
      message: json['message'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      taskerProfile: json['tasker_profile'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'task_id': taskId,
    'tasker_id': taskerId,
    'status': status.toJson(),
    'offer_price': offerPrice,
    if (message != null) 'message': message,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    if (taskerProfile != null) 'tasker_profile': taskerProfile,
  };

  Application copyWith({
    String? id,
    String? taskId,
    String? taskerId,
    ApplicationStatus? status,
    double? offerPrice,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? taskerProfile,
  }) {
    return Application(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskerId: taskerId ?? this.taskerId,
      status: status ?? this.status,
      offerPrice: offerPrice ?? this.offerPrice,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      taskerProfile: taskerProfile ?? this.taskerProfile,
    );
  }
}
