import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../repositories/task_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/db_constants.dart';

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

// Provider to expose categories
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(taskControllerProvider).getCategories();
});

class TaskController {
  final TaskRepository _repository;
  final _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();

  TaskController(this._repository);

  Stream<List<Task>> watchTasks() => _repository.watchTasks();
  
  Stream<Task> watchTask(String id) => _repository.watchTask(id);

  Future<Task> getTaskById(String id) => _repository.getTaskById(id);

  // Upload images to Supabase storage and return URLs
  Future<List<String>> _uploadTaskImages(List<File> images, String taskId) async {
    return await _supabaseService.uploadFiles(
      bucket: 'task_images',
      folderPath: 'tasks/$taskId',
      files: images,
    );
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required String category,
    required double price,
    required String location,
    required DateTime scheduledTime,
    required String posterId,
    String? dateOption,
    bool? needsSpecificTime,
    String? timeOfDay,
    String? locationType,
    bool? providesMaterials,
    List<File>? images,
  }) async {
    // Create the task first to get an ID
    final task = Task(
      id: '',
      title: title,
      description: description,
      category: category,
      price: price,
      location: location,
      scheduledTime: scheduledTime,
      status: 'open',
      posterId: posterId,
      dateOption: dateOption,
      needsSpecificTime: needsSpecificTime,
      timeOfDay: timeOfDay,
      locationType: locationType,
      providesMaterials: providesMaterials,
      images: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final createdTask = await _repository.createTask(task);
    
    // If there are images, upload them and update the task with image URLs
    if (images != null && images.isNotEmpty) {
      final imageUrls = await _uploadTaskImages(images, createdTask.id);
      
      if (imageUrls.isNotEmpty) {
        // Update the task with image URLs
        await _repository.updateTask(createdTask.id, {
          'images': imageUrls,
        });
        
        // Return the updated task
        return await _repository.getTaskById(createdTask.id);
      }
    }
    
    return createdTask;
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
      // Get the task to access its images
      final task = await _repository.getTaskById(id);
      
      // Delete the task from the database
      await _repository.deleteTask(id);
      
      // Delete associated images if they exist
      if (task.images?.isNotEmpty == true) {
        // Extract file paths from URLs
        final filePaths = task.images!.map((url) {
          // Extract the path portion after the bucket name
          final uri = Uri.parse(url);
          final pathSegments = uri.pathSegments;
          // Skip the first segment (usually 'storage') and the bucket name
          return pathSegments.sublist(2).join('/');
        }).toList();
        
        await _supabaseService.deleteFiles(
          bucket: 'task_images',
          filePaths: filePaths,
        );
      }
      
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }
  
  // Get all available categories from the database
  Future<List<Category>> getCategories() async {
    try {
      final response = await _supabase
          .from(DbConstants.categoriesTable)
          .select()
          .order('name');
      
      return response.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      // Return default categories if there's an error
      return _getDefaultCategories();
    }
  }
  
  // Fallback method to provide default categories if DB fetch fails
  List<Category> _getDefaultCategories() {
    return [
      Category(
        id: 'handyman',
        name: 'Handyman',
        icon: 'handyman_outlined',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'cleaning',
        name: 'Cleaning',
        icon: 'cleaning_services_outlined',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'gardening',
        name: 'Gardening',
        icon: 'yard_outlined',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'painting',
        name: 'Painting',
        icon: 'format_paint_outlined',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'organizing',
        name: 'Organizing',
        icon: 'inventory_2_outlined',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'pet_care',
        name: 'Pet Care',
        icon: 'pets_outlined',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'self_care',
        name: 'Self Care',
        icon: 'spa_outlined',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'events_photography',
        name: 'Events & Photography',
        icon: 'camera_alt_outlined',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'others',
        name: 'Others',
        icon: 'more_horiz',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}