// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileImpl _$$ProfileImplFromJson(Map<String, dynamic> json) =>
    _$ProfileImpl(
      id: json['id'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      postcode: (json['postcode'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ProfileImplToJson(_$ProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'full_name': instance.fullName,
      'role': instance.role,
      'phone': instance.phone,
      'avatar_url': instance.avatarUrl,
      'rating': instance.rating,
      'total_tasks': instance.totalTasks,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'postcode': instance.postcode,
    };
