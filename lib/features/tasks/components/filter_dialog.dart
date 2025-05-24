import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_providers.dart';
import '../../../core/utils/string_extensions.dart';

class FilterDialog extends ConsumerWidget {
  const FilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategories = ref.watch(selectedCategoriesProvider);
    final categories = [
      'cleaning',
      'delivery',
      'handyman',
      'moving',
      'other',
    ];

    return AlertDialog(
      title: const Text('Filter Tasks'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: categories.map((category) => CheckboxListTile(
          title: Text(category.capitalize()),
          value: selectedCategories.contains(category),
          onChanged: (value) => _toggleCategory(ref, category),
        )).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(selectedCategoriesProvider.notifier).state = [];
            Navigator.pop(context);
          },
          child: const Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  void _toggleCategory(WidgetRef ref, String category) {
    final categories = List<String>.from(ref.read(selectedCategoriesProvider));
    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }
    ref.read(selectedCategoriesProvider.notifier).state = categories;
  }
} 