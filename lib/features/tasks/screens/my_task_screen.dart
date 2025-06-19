import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/tasks/models/task.dart';

final roleProvider = StateProvider<String>((ref) => 'poster');
final statusProvider = StateProvider<String>((ref) => 'awaiting_offers');
final selectedTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasks = ref.watch(taskStreamProvider);
  final role = ref.watch(roleProvider);
  final status = ref.watch(statusProvider);

  return tasks.whenData((tasks) => tasks.where((task) {
        final isCorrectRole = role == 'poster'
            ? task.posterId == 'current_user_id'
            : task.taskerId == 'current_user_id';
        final isCorrectStatus = task.status == status;
        return isCorrectRole && isCorrectStatus;
      }).toList());
});

// Status tabs list
final statusTabs = ['awaiting_offers', 'upcoming_tasks', 'completed'];
final statusLabels = {
  'awaiting_offers': 'Awaiting offers',
  'upcoming_tasks': 'Upcoming tasks',
  'completed': 'Completed',
};

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

class MyTaskScreen extends ConsumerWidget {
  const MyTaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final status = ref.watch(statusProvider);
    return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          child: Column(
            children: [
              // Header Section - Centered title with notification icon
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered title
                    const Text(
                      'My Tasks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Right-aligned notification icon
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),

              // Role Toggle - Poster/Tasker
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8F0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    // As Poster Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(roleProvider.notifier).state = 'poster',
                        child: Container(
                          decoration: BoxDecoration(
                            color: role == 'poster'
                                ? const Color(0xFF7267CB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'As Poster',
                            style: TextStyle(
                              color: role == 'poster'
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // As Tasker Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(roleProvider.notifier).state = 'tasker',
                        child: Container(
                          decoration: BoxDecoration(
                            color: role == 'tasker'
                                ? const Color(0xFF7267CB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'As Tasker',
                            style: TextStyle(
                              color: role == 'tasker'
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Tabs - Awaiting/Upcoming/Completed
              Container(
                margin: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 16.0),
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8F0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: statusTabs
                      .map((tab) => Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  ref.read(statusProvider.notifier).state = tab,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: status == tab
                                      ? const Color(0xFF7267CB)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(0),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  statusLabels[tab] ?? tab,
                                  style: TextStyle(
                                    color: status == tab
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              // Task List
              Expanded(
                child: ref.watch(selectedTasksProvider).when<Widget>(
                      data: (tasks) => tasks.isEmpty
                          ? const Center(child: Text('No tasks found'))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.05),
                                        spreadRadius: 0,
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Top section with title and price
                                      Container(
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                                color: Color(0xFFEEEEEE),
                                                width: 1),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                task.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'RM ${task.budget.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Bottom section with status, date, location and view button
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Left side - Status/Offers
                                          Container(
                                            width: 100,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16.0,
                                                horizontal: 12.0),
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                right: BorderSide(
                                                    color: Color(0xFFEEEEEE),
                                                    width: 1),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Open',
                                                  style: TextStyle(
                                                    color:
                                                        const Color(0xFF7267CB),
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  task.offers != null &&
                                                          task.offers!
                                                              .isNotEmpty
                                                      ? '${task.offers!.length} ${task.offers!.length == 1 ? 'Offer' : 'Offers'}'
                                                      : '—',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Right side - Date, location, view button
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12.0,
                                                      horizontal: 12.0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  // Date and location column
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Date row
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .calendar_today_outlined,
                                                            size: 14,
                                                            color: Colors.grey,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            'On ${DateFormat('EEE, d MMM').format(task.scheduledTime)}',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[700],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      // Location row
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .location_on_outlined,
                                                            size: 14,
                                                            color: Colors.grey,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            task.location,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[700],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),

                                                  // View button
                                                  TextButton(
                                                    onPressed: () {},
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          const Color(
                                                              0xFF7267CB),
                                                      padding: EdgeInsets.zero,
                                                      minimumSize:
                                                          const Size(40, 30),
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    child: const Text(
                                                      'View',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text('Error: $error')),
                    ),
              ),
            ],
          ),
        ));
  }
}
