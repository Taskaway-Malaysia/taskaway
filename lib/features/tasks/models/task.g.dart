// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskImpl _$$TaskImplFromJson(Map<String, dynamic> json) => _$TaskImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      location: json['location'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      status: $enumDecodeNullable(_$TaskStatusEnumMap, json['status']) ??
          TaskStatus.pending,
      posterId: json['poster_id'] as String,
      taskerId: json['tasker_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$TaskImplToJson(_$TaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'price': instance.price,
      'location': instance.location,
      'scheduled_time': instance.scheduledTime.toIso8601String(),
      'status': instance.status.toJson(),
      'poster_id': instance.posterId,
      'tasker_id': instance.taskerId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$TaskStatusEnumMap = {
  TaskStatus.pending: 'pending',
  TaskStatus.open: 'open',
  TaskStatus.assigned: 'assigned',
  TaskStatus.inProgress: 'in_progress',
  TaskStatus.completed: 'completed',
  TaskStatus.cancelled: 'cancelled',
  TaskStatus.disputed: 'disputed',
};
