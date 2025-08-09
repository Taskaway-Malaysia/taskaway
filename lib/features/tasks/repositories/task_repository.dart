import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../../../core/constants/db_constants.dart';
import 'dart:developer' as dev;

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    supabase: Supabase.instance.client,
  );
});

class TaskRepository {
  final SupabaseClient supabase;
  final String _tableName = DbConstants.tasksTable;

  TaskRepository({required this.supabase});

  // Watch all tasks (stream)
  Stream<List<Task>> watchTasks() {
    try {
      // First attempt to use Realtime subscription
      return supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => Task.fromJson(json)).toList())
          .handleError((error) {
            // Log the Realtime error
            dev.log('Realtime subscription error: $error');
            
            // If Realtime fails, fall back to a polling-based stream
            return _createPollingStream();
          });
    } catch (e) {
      // If setting up the Realtime stream fails, fall back to polling
      dev.log('Error setting up Realtime stream: $e');
      return _createPollingStream();
    }
  }

  // Get tasks by IDs with optional status filter
  Future<List<Task>> getTasksByIds(List<String> ids, {String? status}) async {
    if (ids.isEmpty) return [];
    try {
      var query = supabase.from(_tableName).select();
      final orExpr = ids.map((id) => 'id.eq.$id').join(',');
      query = query.or(orExpr);
      if (status != null) {
        query = query.eq('status', status);
      }
      final response = await query.order('created_at', ascending: false);
      return response.map((json) => Task.fromJson(json)).toList().cast<Task>();
    } catch (e) {
      dev.log('Error fetching tasks by ids: $e');
      return [];
    }
  }

  // Creates a polling-based stream as a fallback when Realtime fails
  Stream<List<Task>> _createPollingStream() {
    // Use a periodic timer to poll data every 3 seconds
    return Stream.periodic(const Duration(seconds: 3), (_) => null)
        .asyncMap((_) => getTasks())
        .asBroadcastStream();
  }

  // Watch a specific task (stream)
  Stream<Task> watchTask(String id) {
    try {
      // First attempt to use Realtime subscription
      // When the stream emits a change, re-fetch the full task data with offers.
      return supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('id', id)
          .asyncMap((_) => getTaskById(id))
          .handleError((error) {
            // Log the Realtime error
            dev.log('Realtime task subscription error: $error');
            
            // If Realtime fails, fall back to a polling-based stream
            return _createTaskPollingStream(id);
          });
    } catch (e) {
      // If setting up the Realtime stream fails, fall back to polling
      dev.log('Error setting up Realtime task stream: $e');
      return _createTaskPollingStream(id);
    }
  }

  // Creates a polling-based stream for a single task as a fallback when Realtime fails
  Stream<Task> _createTaskPollingStream(String id) {
    // Use a periodic timer to poll data every 3 seconds
    return Stream.periodic(const Duration(seconds: 3), (_) => null)
        .asyncMap((_) => getTaskById(id))
        .asBroadcastStream();
  }

  // Get a specific task by ID
  Future<Task> getTaskById(String id) async {
    final response = await supabase
        .from(_tableName)
        .select('*, offers:taskaway_applications(*, tasker_profile:taskaway_profiles(*))')
        .eq('id', id)
        .single();
    
    return Task.fromJson(response);
  }

  // Create a new task
  Future<Task> createTask(Task task) async {
    final response = await supabase
        .from(_tableName)
        .insert(task.toJson())
        .select()
        .single();
    
    return Task.fromJson(response);
  }

  // Update an existing task
  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await supabase
        .from(_tableName)
        .update(data)
        .eq('id', id);
  }

  // Delete a task
  Future<void> deleteTask(String id) async {
    await supabase
        .from(_tableName)
        .delete()
        .eq('id', id);
  }
  
  // Get all tasks (for polling fallback)
  Future<List<Task>> getTasks() async {
    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);
      
      return response.map((json) => Task.fromJson(json)).toList().cast<Task>();
    } catch (e) {
      dev.log('Error fetching tasks: $e');
      return [];
    }
  }
  
  // Watch available tasks for taskers to browse
  Stream<List<Task>> watchAvailableTasks() {
    try {
      // First attempt to use Realtime subscription
      return supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('status', 'open') // Only show open tasks
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => Task.fromJson(json)).toList())
          .handleError((error) {
            // Log the Realtime error
            dev.log('Realtime subscription error for available tasks: $error');
            
            // If Realtime fails, fall back to a polling-based stream
            return _createAvailableTasksPollingStream();
          });
    } catch (e) {
      // If setting up the Realtime stream fails, fall back to polling
      dev.log('Error setting up Realtime stream for available tasks: $e');
      return _createAvailableTasksPollingStream();
    }
  }

  // Creates a polling-based stream for available tasks as a fallback when Realtime fails
  Stream<List<Task>> _createAvailableTasksPollingStream() {
    // Use a periodic timer to poll data every 3 seconds
    return Stream.periodic(const Duration(seconds: 3), (_) => null)
        .asyncMap((_) => getAvailableTasks())
        .asBroadcastStream();
  }
  
  // Get available tasks (for polling fallback)
  Future<List<Task>> getAvailableTasks() async {
    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .eq('status', 'open')
          .order('created_at', ascending: false);
      
      return response.map((json) => Task.fromJson(json)).toList().cast<Task>();
    } catch (e) {
      dev.log('Error fetching available tasks: $e');
      return [];
    }
  }
}
