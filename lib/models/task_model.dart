import 'package:freezed_annotation/freezed_annotation.dart';

// part 'task_model.freezed.dart';
// part 'task_model.g.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    required String description,
    required String category,
    required double price,
    required String location,
    required DateTime deadline,
    required String posterId,
    @Default('open') String status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
} 