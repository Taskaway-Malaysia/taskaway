import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    supabase: Supabase.instance.client,
  );
});

class TaskRepository {
  final SupabaseClient supabase;
  static const String _tableName = 'taskaway_tasks';

  TaskRepository({required this.supabase});

  Future<List<Task>> getTasks({
    String? status,
    String? posterId,
    String? taskerId,
    String? category,
  }) async {
    var query = supabase
        .from(_tableName)
        .select();

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
    return response.map((json) => Task.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Task> getTaskById(String id) async {
    final data = await supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .single();
    
    return Task.fromJson(data as Map<String, dynamic>);
  }

  Future<Task> createTask(Task task) async {
    final response = await supabase
        .from(_tableName)
        .insert(task.toJson())
        .select()
        .single();
    
    return Task.fromJson(response as Map<String, dynamic>);
  }

  Future<Task> updateTask(String id, Map<String, dynamic> data) async {
    final response = await supabase
        .from(_tableName)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    
    return Task.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteTask(String id) async {
    await supabase
        .from(_tableName)
        .delete()
        .eq('id', id);
  }

  Stream<List<Task>> watchTasks() {
    return supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((response) => 
            response.map((json) => Task.fromJson(json as Map<String, dynamic>)).toList());
  }

  Stream<Task> watchTask(String id) {
    return supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((response) {
          if (response.isEmpty) {
            throw Exception('Task not found');
          }
          return Task.fromJson(response.first as Map<String, dynamic>);
        });
  }
} 