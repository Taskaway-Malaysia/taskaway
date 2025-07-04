import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskaway/features/tasks/components/task_card.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';

// Provider to get all open tasks (available for taskers to browse)
final browseTasksProvider = Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(taskStreamProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return const AsyncValue.loading();
  }

  return tasksAsync.whenData((tasks) {
    // Filter to show only open tasks that are NOT posted by the current user
    return tasks.where((task) {
      return task.status == 'open' && task.posterId != currentUser.id;
    }).toList();
  });
});

// State providers for filters
final selectedRegionProvider = StateProvider<String?>((ref) => null);
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final selectedSortProvider = StateProvider<String?>((ref) => null);
final searchExpandedProvider = StateProvider<bool>((ref) => false);

class BrowseTasksScreen extends ConsumerStatefulWidget {
  const BrowseTasksScreen({super.key});

  @override
  ConsumerState<BrowseTasksScreen> createState() => _BrowseTasksScreenState();
}

class _BrowseTasksScreenState extends ConsumerState<BrowseTasksScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _regions = [
    'Kuala Lumpur',
    'Selangor',
    'Penang',
    'Johor',
    'Perak',
    'Sabah',
    'Sarawak',
    'Kedah',
    'Kelantan',
    'Terengganu',
    'Pahang',
    'Negeri Sembilan',
    'Malacca',
    'Perlis',
    'Labuan',
    'Putrajaya'
  ];

  final List<String> _categories = [
    'Handyman',
    'Cleaning',
    'Gardening',
    'Painting',
    'Organizing',
    'Pet Care',
    'Self Care',
    'Events & Photography',
    'Others'
  ];

  final List<String> _sortOptions = [
    'Latest',
    'Price: Low to High',
    'Price: High to Low',
    'Nearest'
  ];

  @override
  Widget build(BuildContext context) {
    final isSearchExpanded = ref.watch(searchExpandedProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with search and filters
          _buildHeader(isSearchExpanded),
          
          // Task list
          Expanded(
            child: ref.watch(browseTasksProvider).when(
              data: (tasks) {
                // Filter tasks based on search query and filters
                final filteredTasks = _filterTasks(tasks);

                if (filteredTasks.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No tasks found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search criteria',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TaskCard(
                        task: filteredTasks[index],
                        accentColor: const Color(0xFFFF9500), // Orange color
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading tasks: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.refresh(browseTasksProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSearchExpanded) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9500), // Orange color
            Color(0xFFFF7A00), // Darker orange
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and notification with search
          Row(
            children: [
              if (!isSearchExpanded)
                const Text(
                  'Browse Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const Spacer(),
              // Search icon/field
              if (!isSearchExpanded)
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 28),
                  onPressed: () {
                    ref.read(searchExpandedProvider.notifier).state = true;
                  },
                )
              else
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search tasks...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            autofocus: true,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            ref.read(searchExpandedProvider.notifier).state = false;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              // Notification bell
              if (!isSearchExpanded)
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    // Handle notification tap
                  },
                ),
            ],
          ),
          if (!isSearchExpanded) ...[
            const SizedBox(height: 8),
            const Text(
              'Grab a Task. Earn Money.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Filter dropdowns - moved inside header
          Row(
            children: [
              // Region filter
              Expanded(
                child: _buildDropdownFilter(
                  'Region',
                  ref.watch(selectedRegionProvider),
                  _regions,
                  (value) => ref.read(selectedRegionProvider.notifier).state = value,
                ),
              ),
              const SizedBox(width: 12),
              // Categories filter
              Expanded(
                child: _buildDropdownFilter(
                  'Categories',
                  ref.watch(selectedCategoryProvider),
                  _categories,
                  (value) => ref.read(selectedCategoryProvider.notifier).state = value,
                ),
              ),
              const SizedBox(width: 12),
              // Sort by filter
              Expanded(
                child: _buildDropdownFilter(
                  'Sort by',
                  ref.watch(selectedSortProvider),
                  _sortOptions,
                  (value) => ref.read(selectedSortProvider.notifier).state = value,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildDropdownFilter(
    String label,
    String? selectedValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedValue,
        hint: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(label),
          ),
          ...options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }),
        ],
        onChanged: onChanged,
      ),
    );
  }

  List<Task> _filterTasks(List<Task> tasks) {
    var filteredTasks = tasks;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               task.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               task.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply region filter
    final selectedRegion = ref.watch(selectedRegionProvider);
    if (selectedRegion != null) {
      filteredTasks = filteredTasks.where((task) {
        return task.location.toLowerCase().contains(selectedRegion.toLowerCase());
      }).toList();
    }

    // Apply category filter
    final selectedCategory = ref.watch(selectedCategoryProvider);
    if (selectedCategory != null) {
      filteredTasks = filteredTasks.where((task) {
        return task.category.toLowerCase().contains(selectedCategory.toLowerCase());
      }).toList();
    }

    // Apply sort filter
    final selectedSort = ref.watch(selectedSortProvider);
    if (selectedSort != null) {
      switch (selectedSort) {
        case 'Latest':
          filteredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'Price: Low to High':
          filteredTasks.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'Price: High to Low':
          filteredTasks.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'Nearest':
          // For now, just sort by location name
          filteredTasks.sort((a, b) => a.location.compareTo(b.location));
          break;
      }
    }

    return filteredTasks;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 