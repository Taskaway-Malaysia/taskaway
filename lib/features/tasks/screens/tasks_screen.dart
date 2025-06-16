import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:taskaway/core/constants/style_constants.dart'; // For theme colors
import 'package:taskaway/core/utils/states.dart'; // For location dropdown
import 'package:taskaway/features/auth/controllers/auth_controller.dart'; // For currentProfileProvider
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/features/tasks/models/task_status.dart';
import 'dart:developer' as dev;

// Mock data for now
final List<Task> _mockTasks = [
  Task(
    id: '1',
    title: 'I am currently in need of the services of a maid',
    description: 'Detailed description for maid services.',
    category: 'Home Services',
    price: 100.00,
    location: 'Petaling Jaya',
    scheduledTime: DateTime.now().add(const Duration(days: 2)),
    status: TaskStatus.open,
    posterId: 'user1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    // posterAvatarUrl: 'https://example.com/avatar1.png', // Example
    // offerCount: 2, // Example
  ),
  Task(
    id: '2',
    title: 'I am currently in need of the services of a maid',
    description: 'Another maid service request.',
    category: 'Home Services',
    price: 1000.00,
    location: 'Usj 4, Subang Jaya',
    scheduledTime: DateTime.now().add(const Duration(days: 3)),
    status: TaskStatus.open,
    posterId: 'user2',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    // posterAvatarUrl: 'https://example.com/avatar2.png', // Example
    // offerCount: 0, // Example
  ),
  Task(
    id: '3',
    title: 'I am currently in need of the services of a maid',
    description: 'A different task.',
    category: 'Cleaning',
    price: 30.00,
    location: 'Bukit Jelutong',
    scheduledTime: DateTime.now().add(const Duration(days: 1)), // "Any day" can be represented by a flexible date or specific logic later
    status: TaskStatus.open,
    posterId: 'user3',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    // offerCount: 1, // Example
  ),
];

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
      dev.log('User is a tasker or profile still loading, using tasker theme colors');
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
                        items: const ['Select category', 'Home Services', 'Cleaning', 'Delivery', 'IT & Tech'],
                        onChanged: (value) {
                          dev.log('Category filter changed to: $value');
                        },
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: FilterDropdown(
                        hintText: 'Sort',
                        items: const ['Sort', 'Price: Low to High', 'Price: High to Low', 'Date: Newest', 'Date: Oldest'],
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
                  width: double.infinity, // Ensure it takes full width for left alignment
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
          contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
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
    final theme = Theme.of(context);
    final taskerPrimaryColor = theme.secondaryHeaderColor; // Tasker Primary (StyleConstants.taskerColorPrimary)
    final posterPrimaryColor = theme.colorScheme.primary; // Poster Primary

    // Date formatting
    String formattedDate = 'Any day';
    try {
      // Example: "Before Thu, 18 Jan"
      // For "Any day", we might need a specific flag in the model or handle it differently
      if (task.scheduledTime.year != 1) { // A way to check if it's a specific date
         formattedDate = 'Before ${DateFormat('E, d MMM').format(task.scheduledTime)}';
      }
    } catch (e) {
      // log('Error formatting date: $e');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'RM ${task.price.toStringAsFixed(0)}', // Assuming price doesn't need .00
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Divider(height: 24.0, thickness: 1, color: Colors.grey), // height includes space above (11.5) and below (11.5) + thickness (1)
            Row(
              children: [
                // Status and Offer Count Column
                Container(
                  width: 70, // Fixed width for the status column
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Center text horizontally
                    mainAxisAlignment: MainAxisAlignment.center, // Center vertically if row allows
                    children: [
                      Text(
                        task.status.name.toUpperCase(), // e.g., "OPEN"
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: posterPrimaryColor, // Poster color for "Open"
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Horizontal divider within status column
                      Container(
                        height: 1,
                        width: 20, // Adjust width as needed for the short line
                        color: Colors.grey.shade400,
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                      ),
                      Text(
                        '2 Offer(s)', // Mocked for now
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                // Vertical Divider between status column and avatar
                Container(
                  height: 60, // Adjust height to match content
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: VerticalDivider(
                    width: 1.0,
                    thickness: 1,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(width: 8.0),
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(Icons.person, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 12.0),
                // Date and Location Column - Wrapped with Expanded
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // Align items vertically in the center
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade700),
                          const SizedBox(width: 4.0),
                          Flexible( // Allow text to wrap or truncate if needed
                            child: Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade700),
                          const SizedBox(width: 4.0),
                          Flexible( // Allow text to wrap or truncate
                            child: Text(
                              task.location,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // View Button
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to task details screen
                    // context.go('/home/browse/${task.id}');
                  },
                  child: Text(
                    'View',
                    style: TextStyle(
                        color: taskerPrimaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}