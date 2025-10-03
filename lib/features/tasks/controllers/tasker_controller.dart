import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/features/auth/models/profile.dart';
import 'package:taskaway/features/tasks/repositories/tasker_repository.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import 'dart:developer' as dev;

/// Provider for TaskerRepository
final taskerRepositoryProvider = Provider<TaskerRepository>((ref) {
  return TaskerRepository(Supabase.instance.client);
});

/// Provider to fetch available taskers for a specific task
///
/// Parameters: Map with 'taskId'
/// Returns: List of nearby available taskers
final availableTaskersProvider = FutureProvider.autoDispose.family<List<Profile>, String>((ref, taskId) async {
  try {
    dev.log('[TaskerController] Fetching available taskers for task: $taskId');

    // Get task details to determine location and category
    final taskResponse = await Supabase.instance.client
        .from('taskaway_tasks')
        .select()
        .eq('id', taskId)
        .single();

    final task = Task.fromJson(taskResponse as Map<String, dynamic>);

    // Use task location if available, otherwise default to KL area
    final latitude = task.latitude ?? 3.139;
    final longitude = task.longitude ?? 101.687;

    dev.log('[TaskerController] Task location: ($latitude, $longitude), category: ${task.category}');

    // Fetch nearby taskers
    final repository = ref.read(taskerRepositoryProvider);
    final taskers = await repository.getAvailableTaskers(
      category: task.category,
      latitude: latitude,
      longitude: longitude,
      radiusKm: 10.0,
    );

    dev.log('[TaskerController] Found ${taskers.length} available taskers');
    return taskers;
  } catch (e, st) {
    dev.log('[TaskerController] Error fetching available taskers: $e\n$st');
    rethrow;
  }
});

/// Provider to watch task status changes (for detecting acceptance)
///
/// Uses Supabase real-time to listen for task updates
final taskStatusStreamProvider = StreamProvider.autoDispose.family<Task, String>((ref, taskId) {
  dev.log('[TaskerController] Setting up real-time subscription for task: $taskId');

  return Supabase.instance.client
      .from('taskaway_tasks')
      .stream(primaryKey: ['id'])
      .eq('id', taskId)
      .limit(1)
      .map((data) {
        if (data.isEmpty) {
          throw Exception('Task not found');
        }
        return Task.fromJson(data.first as Map<String, dynamic>);
      });
});

/// Controller for tasker-related operations
class TaskerController extends StateNotifier<AsyncValue<void>> {
  final TaskerRepository _repository;

  TaskerController(this._repository) : super(const AsyncValue.data(null));

  /// Accept a task (called by tasker)
  Future<void> acceptTask({
    required String taskId,
    required String taskerId,
  }) async {
    state = const AsyncValue.loading();

    try {
      dev.log('[TaskerController] Accepting task $taskId for tasker $taskerId');

      await _repository.acceptTask(
        taskId: taskId,
        taskerId: taskerId,
      );

      state = const AsyncValue.data(null);
      dev.log('[TaskerController] Task accepted successfully');
    } catch (e, st) {
      dev.log('[TaskerController] Error accepting task: $e\n$st');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider for TaskerController
final taskerControllerProvider = StateNotifierProvider<TaskerController, AsyncValue<void>>((ref) {
  final repository = ref.read(taskerRepositoryProvider);
  return TaskerController(repository);
});
