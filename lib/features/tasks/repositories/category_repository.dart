import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../../../core/constants/db_constants.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    supabase: Supabase.instance.client,
  );
});

class CategoryRepository {
  final SupabaseClient supabase;
  final String _tableName = DbConstants.categoriesTable;

  CategoryRepository({required this.supabase});

  Future<List<Category>> getCategories() async {
    try {
      final response = await supabase
          .from(_tableName)
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
        id: 'cleaning',
        name: 'Cleaning',
        icon: 'cleaning',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'painting',
        name: 'Painting',
        icon: 'painting',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'gardening',
        name: 'Gardening',
        icon: 'gardening',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'delivery',
        name: 'Delivery',
        icon: 'delivery',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'handyman',
        name: 'Handyman',
        icon: 'handyman',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
