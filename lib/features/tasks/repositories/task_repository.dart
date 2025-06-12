import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../../../core/constants/db_constants.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    supabase: Supabase.instance.client,
  );
});

class TaskRepository {
  final SupabaseClient supabase;
  final String _tableName = DbConstants.tasksTable;

  TaskRepository({required this.supabase});

  Future<List<Task>> getTasks({
    String? status,
    String? posterId,
    String? taskerId,
    String? category,
    bool includeProfiles = false,
  }) async {
    var query = supabase
        .from(_tableName)
        .select(includeProfiles ? '''
          *,
          poster_profile:taskaway_profiles!poster_id(full_name),
          tasker_profile:taskaway_profiles!tasker_id(full_name)
        ''' : '*');

    if (status != null) {
      query = query.eq('status', status);
    }
    if (posterId != null) {
      query = query.eq('poster_id', posterId);
    }
    if (taskerId != null) {
      query = query.eq('tasker_id', taskerId);
    }
    if (category != null) {
      query = query.eq('category', category);
    }

    final response = await query;
    return response.map((json) => Task.fromJson(json)).toList();
  }

  Future<Task> getTaskById(String id, {bool includeProfiles = false}) async {
    final data = await supabase
        .from(_tableName)
        .select(includeProfiles ? '''
          *,
          poster_profile:taskaway_profiles!poster_id(full_name),
          tasker_profile:taskaway_profiles!tasker_id(full_name)
        ''' : '*')
        .eq('id', id)
        .single();
    
    return Task.fromJson(data);
  }

  Future<Task> createTask(Task task) async {
    final response = await supabase
        .from(_tableName)
        .insert(task.toJson())
        .select()
        .single();
    
    return Task.fromJson(response);
  }

  Future<Task> updateTask(String id, Map<String, dynamic> data) async {
    try {
      // First verify the task exists and the user has permission
      final currentTask = await supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      // Perform the update
      final response = await supabase
          .from(_tableName)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      
      return Task.fromJson(response);
    } on PostgrestException catch (e) {
      print('PostgrestException in TaskRepository.updateTask: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('Error in TaskRepository.updateTask: $e');
      throw Exception('Failed to update task: ${e.toString()}');
    }
  }

  Future<void> deleteTask(String id) async {
    await supabase
        .from(_tableName)
        .delete()
        .eq('id', id);
  }

  Stream<List<Task>> watchTasks({bool includeProfiles = false}) {
    return supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((response) => response.map((json) => Task.fromJson(json)).toList());
  }

  Stream<Task> watchTask(String id, {bool includeProfiles = false}) async* {
    try {
      // Get initial data with profiles
      final initialData = await getTaskById(id, includeProfiles: true);
      yield initialData;

      // Stream updates
      await for (final list in supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('id', id)) {
        if (list.isEmpty) continue; // Skip empty updates instead of throwing
        
        final json = list.first;
        // Preserve the profile data from initial fetch
        yield Task.fromJson({
          ...json,
          'poster_profile': initialData.posterProfile,
          'tasker_profile': initialData.taskerProfile,
        });
      }
    } catch (e) {
      print('Error in watchTask: $e');
      rethrow; // Rethrow to let StreamBuilder handle the error
    }
  }

  // Helper method to fetch profiles for a task when needed
  Future<Task> getTaskWithProfiles(Task task) async {
    try {
      final posterProfile = await supabase
          .from('taskaway_profiles')
          .select('full_name')
          .eq('id', task.posterId)
          .single();
      
      Map<String, dynamic>? taskerProfile;
      final taskerId = task.taskerId;
      if (taskerId != null) {
        taskerProfile = await supabase
            .from('taskaway_profiles')
            .select('full_name')
            .eq('id', taskerId)
            .single();
      }

      return Task.fromJson({
        ...task.toJson(),
        'id': task.id,
        'poster_profile': posterProfile,
        'tasker_profile': taskerProfile,
      });
    } catch (e) {
      print('Error fetching profiles for task ${task.id}: $e');
      return task;
    }
  }
} 