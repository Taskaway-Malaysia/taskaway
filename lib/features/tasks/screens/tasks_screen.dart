import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:taskaway/core/constants/style_constants.dart'; // For theme colors
import 'package:taskaway/core/utils/states.dart'; // For location dropdown
import 'package:taskaway/features/auth/controllers/auth_controller.dart'; // For currentProfileProvider
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/features/tasks/models/task_status.dart';
import 'dart:developer' as dev;

// Provider for role selection (Poster or Tasker)
final taskRoleProvider = StateProvider.autoDispose<String>((ref) => 'poster');

// Provider for task status filter
final taskStatusProvider =
    StateProvider.autoDispose<String>((ref) => 'awaiting_offers');

// Provider for filtered tasks that combines search, category, role and status filters
final filteredTasksProvider =
    Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  final tasks = ref.watch(taskStreamProvider);
  final searchQuery = ref.watch(searchTextProvider);
  final selectedCategories = ref.watch(selectedCategoriesProvider);
  final role = ref.watch(taskRoleProvider);
  final status = ref.watch(taskStatusProvider);

  return tasks.whenData((tasks) {
    return tasks.where((task) {
      // Filter by role (poster or tasker)
      final matchesRole =
          (role == 'poster' && task.posterId == 'current_user_id') ||
              (role == 'tasker' && task.taskerId == 'current_user_id');

      // Filter by status
      final matchesStatus =
          status == 'all' || mapStatusToFilter(task.status) == status;

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

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Watch current profile to get the user role
    final profileAsync = ref.watch(currentProfileProvider);

    // Determine the header color based on user role
    Color headerColor;
    if (profileAsync.value?.role == 'poster') {
      headerColor = StyleConstants.posterColorPrimary; // Poster Purple
      dev.log('User is a poster, using poster theme colors');
    } else {
      // Default to tasker color for taskers and when profile is still loading
      headerColor = StyleConstants.taskerColorPrimary; // Tasker Orange
      dev.log(
          'User is a tasker or profile still loading, using tasker theme colors');
    }
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.only(
              top: kToolbarHeight, // Approx status bar height + appbar
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            decoration: BoxDecoration(
              color: headerColor, // Dynamically set based on user role
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Browse Tasks',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.black87, // Explicitly dark color
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.black),
                          onPressed: () {
                            // TODO: Implement search functionality
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_none,
                              color: Colors.black),
                          onPressed: () {
                            // TODO: Implement notification functionality
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16.0),
                // Filter Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: FilterDropdown(
                        hintText: 'Entire Malaysia',
                        items: ['Entire Malaysia', ...states],
                        onChanged: (value) {
                          dev.log('Location filter changed to: $value');
                        },
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: FilterDropdown(
                        hintText: 'Select category',
                        items: const [
                          'Select category',
                          'Home Services',
                          'Cleaning',
                          'Delivery',
                          'IT & Tech'
                        ],
                        onChanged: (value) {
                          dev.log('Category filter changed to: $value');
                        },
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: FilterDropdown(
                        hintText: 'Sort',
                        items: const [
                          'Sort',
                          'Price: Low to High',
                          'Price: High to Low',
                          'Date: Newest',
                          'Date: Oldest'
                        ],
                        onChanged: (value) {
                          dev.log('Sort option changed to: $value');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0), // Spacing before the text
                // "Grab a Task. Earn Money." Text - MOVED HERE (Inside Header, after filters)
                Container(
                  width: double
                      .infinity, // Ensure it takes full width for left alignment
                  // padding: const EdgeInsets.only(top: 12.0), // Padding already handled by SizedBox and Column's padding
                  child: Text(
                    'Grab a Task. Earn Money.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
          // Task List
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _mockTasks.length,
              itemBuilder: (context, index) {
                return TaskCard(task: _mockTasks[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FilterDropdown extends StatelessWidget {
  final String hintText;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const FilterDropdown({
    required this.hintText,
    required this.items,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
        ),
        hint: Text(hintText),
        isExpanded: true, // Ensure dropdown expands to fill available space
        icon: const Icon(Icons.arrow_drop_down, size: 20.0), // Smaller icon
        onChanged: onChanged, // Add back the onChanged callback
        itemHeight: 48,
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: const TextStyle(fontSize: 13)),
          );
        }).toList(),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({required this.task, super.key});

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
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white),
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
                        onTap: () => ref.read(taskRoleProvider.notifier).state =
                            'poster',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: role == 'poster'
                                ? const Color(0xFF6C5CE7)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'As Poster',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: role == 'poster'
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ref.read(taskRoleProvider.notifier).state =
                            'tasker',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: role == 'tasker'
                                ? const Color(0xFF6C5CE7)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'As Tasker',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: role == 'tasker'
                                  ? Colors.white
                                  : Colors.grey.shade700,
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
                    _buildStatusTab(
                        'awaiting_offers', 'Awaiting offers', status),
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
          color: isSelected
              ? const Color(0xFF6C5CE7)
              : const Color(0xFF6C5CE7).withOpacity(0.1),
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
