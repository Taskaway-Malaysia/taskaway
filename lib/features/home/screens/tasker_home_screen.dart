import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskaway/features/auth/models/profile.dart';
import 'package:taskaway/features/tasks/components/task_card.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/core/widgets/qwerty_overlay.dart';
import 'package:taskaway/features/tasks/models/task.dart';

// Provider for browse page region filter
final regionFilterProvider = StateProvider<String>((ref) => 'All Regions');

// Provider for available postcodes from tasks
final availablePostcodesProvider = Provider<List<String>>((ref) {
  final tasksAsync = ref.watch(availableTasksProvider);
  return tasksAsync.maybeWhen(
    data: (tasks) {
      final postcodes = tasks
          .map((task) => task.location)
          .where((location) => location.isNotEmpty)
          .toSet()
          .toList();
      postcodes.sort();
      return ['All Regions', ...postcodes];
    },
    orElse: () => ['All Regions'],
  );
});

// Provider for browse page category filter
final categoryFilterProvider = StateProvider<String>((ref) => 'All Categories');

// Provider for browse page sort filter
final sortFilterProvider = StateProvider<String>((ref) => 'Latest');

// Provider for the search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider to manage search UI state
final isSearchingProvider = StateProvider<bool>((ref) => false);

// Provider for available tasks in browse page
final availableTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskControllerProvider).watchAvailableTasks();
});

// Provider for filtered available tasks
final filteredAvailableTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(availableTasksProvider);
  final region = ref.watch(regionFilterProvider);
  final category = ref.watch(categoryFilterProvider);
  final sort = ref.watch(sortFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return tasksAsync.whenData((tasks) {
    var filteredTasks = tasks;

    // Apply search query filter
    if (searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        final titleMatch = task.title.toLowerCase().contains(searchQuery.toLowerCase());
        final descriptionMatch = task.description.toLowerCase().contains(searchQuery.toLowerCase());
        return titleMatch || descriptionMatch;
      }).toList();
    }

    // Apply region filter if not 'All Regions'
    if (region != 'All Regions') {
      filteredTasks = filteredTasks
          .where((task) => task.location.toLowerCase().contains(region.toLowerCase()))
          .toList();
    }

    // Apply category filter if not 'All Categories'
    if (category != 'All Categories') {
      filteredTasks = filteredTasks
          .where((task) =>
              task.category.toLowerCase() ==
              category.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_'))
          .toList();
    }

    // Apply sorting
    switch (sort) {
      case 'Latest':
        filteredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Price: High to Low':
        filteredTasks.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Price: Low to High':
        filteredTasks.sort((a, b) => a.price.compareTo(b.price));
        break;
    }

    return filteredTasks;
  });
});

class TaskerHomeScreen extends ConsumerStatefulWidget {
  final Profile? profile;
  const TaskerHomeScreen({super.key, this.profile});

  @override
  ConsumerState<TaskerHomeScreen> createState() => _TaskerHomeScreenState();
}

class _TaskerHomeScreenState extends ConsumerState<TaskerHomeScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRegion = ref.watch(regionFilterProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final selectedSort = ref.watch(sortFilterProvider);
    final availablePostcodes = ref.watch(availablePostcodesProvider);
    final isSearching = ref.watch(isSearchingProvider);

    return Stack(
      children: [
        Column(children: [
          // Header with filters
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF39C12),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isSearching)
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Search tasks...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.black54),
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      )
                    else
                      const Text(
                        'Browse Task',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(isSearching ? Icons.close : Icons.search, color: Colors.black, size: 28),
                          onPressed: () {
                            final newIsSearching = !isSearching;
                            ref.read(isSearchingProvider.notifier).state = newIsSearching;
                            if (newIsSearching) {
                              _searchFocusNode.requestFocus();
                            } else {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                            }
                          },
                        ),
                        if (!isSearching)
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.black, size: 28),
                            onPressed: () {},
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filters Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Consumer(builder: (context, ref, _) {
                    return Row(
                      children: [
                        // Region filter
                        _buildDropdownContainer(
                          child: DropdownButton<String>(
                            value: selectedRegion,
                            hint: const Text('Region'),
                            underline: Container(),
                            icon: const Icon(Icons.arrow_drop_down),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                ref.read(regionFilterProvider.notifier).state = newValue;
                              }
                            },
                            items: availablePostcodes.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Category filter
                        _buildDropdownContainer(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            hint: const Text('Category'),
                            underline: Container(),
                            icon: const Icon(Icons.arrow_drop_down),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                ref.read(categoryFilterProvider.notifier).state = newValue;
                              }
                            },
                            items: <String>[
                              'All Categories',
                              'Handyman',
                              'Cleaning',
                              'Gardening',
                              'Painting',
                              'Organizing',
                              'Pet Care',
                              'Self Care',
                              'Events & Photography',
                              'Others'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sort filter
                        _buildDropdownContainer(
                          child: DropdownButton<String>(
                            value: selectedSort,
                            hint: const Text('Sort by'),
                            underline: Container(),
                            icon: const Icon(Icons.arrow_drop_down),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                ref.read(sortFilterProvider.notifier).state = newValue;
                              }
                            },
                            items: <String>['Latest', 'Price: High to Low', 'Price: Low to High']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Title text
                const Text(
                  'Grab a Task. Earn Money.',
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Available tasks list
          Expanded(
            child: Consumer(builder: (context, ref, _) {
              final tasksAsync = ref.watch(filteredAvailableTasksProvider);

              return tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Center(
                      child: Text('No available tasks found'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TaskCard(
                          task: task,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              );
            }),
          ),
        ]),
        if (isSearching)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: QwertyOverlay(
              previewController: _searchController,
              onCharacterPressed: (char) {
                _searchController.text += char;
              },
              onBackspacePressed: () {
                if (_searchController.text.isNotEmpty) {
                  _searchController.text = _searchController.text.substring(0, _searchController.text.length - 1);
                }
              },
              onConfirmPressed: () {
                ref.read(isSearchingProvider.notifier).state = false;
                _searchFocusNode.unfocus();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
