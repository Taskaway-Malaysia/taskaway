import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final taskControllerProvider = Provider((ref) {
  return TaskController(ref);
});

final taskStreamProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchTasks();
});

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasks = ref.watch(taskStreamProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCategories = ref.watch(selectedCategoriesProvider);
  
  return tasks.whenData((tasks) {
    return tasks.where((task) {
      final matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(searchQuery.toLowerCase());
          
      final matchesCategories = selectedCategories.isEmpty ||
          selectedCategories.any((category) => category == task.category);
          
      return matchesSearch && matchesCategories;
    }).toList();
  });
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoriesProvider = StateProvider<List<String>>((ref) => []);

class TaskController {
  final Ref _ref;

  TaskController(this._ref);

  Future<void> createTask({
    required String title,
    required String description,
    required String category,
    required double price,
    required String location,
    required DateTime scheduledTime,
  }) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      await _ref.read(taskRepositoryProvider).createTask(Task(
        title: title,
        description: description,
        price: price,
        status: 'open',
        posterId: currentUser.id,
        category: category,
        location: location,
        scheduledTime: scheduledTime,
      ));
    } catch (e) {
      print('Error creating task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  Future<List<Task>> getTasks({
    String? status,
    String? posterId,
    String? taskerId,
    String? category,
  }) async {
    try {
      final repository = _ref.read(taskRepositoryProvider);
      return await repository.getTasks(
        status: status,
        posterId: posterId,
        taskerId: taskerId,
        category: category,
      );
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  Stream<List<Task>> watchTasks() {
    final repository = _ref.read(taskRepositoryProvider);
    return repository.watchTasks();
  }

  Stream<Task> watchTask(String taskId) {
    final repository = _ref.read(taskRepositoryProvider);
    return repository.watchTask(taskId);
  }

  Future<bool> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      final repository = _ref.read(taskRepositoryProvider);
      await repository.updateTask(id, updates);
      return true;
    } catch (error) {
      print('Error updating task: $error');
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      final repository = _ref.read(taskRepositoryProvider);
      await repository.deleteTask(id);
      return true;
    } catch (error) {
      return false;
    }
  }
} 