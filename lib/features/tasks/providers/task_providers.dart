import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../controllers/task_controller.dart' show taskStreamProvider;

// Provider for search text state
final searchTextProvider = StateProvider.autoDispose<String>((ref) => '');

// Provider for selected categories
final selectedCategoriesProvider = StateProvider.autoDispose<List<String>>((ref) => []);

// Provider for filtered tasks that combines search and category filters
final filteredTasksProvider = Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  final tasks = ref.watch(taskStreamProvider);
  final searchQuery = ref.watch(searchTextProvider);
  final selectedCategories = ref.watch(selectedCategoriesProvider);
  
  return tasks.whenData((tasks) {
    return tasks.where((task) {
      final matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(searchQuery.toLowerCase());
          
      final matchesCategories = selectedCategories.isEmpty ||
          selectedCategories.contains(task.category);
          
      return matchesSearch && matchesCategories;
    }).toList();
  });
}); 