import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/task_controller.dart';
import '../models/task.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isClient = user?.userMetadata?['role'] == 'client';
    final tasks = ref.watch(filteredTasksProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Search and Filter Bar
          SliverAppBar(
            floating: true,
            automaticallyImplyLeading: false,
            title: SearchBar(
              controller: _searchController,
              hintText: 'Search tasks...',
              leading: const Icon(Icons.search),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  _showFilterDialog(context);
                },
              ),
            ],
          ),

          // Tasks List
          tasks.when(
            data: (taskList) => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: taskList.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Text('No tasks found'),
                      ),
                    )
                  : SliverList.separated(
                      itemCount: taskList.length,
                      itemBuilder: (context, index) {
                        final task = taskList[index];
                        return TaskCard(task: task);
                      },
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                    ),
            ),
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isClient
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/home/tasks/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('Post Task'),
            )
          : null,
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const FilterDialog(),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y h:mm a');

    return Card(
      child: InkWell(
        onTap: () {
          context.push('/home/tasks/${task.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status, theme),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.status.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.category,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.location,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(task.scheduledTime),
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    'RM ${task.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'open':
        return theme.colorScheme.primary;
      case 'in_progress':
        return theme.colorScheme.tertiary;
      case 'completed':
        return theme.colorScheme.secondary;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }
}

class FilterDialog extends ConsumerWidget {
  const FilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategories = ref.watch(selectedCategoriesProvider);

    return AlertDialog(
      title: const Text('Filter Tasks'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text('Cleaning'),
            value: selectedCategories.contains('cleaning'),
            onChanged: (value) {
              _toggleCategory(ref, 'cleaning');
            },
          ),
          CheckboxListTile(
            title: const Text('Delivery'),
            value: selectedCategories.contains('delivery'),
            onChanged: (value) {
              _toggleCategory(ref, 'delivery');
            },
          ),
          CheckboxListTile(
            title: const Text('Handyman'),
            value: selectedCategories.contains('handyman'),
            onChanged: (value) {
              _toggleCategory(ref, 'handyman');
            },
          ),
          CheckboxListTile(
            title: const Text('Moving'),
            value: selectedCategories.contains('moving'),
            onChanged: (value) {
              _toggleCategory(ref, 'moving');
            },
          ),
          CheckboxListTile(
            title: const Text('Other'),
            value: selectedCategories.contains('other'),
            onChanged: (value) {
              _toggleCategory(ref, 'other');
            },
          ),
        ],
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
          onPressed: () {
            Navigator.pop(context);
          },
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