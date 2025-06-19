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

  // Watch all tasks (stream)
  Stream<List<Task>> watchTasks() {
    return supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Task.fromJson(json)).toList());
  }
  
  // Watch a specific task (stream)
  Stream<Task> watchTask(String id) {
    return supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => Task.fromJson(data.first));
  }

  // Get a specific task by ID
  Future<Task> getTaskById(String id) async {
    final response = await supabase
        .from(_tableName)
        .select()
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
  Future<Task> updateTask(String id, Map<String, dynamic> data) async {
    final response = await supabase
        .from(_tableName)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    
    return Task.fromJson(response);
  }

  // Delete a task
  Future<void> deleteTask(String id) async {
    await supabase
        .from(_tableName)
        .delete()
        .eq('id', id);
  }
}
