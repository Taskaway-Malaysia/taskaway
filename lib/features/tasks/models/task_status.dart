import 'package:freezed_annotation/freezed_annotation.dart';

/// Enum representing the status of a task.
/// Matches the `taskaway_task_status` PostgreSQL enum.
enum TaskStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('open')
  open,
  @JsonValue('assigned')
  assigned,
  @JsonValue('in_progress') // Assuming this might be a status
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('disputed') // Assuming this might be a status
  disputed;

  String toJson() => name;
  static TaskStatus fromJson(String json) => values.byName(json);
}
