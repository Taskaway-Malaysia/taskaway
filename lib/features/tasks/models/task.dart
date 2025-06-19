import 'package:freezed_annotation/freezed_annotation.dart';
import 'task_status.dart';

// ignore_for_file: invalid_annotation_target

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Task({
    required String id,
    required String title,
    required String description,
    required String category,
    required double price,
    required String location,
    required DateTime scheduledTime,
    @Default(TaskStatus.pending) TaskStatus status,
    required String posterId,
    String? taskerId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
