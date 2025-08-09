// ignore_for_file: constant_identifier_names

/// Enum representing the status of a task.
/// Matches the `taskaway_task_status` PostgreSQL enum.
enum TaskStatus {
  pending,
  open,
  in_progress,
  pending_approval,
  pending_payment,
  completed,
  cancelled;

  String toJson() => name;
  static TaskStatus fromJson(String json) =>
      TaskStatus.values.firstWhere((e) => e.name == json);
}
