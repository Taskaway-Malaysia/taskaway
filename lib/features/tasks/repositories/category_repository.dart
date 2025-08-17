import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import 'dart:developer' as dev;

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    supabase: Supabase.instance.client,
  );
});

class CategoryRepository {
  final SupabaseClient supabase;

  CategoryRepository({required this.supabase});

  Future<List<Category>> getCategories() async {
    // Since taskaway_categories is an ENUM and not a table, we'll use the hardcoded values
    print('Using hardcoded categories since taskaway_categories is an ENUM');
    return _getDefaultCategories();
  }

  // Method to provide categories based on the Supabase ENUM
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
        id: 'handyman',
        name: 'Handyman',
        icon: 'handyman',
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
        id: 'painting',
        name: 'Painting',
        icon: 'painting',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'organizing',
        name: 'Organizing',
        icon: 'organizing',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'pet_care',
        name: 'Pet Care',
        icon: 'pet_care',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'self_care',
        name: 'Self Care',
        icon: 'self_care',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'events_photography',
        name: 'Events & Photography',
        icon: 'events_photography',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'others',
        name: 'Others',
        icon: 'others',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
