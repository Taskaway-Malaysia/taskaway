import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_providers.dart';

class TaskSearchBar extends ConsumerWidget {
  final TextEditingController controller;
  final VoidCallback onFilterTap;

  const TaskSearchBar({
    super.key,
    required this.controller,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      floating: true,
      automaticallyImplyLeading: false,
      title: SearchBar(
        controller: controller,
        hintText: 'Search tasks...',
        leading: const Icon(Icons.search),
        onChanged: (value) {
          ref.read(searchTextProvider.notifier).state = value;
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: onFilterTap,
        ),
      ],
    );
  }
} 