import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final taskControllerProvider = Provider((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskController(repository);
});

// Stream of all tasks
final taskStreamProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskControllerProvider).watchTasks();
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
  final TaskRepository _repository;

  TaskController(this._repository);

  Stream<List<Task>> watchTasks() => _repository.watchTasks();
  
  Stream<Task> watchTask(String id) => _repository.watchTask(id);

  Future<Task> getTaskById(String id) => _repository.getTaskById(id);

  Future<Task> createTask({
    required String title,
    required String description,
    required String category,
    required double price,
    required String location,
    required DateTime scheduledTime,
    required String posterId,
  }) async {
    final task = Task(
      title: title,
      description: description,
      category: category,
      price: price,
      location: location,
      scheduledTime: scheduledTime,
      status: 'open',
      posterId: posterId,
    );
    return _repository.createTask(task);
  }

  Future<Task> updateTask(String id, Map<String, dynamic> data) async {
    // Convert the data map to use snake_case for database compatibility
    final dbData = {
      if (data['title'] != null) 'title': data['title'],
      if (data['description'] != null) 'description': data['description'],
      if (data['category'] != null) 'category': data['category'],
      if (data['price'] != null) 'price': data['price'],
      if (data['location'] != null) 'location': data['location'],
      if (data['scheduledTime'] != null) 'scheduled_time': (data['scheduledTime'] as DateTime).toIso8601String(),
      if (data['status'] != null) 'status': data['status'],
      if (data['taskerId'] != null) 'tasker_id': data['taskerId'],
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    return _repository.updateTask(id, dbData);
  }

  Future<bool> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);
      return true;
    } catch (e) {
      return false;
    }
  }
} 