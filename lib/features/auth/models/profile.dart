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
  final String? bio;
  final String? about;
  final List<String>? skills;
  final List<String>? myWorks;
  final DateTime? lastSignInAt;
  final double? latitude;
  final double? longitude;
  final bool? isAvailable;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolderName;
  final String? bankVerificationStatus;
  final DateTime? bankVerifiedAt;
  final String? fcmToken;
  final bool notificationsEnabled;
  final DateTime? lastSeen;

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
    this.bio,
    this.about,
    this.skills,
    this.myWorks,
    this.lastSignInAt,
    this.latitude,
    this.longitude,
    this.isAvailable,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolderName,
    this.bankVerificationStatus,
    this.bankVerifiedAt,
    this.fcmToken,
    this.notificationsEnabled = true,
    this.lastSeen,
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
      bio: json['bio'] as String?,
      about: json['about'] as String?,
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      myWorks: json['my_works'] != null ? List<String>.from(json['my_works']) : null,
      lastSignInAt: json['last_sign_in_at'] != null ? DateTime.parse(json['last_sign_in_at'] as String) : null,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      isAvailable: json['is_available'] as bool?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankAccountHolderName: json['bank_account_holder_name'] as String?,
      bankVerificationStatus: json['bank_verification_status'] as String?,
      bankVerifiedAt: json['bank_verified_at'] != null ? DateTime.parse(json['bank_verified_at'] as String) : null,
      fcmToken: json['fcm_token'] as String?,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen'] as String) : null,
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
    if (bio != null) 'bio': bio,
    if (about != null) 'about': about,
    if (skills != null) 'skills': skills,
    if (myWorks != null) 'my_works': myWorks,
    if (lastSignInAt != null) 'last_sign_in_at': lastSignInAt!.toIso8601String(),
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (isAvailable != null) 'is_available': isAvailable,
    if (bankName != null) 'bank_name': bankName,
    if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
    if (bankAccountHolderName != null) 'bank_account_holder_name': bankAccountHolderName,
    if (bankVerificationStatus != null) 'bank_verification_status': bankVerificationStatus,
    if (bankVerifiedAt != null) 'bank_verified_at': bankVerifiedAt!.toIso8601String(),
    if (fcmToken != null) 'fcm_token': fcmToken,
    'notifications_enabled': notificationsEnabled,
    if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
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
    String? bio,
    String? about,
    List<String>? skills,
    List<String>? myWorks,
    DateTime? lastSignInAt,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountHolderName,
    String? bankVerificationStatus,
    DateTime? bankVerifiedAt,
    String? fcmToken,
    bool? notificationsEnabled,
    DateTime? lastSeen,
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
      bio: bio ?? this.bio,
      about: about ?? this.about,
      skills: skills ?? this.skills,
      myWorks: myWorks ?? this.myWorks,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountHolderName: bankAccountHolderName ?? this.bankAccountHolderName,
      bankVerificationStatus: bankVerificationStatus ?? this.bankVerificationStatus,
      bankVerifiedAt: bankVerifiedAt ?? this.bankVerifiedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastSeen: lastSeen ?? this.lastSeen,
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
        other.postcode == postcode &&
        other.bio == bio &&
        other.about == about &&
        other.skills == skills &&
        other.myWorks == myWorks &&
        other.lastSignInAt == lastSignInAt &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.isAvailable == isAvailable &&
        other.bankName == bankName &&
        other.bankAccountNumber == bankAccountNumber &&
        other.bankAccountHolderName == bankAccountHolderName &&
        other.bankVerificationStatus == bankVerificationStatus &&
        other.bankVerifiedAt == bankVerifiedAt &&
        other.fcmToken == fcmToken &&
        other.notificationsEnabled == notificationsEnabled &&
        other.lastSeen == lastSeen;
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
      bio,
      about,
      skills,
      myWorks,
      Object.hash(
        lastSignInAt,
        latitude,
        longitude,
        isAvailable,
        bankName,
        bankAccountNumber,
        bankAccountHolderName,
        bankVerificationStatus,
        bankVerifiedAt,
        fcmToken,
        notificationsEnabled,
        lastSeen,
      ),
    );
  }

  // Helper getter for profile image URL (alias for avatarUrl)
  String? get profileImageUrl => avatarUrl;
}
