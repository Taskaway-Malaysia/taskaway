import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

final categoryControllerProvider = Provider((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryController(repository);
});

// Provider to expose categories
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryControllerProvider).getCategories();
});

class CategoryController {
  final CategoryRepository _repository;

  CategoryController(this._repository);

  Future<List<Category>> getCategories() async {
    return await _repository.getCategories();
  }
}
