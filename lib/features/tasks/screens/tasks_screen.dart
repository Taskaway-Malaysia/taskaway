import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/task_controller.dart' show taskStreamProvider;
import '../models/task.dart';
import '../components/components.dart';
import '../providers/task_providers.dart';

// Provider for search text state
final searchTextProvider = StateProvider.autoDispose<String>((ref) => '');

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

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    if (!mounted) return;
    ref.invalidate(taskStreamProvider);
    ref.invalidate(searchTextProvider);
    ref.invalidate(selectedCategoriesProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        _initializeData();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    ref.invalidate(taskStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus && mounted) {
          _initializeData();
        }
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              TaskSearchBar(
                controller: _searchController,
                onFilterTap: () => showDialog(
                  context: context,
                  builder: (context) => const FilterDialog(),
                ),
              ),
              TaskListView(),
            ],
          ),
        ),
        floatingActionButton: CreateTaskButton(),
      ),
    );
  }
}