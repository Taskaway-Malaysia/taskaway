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
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/profile/controllers/profile_controller.dart';
import 'package:taskaway/core/services/location_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import 'dart:developer' as dev;

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
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });

    // Start location tracking if user is already available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(currentProfileProvider).value;
      final user = ref.read(currentUserProvider);
      if (profile?.isAvailable == true && user != null) {
        dev.log('[TaskerHome] User is available, starting location tracking');
        _locationService.startTracking(user.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _locationService.stopTracking();
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
              const SizedBox(height: 140), // Space for header
              Expanded(
                child: tasks.isEmpty
                    ? const Center(
                        child: Text('No available tasks found'),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(AppSpacing.lg),
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
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
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
              SizedBox(height: AppSpacing.lg),
              // Add filter options here
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownContainer(
                      child: DropdownButton<String>(
                        value: ref.watch(regionFilterProvider),
                        hint: Text('Region'),
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
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildDropdownContainer(
                      child: DropdownButton<String>(
                        value: ref.watch(categoryFilterProvider),
                        hint: Text('Category'),
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
              SizedBox(height: AppSpacing.lg),
              _buildDropdownContainer(
                child: DropdownButton<String>(
                  value: ref.watch(sortFilterProvider),
                  hint: Text('Sort by'),
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
              SizedBox(height: AppSpacing.xxl),
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
                        borderRadius: AppRadius.smMd,
                      ),
                    ),
                    child: Text(
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
                    borderRadius: AppRadius.smMd,
                    side: const BorderSide(
                      color: Color(0xFFFFC333),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: AppTypography.labelMedium,
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
          child: Text(
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
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderDefault,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // User profile row with availability badge
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE8E9F1),
                          ),
                          child: profileAsync.when(
                            data: (profile) {
                              final name = profile?.fullName ?? 'User';
                              final avatarUrl = profile?.avatarUrl;

                              if (avatarUrl != null) {
                                return ClipOval(
                                  child: Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    width: 64,
                                    height: 64,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF788494),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }

                              return Center(
                                child: Text(
                                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF788494),
                                  ),
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const Icon(Icons.person, color: Color(0xFF788494), size: 32),
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        // Name with greeting
                        Expanded(
                          child: profileAsync.when(
                            data: (profile) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile?.fullName ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const Text('User'),
                          ),
                        ),
                        // Availability badge
                        profileAsync.when(
                          data: (profile) {
                            final isAvailable = profile?.isAvailable ?? false;
                            return GestureDetector(
                              onTap: () async {
                                if (currentUser == null) return;

                                final newValue = !isAvailable;

                                if (newValue) {
                                  // Turning availability ON
                                  dev.log('[TaskerHome] Enabling availability, requesting location permission');

                                  final hasPermission = await _locationService.requestPermissions();
                                  if (!hasPermission) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Location permission is required to enable availability'),
                                          backgroundColor: Color(0xFFFF9800),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  dev.log('[TaskerHome] Location permission granted, starting tracking');
                                  _locationService.startTracking(currentUser.id);
                                } else {
                                  // Turning availability OFF
                                  dev.log('[TaskerHome] Disabling availability, stopping location tracking');
                                  _locationService.stopTracking();
                                }

                                // Update availability in database
                                try {
                                  await ref
                                      .read(profileControllerProvider)
                                      .updateAvailability(
                                        userId: currentUser.id,
                                        isAvailable: newValue,
                                      );

                                  // Invalidate the profile provider to refresh the UI
                                  ref.invalidate(currentProfileProvider);
                                } catch (e) {
                                  dev.log('[TaskerHome] Error updating availability: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update availability: $e'),
                                        backgroundColor: const Color(0xFFFF9800),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isAvailable
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFFFB74D),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isAvailable ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isAvailable
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFE65100),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isAvailable
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFFFFB74D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  // Search and filter row
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        // Search bar
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
                              borderRadius: AppRadius.smMd,
                            ),
                            child: Row(
                              children: [
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
                                SizedBox(width: AppSpacing.sm),
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF202020),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF202020),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        // Filter button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              print('Filter button tapped!');
                              print('Current context: $context');
                              _showFilterBottomSheet(context, ref);
                            },
                            borderRadius: AppRadius.smMd,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
                                borderRadius: AppRadius.smMd,
                              ),
                              child: Stack(
                                children: [
                                  const Center(
                                    child: Icon(
                                      Icons.tune,
                                      size: 20,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
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
                                            color: AppColors.textPrimary,
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
                ],
              ),
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
        color: AppColors.white,
        borderRadius: AppRadius.xxl,
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