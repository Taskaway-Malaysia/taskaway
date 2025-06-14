import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/task_controller.dart' show taskStreamProvider;
import '../models/task.dart';
import '../components/components.dart';
import '../providers/task_providers.dart';

// Provider for search text state
final searchTextProvider = StateProvider.autoDispose<String>((ref) => '');

// Provider for role selection (Poster or Tasker)
final taskRoleProvider = StateProvider.autoDispose<String>((ref) => 'poster');

// Provider for task status filter
final taskStatusProvider = StateProvider.autoDispose<String>((ref) => 'awaiting_offers');

// Provider for filtered tasks that combines search, category, role and status filters
final filteredTasksProvider = Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  final tasks = ref.watch(taskStreamProvider);
  final searchQuery = ref.watch(searchTextProvider);
  final selectedCategories = ref.watch(selectedCategoriesProvider);
  final role = ref.watch(taskRoleProvider);
  final status = ref.watch(taskStatusProvider);
  
  return tasks.whenData((tasks) {
    return tasks.where((task) {
      // Filter by role (poster or tasker)
      final matchesRole = (role == 'poster' && task.posterId == 'current_user_id') || 
                         (role == 'tasker' && task.taskerId == 'current_user_id');
      
      // Filter by status
      final matchesStatus = status == 'all' || mapStatusToFilter(task.status) == status;
      
      // Filter by search query
      final matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(searchQuery.toLowerCase());
          
      // Filter by categories
      final matchesCategories = selectedCategories.isEmpty ||
          selectedCategories.contains(task.category);
          
      return matchesRole && matchesStatus && matchesSearch && matchesCategories;
    }).toList();
  });
});

// Helper function to map task status to filter value
String mapStatusToFilter(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return 'awaiting_offers';
    case 'assigned':
    case 'in_progress':
      return 'upcoming_tasks';
    case 'completed':
    case 'cancelled':
      return 'completed';
    default:
      return 'awaiting_offers';
  }
}

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
    final role = ref.watch(taskRoleProvider);
    final status = ref.watch(taskStatusProvider);
    
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
          child: Column(
            children: [
              // Purple header with title and notification
              Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF6C5CE7), // Purple color from the image
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    const Text(
                      'My Tasks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () {
                        // Handle notification tap
                      },
                    ),
                  ],
                ),
              ),
              
              // Role selector tabs
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ref.read(taskRoleProvider.notifier).state = 'poster',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: role == 'poster' ? const Color(0xFF6C5CE7) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'As Poster',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: role == 'poster' ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ref.read(taskRoleProvider.notifier).state = 'tasker',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: role == 'tasker' ? const Color(0xFF6C5CE7) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'As Tasker',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: role == 'tasker' ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status selector tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatusTab('awaiting_offers', 'Awaiting offers', status),
                    const SizedBox(width: 8),
                    _buildStatusTab('upcoming_tasks', 'Upcoming tasks', status),
                    const SizedBox(width: 8),
                    _buildStatusTab('completed', 'Completed', status),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Task list
              Expanded(
                child: TaskListView(),
              ),
            ],
          ),
        ),
        floatingActionButton: const CreateTaskButton(),
        // Removed the bottomNavigationBar to avoid duplication
      ),
    );
  }
  
  Widget _buildStatusTab(String value, String label, String currentStatus) {
    final isSelected = currentStatus == value;
    
    return GestureDetector(
      onTap: () => ref.read(taskStatusProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFF6C5CE7).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6C5CE7),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}