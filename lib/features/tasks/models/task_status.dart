// ignore_for_file: constant_identifier_names

/// Enum representing the status of a task.
/// Matches the `taskaway_task_status` PostgreSQL enum.
enum TaskStatus {
  open,          // Task posted, awaiting offers
  accepted,      // Offer accepted, payment authorized
  in_progress,   // Work has started
  pending_approval, // Work submitted, awaiting review
  completed,     // Task finished and approved
  cancelled;     // Task cancelled

  String toJson() => name;
  static TaskStatus fromJson(String json) =>
      TaskStatus.values.firstWhere((e) => e.name == json);
}
