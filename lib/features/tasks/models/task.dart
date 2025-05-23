class Task {
  final String id;
  final String title;
  final String description;
  final double price;
  final String status;
  final String posterId;
  final String? taskerId;
  final Map<String, dynamic>? posterProfile;
  final Map<String, dynamic>? taskerProfile;
  final String category;
  final String location;
  final DateTime scheduledTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? get posterName => posterProfile?['full_name'] as String?;
  String? get taskerName => taskerProfile?['full_name'] as String?;

  Task({
    String? id,
    required this.title,
    required this.description,
    required this.price,
    required this.status,
    required this.posterId,
    this.taskerId,
    this.posterProfile,
    this.taskerProfile,
    required this.category,
    required this.location,
    required this.scheduledTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? '',
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
      posterId: json['poster_id'] as String,
      taskerId: json['tasker_id'] as String?,
      posterProfile: json['poster_profile'] as Map<String, dynamic>?,
      taskerProfile: json['tasker_profile'] as Map<String, dynamic>?,
      category: json['category'] as String,
      location: json['location'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'status': status,
      'poster_id': posterId,
      'tasker_id': taskerId,
      'category': category,
      'location': location,
      'scheduled_time': scheduledTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? status,
    String? posterId,
    String? taskerId,
    Map<String, dynamic>? posterProfile,
    Map<String, dynamic>? taskerProfile,
    String? category,
    String? location,
    DateTime? scheduledTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      status: status ?? this.status,
      posterId: posterId ?? this.posterId,
      taskerId: taskerId ?? this.taskerId,
      posterProfile: posterProfile ?? this.posterProfile,
      taskerProfile: taskerProfile ?? this.taskerProfile,
      category: category ?? this.category,
      location: location ?? this.location,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          price == other.price &&
          status == other.status &&
          posterId == other.posterId &&
          taskerId == other.taskerId &&
          posterProfile == other.posterProfile &&
          taskerProfile == other.taskerProfile &&
          category == other.category &&
          location == other.location &&
          scheduledTime == other.scheduledTime &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      price.hashCode ^
      status.hashCode ^
      posterId.hashCode ^
      taskerId.hashCode ^
      posterProfile.hashCode ^
      taskerProfile.hashCode ^
      category.hashCode ^
      location.hashCode ^
      scheduledTime.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
} 