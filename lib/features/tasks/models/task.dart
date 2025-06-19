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
  final List<String>? images;
  final String? dateOption;
  final bool? needsSpecificTime;
  final String? timeOfDay;
  final String? locationType;
  final bool? providesMaterials;

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
    this.images,
    this.dateOption,
    this.needsSpecificTime,
    this.timeOfDay,
    this.locationType,
    this.providesMaterials,
  })  : id = id ?? '',
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
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : null,
      dateOption: json['date_option'] as String?,
      needsSpecificTime: json['needs_specific_time'] as bool?,
      timeOfDay: json['time_of_day'] as String?,
      locationType: json['location_type'] as String?,
      providesMaterials: json['provides_materials'] as bool?,
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
      if (images != null) 'images': images,
      if (dateOption != null) 'date_option': dateOption,
      if (needsSpecificTime != null) 'needs_specific_time': needsSpecificTime,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (locationType != null) 'location_type': locationType,
      if (providesMaterials != null) 'provides_materials': providesMaterials,
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
    List<String>? images,
    String? dateOption,
    bool? needsSpecificTime,
    String? timeOfDay,
    String? locationType,
    bool? providesMaterials,
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
      images: images ?? this.images,
      dateOption: dateOption ?? this.dateOption,
      needsSpecificTime: needsSpecificTime ?? this.needsSpecificTime,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      locationType: locationType ?? this.locationType,
      providesMaterials: providesMaterials ?? this.providesMaterials,
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
          updatedAt == other.updatedAt &&
          _listEquals(images, other.images) &&
          dateOption == other.dateOption &&
          needsSpecificTime == other.needsSpecificTime &&
          timeOfDay == other.timeOfDay &&
          locationType == other.locationType &&
          providesMaterials == other.providesMaterials;

  // Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

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
      updatedAt.hashCode ^
      images.hashCode ^
      dateOption.hashCode ^
      needsSpecificTime.hashCode ^
      timeOfDay.hashCode ^
      locationType.hashCode ^
      providesMaterials.hashCode;
}
