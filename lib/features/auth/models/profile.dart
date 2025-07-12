class Profile {
  final String id;
  final String? username;
  final String fullName;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final double rating;
  final int totalTasks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? dateOfBirth;
  final int? postcode;

  Profile({
    required this.id,
    this.username,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.rating = 0.0,
    this.totalTasks = 0,
    this.createdAt,
    this.updatedAt,
    this.dateOfBirth,
    this.postcode,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      totalTasks: json['total_tasks'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth'] as String) : null,
      postcode: json['postcode'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (username != null) 'username': username,
    'full_name': fullName,
    'role': role,
    if (phone != null) 'phone': phone,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    'rating': rating,
    'total_tasks': totalTasks,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    if (dateOfBirth != null) 'date_of_birth': dateOfBirth!.toIso8601String(),
    if (postcode != null) 'postcode': postcode,
  };

  Profile copyWith({
    String? id,
    String? username,
    String? fullName,
    String? role,
    String? phone,
    String? avatarUrl,
    double? rating,
    int? totalTasks,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dateOfBirth,
    int? postcode,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      totalTasks: totalTasks ?? this.totalTasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      postcode: postcode ?? this.postcode,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile &&
        other.id == id &&
        other.username == username &&
        other.fullName == fullName &&
        other.role == role &&
        other.phone == phone &&
        other.avatarUrl == avatarUrl &&
        other.rating == rating &&
        other.totalTasks == totalTasks &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.dateOfBirth == dateOfBirth &&
        other.postcode == postcode;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      fullName,
      role,
      phone,
      avatarUrl,
      rating,
      totalTasks,
      createdAt,
      updatedAt,
      dateOfBirth,
      postcode,
    );
  }
}
