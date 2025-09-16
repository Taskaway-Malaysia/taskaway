import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/features/auth/models/profile.dart';
import 'package:taskaway/features/tasks/components/task_card.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/core/widgets/qwerty_overlay.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/features/home/widgets/map_widget.dart';
import 'package:taskaway/features/home/widgets/tasker_poster_toggle.dart';
import 'package:taskaway/features/home/widgets/search_overlay.dart';
import 'package:taskaway/features/home/widgets/view_list_toggle.dart';

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
    final viewMode = ref.watch(viewModeProvider);
    final userMode = ref.watch(userModeProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Main content (map or list)
          _buildMainContent(context, ref, viewMode),

          // Top Section - exact Figma implementation
          _buildTopSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, ViewMode viewMode) {
    final tasksAsync = ref.watch(filteredAvailableTasksProvider);

    return tasksAsync.when(
      data: (tasks) {
        if (viewMode == ViewMode.map) {
          // Map view
          return MapWidget(
            tasks: tasks,
            onTaskTap: (task) {
              context.push('/task/${task.id}');
            },
          );
        } else {
          // List view
          return Column(
            children: [
              const SizedBox(height: 200), // Space for header
              Expanded(
                child: tasks.isEmpty
                    ? const Center(
                        child: Text('No available tasks found'),
                      )
                    : ListView.builder(
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
                      ),
              ),
            ],
          );
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    print('_showFilterBottomSheet called');
    try {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          print('Building filter bottom sheet');
          return StatefulBuilder(
            builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // Show result count
                  Consumer(
                    builder: (context, ref, child) {
                      final tasksAsync = ref.watch(filteredAvailableTasksProvider);
                      return tasksAsync.maybeWhen(
                        data: (tasks) => Text(
                          '${tasks.length} results',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF788494),
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Add filter options here
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownContainer(
                      child: DropdownButton<String>(
                        value: ref.watch(regionFilterProvider),
                        hint: const Text('Region'),
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            ref.read(regionFilterProvider.notifier).state = newValue;
                            setState(() {}); // Refresh to update result count
                          }
                        },
                        items: ref.watch(availablePostcodesProvider).map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdownContainer(
                      child: DropdownButton<String>(
                        value: ref.watch(categoryFilterProvider),
                        hint: const Text('Category'),
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            ref.read(categoryFilterProvider.notifier).state = newValue;
                            setState(() {}); // Refresh to update result count
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdownContainer(
                child: DropdownButton<String>(
                  value: ref.watch(sortFilterProvider),
                  hint: const Text('Sort by'),
                  underline: Container(),
                  icon: const Icon(Icons.arrow_drop_down),
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      ref.read(sortFilterProvider.notifier).state = newValue;
                      setState(() {}); // Refresh to update result count
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
              const SizedBox(height: 24),
              // Clear All Filters button
              if (_getActiveFilterCount(ref) > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(regionFilterProvider.notifier).state = 'All Regions';
                      ref.read(categoryFilterProvider.notifier).state = 'All Categories';
                      ref.read(sortFilterProvider.notifier).state = 'Latest';
                      setState(() {}); // Refresh to update UI
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      side: const BorderSide(color: Color(0xFFE4E4E4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Clear All Filters',
                      style: TextStyle(
                        color: Color(0xFF788494),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Apply Filters button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(0xFFFFDB5B),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(
                      color: Color(0xFFFFC333),
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
            ),
          );
        },
      );
    } catch (e) {
      print('Error showing filter bottom sheet: $e');
    }
  }


  Widget _buildActiveFilters(BuildContext context, WidgetRef ref) {
    final region = ref.watch(regionFilterProvider);
    final category = ref.watch(categoryFilterProvider);
    final sort = ref.watch(sortFilterProvider);

    List<Widget> chips = [];

    if (region != 'All Regions') {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text(region, style: const TextStyle(fontSize: 12)),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              ref.read(regionFilterProvider.notifier).state = 'All Regions';
            },
            backgroundColor: const Color(0xFFFFF5E0),
            side: const BorderSide(color: Color(0xFFFFC333)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    if (category != 'All Categories') {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text(category, style: const TextStyle(fontSize: 12)),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              ref.read(categoryFilterProvider.notifier).state = 'All Categories';
            },
            backgroundColor: const Color(0xFFFFF5E0),
            side: const BorderSide(color: Color(0xFFFFC333)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    if (sort != 'Latest') {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text(sort, style: const TextStyle(fontSize: 12)),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              ref.read(sortFilterProvider.notifier).state = 'Latest';
            },
            backgroundColor: const Color(0xFFFFF5E0),
            side: const BorderSide(color: Color(0xFFFFC333)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    if (chips.isNotEmpty) {
      chips.add(
        TextButton(
          onPressed: () {
            ref.read(regionFilterProvider.notifier).state = 'All Regions';
            ref.read(categoryFilterProvider.notifier).state = 'All Categories';
            ref.read(sortFilterProvider.notifier).state = 'Latest';
          },
          child: const Text(
            'Clear all',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF788494),
            ),
          ),
        ),
      );
    }

    return chips.isEmpty
        ? const SizedBox.shrink()
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 25.5, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: chips),
            ),
          );
  }

  Widget _buildTopSection(BuildContext context, WidgetRef ref) {
    final userMode = ref.watch(userModeProvider);
    final hasActiveFilters = _getActiveFilterCount(ref) > 0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Container(
            width: 394,
            height: 151,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Yellow accent line at bottom
                Positioned(
                  left: 0,
                  top: 149,
                  child: Container(
                    width: 197,
                    height: 2,
                    color: const Color(0xFFFFC333),
                  ),
                ),

                // Search area at position (25.5, 62)
                Positioned(
                  left: 25.5,
                  top: 62,
                  child: Row(
                    children: [
                      // Search bar (292px width, exact Figma sizing)
                      Container(
                        width: 292,
                        height: 44, // Match filter button height
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            // Search icon (24x24 frame with 11x11 icon)
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.search,
                                size: 11,
                                color: Color(0xFF202020),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Search text
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                decoration: const InputDecoration(
                                  hintText: 'Search for any service',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  hintStyle: TextStyle(
                                    fontFamily: 'Instrument Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF202020),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF202020),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8), // 8px gap

                      // Filter button - Simplified implementation
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            print('Filter button tapped!');
                            print('Current context: $context');
                            _showFilterBottomSheet(context, ref);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(
                                    Icons.tune,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                ),
                                // Filter count badge
                                if (_getActiveFilterCount(ref) > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFC333),
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '${_getActiveFilterCount(ref)}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // TASKER toggle at position (78, 123)
                Positioned(
                  left: 78,
                  top: 123,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(userModeProvider.notifier).state = UserMode.tasker;
                    },
                    child: Text(
                      'TASKER',
                      style: TextStyle(
                        fontFamily: 'Instrument Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        color: userMode == UserMode.tasker
                            ? const Color(0xFF000000)
                            : const Color(0xFF788494),
                      ),
                    ),
                  ),
                ),

                // POSTER toggle at position (251, 123)
                Positioned(
                  left: 251,
                  top: 123,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(userModeProvider.notifier).state = UserMode.poster;
                    },
                    child: Text(
                      'POSTER',
                      style: TextStyle(
                        fontFamily: 'Instrument Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        color: userMode == UserMode.poster
                            ? const Color(0xFF000000)
                            : const Color(0xFF788494),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Active filters chips
          if (hasActiveFilters)
            _buildActiveFilters(context, ref),
        ],
      ),
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

  int _getActiveFilterCount(WidgetRef ref) {
    int count = 0;
    if (ref.watch(regionFilterProvider) != 'All Regions') count++;
    if (ref.watch(categoryFilterProvider) != 'All Categories') count++;
    if (ref.watch(sortFilterProvider) != 'Latest') count++;
    return count;
  }
}