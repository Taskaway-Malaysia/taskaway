import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/theme/app_colors.dart';
import 'package:taskaway/core/theme/app_typography.dart';
import '../../tasks/models/task.dart';
import '../../tasks/controllers/task_controller.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/service_card.dart';
import 'tasker_home_screen.dart'; // Import to use filter providers
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import 'dart:developer' as dev;
import 'dart:async';
import '../../tasks/repositories/task_repository.dart';

// Status provider for filtering posted tasks
final statusProvider = StateProvider<String>((ref) => 'Upcoming tasks');

// Independent status provider for MapHomeScreen (separate from MyTaskScreen)
// Defaults to 'Upcoming tasks' to show only active tasks, not completed ones
final mapHomeStatusProvider = StateProvider<String>((ref) => 'Upcoming tasks');

// Provider to get ALL tasks posted by the current user
final myPostedTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  dev.log('[MyPostedTasks] Provider called');
  dev.log('[MyPostedTasks] Current user: ${currentUser?.id}');

  if (currentUser == null) {
    dev.log('[MyPostedTasks] No current user, returning empty stream');
    return Stream.value([]);
  }

  // Watch ALL tasks posted by this user with real-time updates
  final taskRepo = ref.read(taskRepositoryProvider);
  return taskRepo.watchMyPostedTasks(currentUser.id).map((myTasks) {
    dev.log('[MyPostedTasks] Real-time update: Found ${myTasks.length} tasks posted by user');
    for (var task in myTasks) {
      dev.log('[MyPostedTasks] - Task: ${task.title}, Status: ${task.status}');
    }
    return myTasks;
  });
});

// Provider to get ALL tasks assigned to the current user (where user is the tasker)
final myAssignedTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  dev.log('[MyAssignedTasks] Provider called');
  dev.log('[MyAssignedTasks] Current user: ${currentUser?.id}');

  if (currentUser == null) {
    dev.log('[MyAssignedTasks] No current user, returning empty stream');
    return Stream.value([]);
  }

  // Watch ALL tasks assigned to this user with real-time updates
  final taskRepo = ref.read(taskRepositoryProvider);
  return taskRepo.watchMyAssignedTasks(currentUser.id).map((myTasks) {
    dev.log('[MyAssignedTasks] Real-time update: Found ${myTasks.length} tasks assigned to user');
    for (var task in myTasks) {
      dev.log('[MyAssignedTasks] - Task: ${task.title}, Status: ${task.status}');
    }
    return myTasks;
  });
});

// Provider for Ongoing Job tab - shows ALL tasks assigned to current user
final myTasksProvider = Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  return ref.watch(myAssignedTasksProvider).when(
    data: (tasks) {
      dev.log('[MapHomeScreen] Ongoing Job view - Total assigned tasks: ${tasks.length}');
      return AsyncValue.data(tasks);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// Status mapping function (same as MyTaskScreen)
String _mapTaskStatusToUiStatus(String dbStatus) {
  switch (dbStatus.toLowerCase()) {
    case 'open':
      return 'Awaiting offers';
    case 'accepted':
    case 'in_progress':
    case 'pending_approval':
      return 'Upcoming tasks';
    case 'completed':
    case 'cancelled':
      return 'Completed';
    default:
      return 'Awaiting offers';
  }
}

class MapHomeScreen extends ConsumerStatefulWidget {
  const MapHomeScreen({super.key});

  @override
  ConsumerState<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends ConsumerState<MapHomeScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(3.1390, 101.6869); // KL default
  bool _isTaskerMode = true;
  bool _isMapView = false; // Toggle between map and list view
  final PageController _cardPageController = PageController(viewportFraction: 0.85);
  int _currentCardIndex = 0;
  final _locationService = LocationService();
  bool _isLoadingLocation = false;

  // Pagination variables
  int _displayLimit = 5; // Start with 5 tasks
  Timer? _autoLoadTimer;
  final ScrollController _listScrollController = ScrollController();

  // Sticky header state
  bool _isHeaderCollapsed = false;
  static const double _headerCollapseThreshold = 100.0; // Scroll threshold to collapse header

  // Helper function to generate random coordinates near KL
  LatLng _generateRandomKLCoordinate(int index) {
    // Base KL coordinates with slight variations
    final baseLat = 3.1390;
    final baseLng = 101.6869;

    // Generate deterministic variation based on index
    final latVariation = (index * 0.003) - 0.015; // Range: -0.015 to +0.015
    final lngVariation = ((index * 2) % 10) * 0.002 - 0.01; // Range: -0.01 to +0.01

    return LatLng(baseLat + latVariation, baseLng + lngVariation);
  }

  // Helper function to calculate distance between two points
  String _calculateDistance(LatLng point1, LatLng point2) {
    final Distance distance = const Distance();
    final meters = distance.as(LengthUnit.Meter, point1, point2);
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m away';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km away';
    }
  }

  @override
  void initState() {
    super.initState();
    dev.log('[MapHomeScreen] initState - Initial _currentLocation: $_currentLocation');
    _getCurrentLocation();

    // Add scroll listener for list view pagination
    _listScrollController.addListener(_onListScroll);

    // Start auto-load timer for map view (loads 5 more tasks every 3 seconds)
    _startAutoLoadTimer();

    // Start location tracking if user is already available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(currentProfileProvider).value;
      final user = ref.read(currentUserProvider);
      if (profile?.isAvailable == true && user != null) {
        dev.log('[MapHomeScreen] User is available, starting location tracking');
        _locationService.startTracking(user.id);
      }
    });
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _listScrollController.dispose();
    _autoLoadTimer?.cancel();
    super.dispose();
  }

  // Pagination helper methods
  void _onListScroll() {
    if (!_listScrollController.hasClients) return;

    final currentScroll = _listScrollController.position.pixels;

    // Handle header collapse/expand based on scroll position
    if (currentScroll > _headerCollapseThreshold && !_isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = true;
      });
    } else if (currentScroll <= _headerCollapseThreshold && _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = false;
      });
    }

    // Handle pagination - load more tasks when near bottom (80% of scroll extent)
    final maxScroll = _listScrollController.position.maxScrollExtent;
    final threshold = maxScroll * 0.8;

    if (currentScroll >= threshold) {
      _loadMoreTasks();
    }
  }

  void _startAutoLoadTimer() {
    // For map view: auto-load 5 more tasks every 3 seconds in background
    _autoLoadTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isMapView && mounted) {
        _loadMoreTasks();
      }
    });
  }

  void _loadMoreTasks() {
    setState(() {
      _displayLimit += 5; // Increase limit by 5
      dev.log('[MapHomeScreen] Loaded more tasks, new limit: $_displayLimit');
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      dev.log('[MapHomeScreen] Checking location permission...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        dev.log('[MapHomeScreen] Location services are disabled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        dev.log('[MapHomeScreen] Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          dev.log('[MapHomeScreen] Location permission denied');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to show nearby tasks'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        dev.log('[MapHomeScreen] Location permission permanently denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location permission in app settings'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      dev.log('[MapHomeScreen] Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,  // Medium accuracy is faster and sufficient
        timeLimit: const Duration(seconds: 30),     // Increased timeout for better reliability
      );

      dev.log('[MapHomeScreen] Got position: ${position.latitude}, ${position.longitude}');

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      dev.log('[MapHomeScreen] Updated _currentLocation to: $_currentLocation');

      // Wait for map to be ready before moving
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            dev.log('[MapHomeScreen] Moving map to: $_currentLocation');
            _mapController.move(_currentLocation, 15);
          } catch (e) {
            dev.log('[MapHomeScreen] Error moving map: $e');
          }
        }
      });
    } catch (e) {
      dev.log('[MapHomeScreen] Error getting location: $e');
      // Silently use default KL location on timeout - no scary error message
      // This provides better UX when GPS is slow or unavailable
      dev.log('[MapHomeScreen] Using default KL location');
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    print('_showFilterBottomSheet called in MapHomeScreen');
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          print('Building filter bottom sheet in MapHomeScreen');
          return StatefulBuilder(
            builder: (context, setState) => Container(
              color: AppColors.backgroundPrimary,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
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
                                color: AppColors.textSecondary,
                              ),
                            ),
                            orElse: () => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  // Category filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundPrimary,
                      borderRadius: AppRadius.smMd,
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: DropdownButton<String>(
                      value: ref.watch(categoryFilterProvider),
                      hint: Text('Category'),
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down),
                      isExpanded: true,
                      dropdownColor: AppColors.backgroundPrimary,
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
                  SizedBox(height: AppSpacing.xxl),
                  // Clear All Filters button
                  if (ref.watch(categoryFilterProvider) != 'All Categories')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton(
                        onPressed: () {
                          dev.log('[MapHomeScreen] Clear All Filters button pressed');
                          ref.read(categoryFilterProvider.notifier).state = 'All Categories';
                          dev.log('[MapHomeScreen] Filters cleared - Category: All Categories');
                          setState(() {}); // Refresh to update UI
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          side: const BorderSide(color: AppColors.borderDefault),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.smMd,
                          ),
                        ),
                        child: Text(
                          'Clear All Filters',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Apply Filters button
                  ElevatedButton(
                    onPressed: () {
                      dev.log('[MapHomeScreen] Apply Filters button pressed');
                      dev.log('[MapHomeScreen] Current filters - Category: ${ref.read(categoryFilterProvider)}, Sort: ${ref.read(sortFilterProvider)}');

                      // Close the bottom sheet - Provider will auto-rebuild due to state changes
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.smMd,
                        side: const BorderSide(
                          color: AppColors.primaryDark,
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

  @override
  Widget build(BuildContext context) {
    // Calculate actual header heights based on component sizes
    // This works consistently across all devices regardless of screen size
    const double searchBarHeight = 68.0;  // Container height from MapSearchBar
    const double bannerHeight = 120.0 + 8.0 + 8.0 + 8.0;  // Banner + top padding + bottom padding + indicator
    const double tabBarHeight = 10.0 + 2.0 + 10.0;  // Tab button padding + border + padding

    // When collapsed, only show minimal header
    const double collapsedTop = 50.0;

    // When expanded, show full header: search bar + banner + tabs
    const double expandedTop = searchBarHeight + bannerHeight + tabBarHeight + 160 ;

    // Preload BOTH datasets for instant tab switching (no delay)
    final taskerTasksAsync = ref.watch(filteredAvailableTasksProvider);  // Find Job data - all open tasks
    final posterTasksAsync = ref.watch(myTasksProvider);                 // Ongoing Job data - tasks assigned to current user

    // Pick which dataset to display based on current mode
    final tasksAsync = _isTaskerMode ? taskerTasksAsync : posterTasksAsync;

    return Scaffold(
      backgroundColor: _isMapView ? AppColors.backgroundPrimary : AppColors.white,
      floatingActionButton: _isMapView && _isTaskerMode
          ? Padding(
              padding: const EdgeInsets.only(bottom: 200), // Above the task cards
              child: FloatingActionButton(
                onPressed: _isLoadingLocation ? null : () async {
                  setState(() => _isLoadingLocation = true);

                  try {
                    await _getCurrentLocation();
                    // Animate map to current location after frame is rendered
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          try {
                            _mapController.move(_currentLocation, 15);
                          } catch (e) {
                            dev.log('[MapHomeScreen] Error moving map: $e');
                          }
                        }
                      });
                    }
                  } catch (e) {
                    dev.log('[MapHomeScreen] Error getting location: $e');
                  } finally {
                    if (mounted) {
                      setState(() => _isLoadingLocation = false);
                    }
                  }
                },
                backgroundColor: AppColors.backgroundPrimary,
                foregroundColor: Colors.blue,
                elevation: 4,
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue,
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
            )
          : null,
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading tasks: $error')),
        data: (tasks) {
          // Sort tasks by distance from current location (closest first)
          final sortedTasks = List<Task>.from(tasks);
          sortedTasks.sort((a, b) {
            // Only sort tasks that have valid coordinates
            if (a.latitude == null || a.longitude == null) return 1;
            if (b.latitude == null || b.longitude == null) return -1;

            final distanceA = const Distance().as(
              LengthUnit.Meter,
              _currentLocation,
              LatLng(a.latitude!, a.longitude!),
            );
            final distanceB = const Distance().as(
              LengthUnit.Meter,
              _currentLocation,
              LatLng(b.latitude!, b.longitude!),
            );

            return distanceA.compareTo(distanceB);
          });

          // Apply pagination - show only first N tasks based on display limit
          final paginatedTasks = sortedTasks.take(_displayLimit).toList();
          dev.log('[MapHomeScreen] Total tasks: ${sortedTasks.length}, Displaying: ${paginatedTasks.length}');

          return Stack(
            children: [
            // Show either map or list view (map only available in Tasker mode)
            if (_isMapView && _isTaskerMode)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  // Shift center slightly up to account for UI elements at top and bottom
                  initialCenter: LatLng(
                    _currentLocation.latitude + 0.002, // Shift north slightly
                    _currentLocation.longitude,
                  ),
                  initialZoom: 15,
                  minZoom: 10,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.taskawayasia.taskaway',
                  ),
                  // Task markers layer (drawn first, below current location)
                  MarkerLayer(
                    markers: paginatedTasks.asMap().entries.where((entry) {
                      // Only show tasks that have valid coordinates
                      final task = entry.value;
                      return task.latitude != null && task.longitude != null;
                    }).map((entry) {
                      final index = entry.key;
                      final task = entry.value;
                      // Use actual task location from database
                      final position = LatLng(task.latitude!, task.longitude!);

                      return Marker(
                        point: position,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentCardIndex = index;
                            });
                            _cardPageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.textPrimary87,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Current location marker layer (drawn on top)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation,
                        width: 50,
                        height: 50,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse circle for visibility
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Inner circle with border
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.textPrimary.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (!_isMapView || !_isTaskerMode)
              // List view (shown when not in map view or when in Poster mode)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: _isHeaderCollapsed ? collapsedTop : expandedTop, // Use calculated header heights
                bottom: _isTaskerMode ? 48 : 0, // Space for VIEW MAP button only in Tasker mode
                left: 0,
                right: 0,
                child: Container(
                  color: AppColors.white, // White background
                  child: ListView.separated(
                    controller: _listScrollController, // Add scroll controller for pagination
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: paginatedTasks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _TaskListItem(
                        task: paginatedTasks[index],
                        index: index,
                        showStatus: !_isTaskerMode, // Show status for Ongoing Job, hide for Find Job
                      );
                    },
                  ),
                ),
              ),
          
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _isHeaderCollapsed ? -300 : 0, // Move off-screen when collapsed
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Yellow background section
                Container(
                  color: const Color(0xFFFFDB5B),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                    // Profile section with availability switch
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile avatar
                          ref.watch(currentProfileProvider).when(
                            data: (profile) => CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.gray200,
                              backgroundImage: profile?.avatarUrl != null
                                ? NetworkImage(profile!.avatarUrl!)
                                : null,
                              child: profile?.avatarUrl == null
                                ? Text(
                                    profile?.fullName.isNotEmpty == true
                                      ? profile!.fullName[0].toUpperCase()
                                      : '?',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                : null,
                            ),
                            loading: () => CircleAvatar(radius: 24, backgroundColor: AppColors.gray200),
                            error: (_, __) => CircleAvatar(radius: 24, backgroundColor: AppColors.gray200),
                          ),
                          SizedBox(width: AppSpacing.md),
                          // Profile name, role, and availability switch
                          Expanded(
                            child: ref.watch(currentProfileProvider).when(
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
                                  ),
                                ],
                              ),
                              loading: () => Column(
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
                                  const Text(
                                    'User',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              error: (_, __) => Column(
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
                                  const Text(
                                    'User',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  _buildAvailabilitySwitchCompact(),
                                ],
                              ),
                            ),
                          ),
                          // Availability badge on the right
                          _buildAvailabilityBadge(),
                        ],
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
                // White rounded container with search and content
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(_isHeaderCollapsed ? 0 : 24),
                      topRight: Radius.circular(_isHeaderCollapsed ? 0 : 24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show search bar in Tasker mode
                      if (_isTaskerMode) ...[
                        MapSearchBar(
                          isTaskerMode: _isTaskerMode,
                          onFilterTap: () {
                            print('Filter tap received in MapHomeScreen');
                            _showFilterBottomSheet(context);
                          },
                          onToggle: (isTasker) {
                            setState(() {
                              _isTaskerMode = isTasker;
                              // Reset pagination when switching modes
                              _displayLimit = 5;
                              // When switching to Poster mode, automatically switch to list view
                              if (!isTasker) {
                                _isMapView = false;
                              } else {
                                // When switching back to Tasker mode, show map view
                                _isMapView = true;
                              }
                            });
                          },
                          onSearch: (query) {
                            // Handle search
                          },
                        ),
                      ] else
                        // Show search bar in Poster mode (MapSearchBar already includes tabs)
                        MapSearchBar(
                          isTaskerMode: _isTaskerMode,
                          onFilterTap: () {
                            print('Filter tap received in MapHomeScreen');
                            _showFilterBottomSheet(context);
                          },
                          onToggle: (isTasker) {
                            setState(() {
                              _isTaskerMode = isTasker;
                              // Reset pagination when switching modes
                              _displayLimit = 5;
                              // Keep current view preference when switching modes
                            });
                          },
                          onSearch: (query) {
                            // Handle search
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
            // Bottom section for map view only (cards and view toggle)
            if (_isMapView)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: paginatedTasks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final task = entry.value;
                          // Use actual task location if available, fallback to user location
                          final position = (task.latitude != null && task.longitude != null)
                              ? LatLng(task.latitude!, task.longitude!)
                              : _currentLocation;
                          final distance = _calculateDistance(_currentLocation, position);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentCardIndex = index;
                              });
                              // Move map to actual task location if available
                              if (task.latitude != null && task.longitude != null) {
                                final position = LatLng(task.latitude!, task.longitude!);
                                try {
                                  _mapController.move(position, 16);
                                } catch (e) {
                                  dev.log('[MapHomeScreen] Error moving map on tap: $e');
                                }
                              }
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.6,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: ServiceCard(
                                task: task,
                                distance: distance,
                                isFocused: index == _currentCardIndex,
                                onViewDetails: () {
                                  context.go('/home/tasks/${task.id}');
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  
                  Container(
                    width: double.infinity,
                    color: AppColors.backgroundPrimary,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isMapView = false;
                        });
                      },
                      icon: const Icon(Icons.view_list, size: 18, color: AppColors.textPrimary),
                      label: Text(
                        'VIEW LIST',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // View toggle button for list view (at bottom) - only in Tasker mode
          if (!_isMapView && _isTaskerMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                color: AppColors.backgroundPrimary,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isMapView = true;
                    });
                  },
                  icon: const Icon(Icons.map_outlined, size: 18, color: AppColors.textPrimary),
                  label: Text(
                    'VIEW MAP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      ),
    );
  }

  /// Build availability switch widget
  Widget _buildStatusFilter() {
    final currentStatus = ref.watch(statusProvider);
    final statuses = ['Awaiting offers', 'Upcoming tasks', 'Completed'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: statuses.map((status) {
          final isSelected = currentStatus == status;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(statusProvider.notifier).state = status;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvailabilitySwitch() {
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        final isAvailable = profile?.isAvailable ?? false;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.successLight : AppColors.warningLight,
              borderRadius: AppRadius.xxl,
              border: Border.all(
                color: isAvailable ? AppColors.success : AppColors.warning,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAvailable ? 'Available' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? AppColors.success : AppColors.warning,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 40,
                  height: 20,
                  child: Switch(
                    value: isAvailable,
                    onChanged: (value) async {
                      if (currentUser == null) return;

                      if (value) {
                        // Turning availability ON - request location permission and start tracking
                        dev.log('[MapHomeScreen] Enabling availability, requesting location permission');

                        final hasPermission = await _locationService.requestPermissions();
                        if (!hasPermission) {
                          // Show permission denied message
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Location permission is required to be available for tasks',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                          return;
                        }

                        // Update availability in database
                        await ref.read(profileControllerProvider).updateAvailability(
                          userId: currentUser.id,
                          isAvailable: true,
                        );

                        // Start location tracking
                        dev.log('[MapHomeScreen] Starting location tracking');
                        await _locationService.startTracking(currentUser.id);

                        // Refresh profile to update UI
                        ref.invalidate(currentProfileProvider);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You are now available! Your location will update every 30 minutes',
                              ),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } else {
                        // Turning availability OFF - stop tracking
                        dev.log('[MapHomeScreen] Disabling availability, stopping location tracking');

                        await ref.read(profileControllerProvider).updateAvailability(
                          userId: currentUser.id,
                          isAvailable: false,
                        );

                        // Stop location tracking
                        _locationService.stopTracking();

                        // Refresh profile to update UI
                        ref.invalidate(currentProfileProvider);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You are now offline',
                              ),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        }
                      }
                    },
                    activeColor: AppColors.success,
                    activeTrackColor: AppColors.successLight,
                    inactiveThumbColor: AppColors.warning,
                    inactiveTrackColor: AppColors.warningLight,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Build compact availability switch for profile section
  Widget _buildAvailabilitySwitchCompact() {
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        final isAvailable = profile?.isAvailable ?? false;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAvailable ? AppColors.successLight : AppColors.warningLight,
            borderRadius: AppRadius.xxl,
            border: Border.all(
              color: isAvailable ? AppColors.success : AppColors.warning,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAvailable ? 'Available' : 'Offline',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isAvailable ? AppColors.success : AppColors.warning,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 40,
                height: 20,
                child: Switch(
                  value: isAvailable,
                  onChanged: (value) async {
                    if (currentUser == null) return;

                    if (value) {
                      // Turning availability ON
                      final hasPermission = await _locationService.requestPermissions();
                      if (!hasPermission) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location permission is required to be available for tasks'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                        return;
                      }

                      await ref.read(profileControllerProvider).updateAvailability(
                        userId: currentUser.id,
                        isAvailable: true,
                      );

                      await _locationService.startTracking(currentUser.id);
                      ref.invalidate(currentProfileProvider);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You are now available!'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } else {
                      // Turning availability OFF
                      await ref.read(profileControllerProvider).updateAvailability(
                        userId: currentUser.id,
                        isAvailable: false,
                      );

                      _locationService.stopTracking();
                      ref.invalidate(currentProfileProvider);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You are now offline'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }
                    }
                  },
                  activeColor: AppColors.success,
                  activeTrackColor: AppColors.successLight,
                  inactiveThumbColor: AppColors.warning,
                  inactiveTrackColor: AppColors.warningLight,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Build availability badge (Offline/Online with dot)
  Widget _buildAvailabilityBadge() {
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        final isAvailable = profile?.isAvailable ?? false;
        return GestureDetector(
          onTap: () async {
            if (currentUser == null) return;

            final newValue = !isAvailable;

            if (newValue) {
              // Turning availability ON
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
              _locationService.startTracking(currentUser.id);
            } else {
              // Turning availability OFF
              _locationService.stopTracking();
            }

            // Update availability in database
            try {
              await ref.read(profileControllerProvider).updateAvailability(
                userId: currentUser.id,
                isAvailable: newValue,
              );
              ref.invalidate(currentProfileProvider);
            } catch (e) {
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
    );
  }
}

class ServiceMarker {
  final String id;
  final LatLng position;
  final String title;
  final String distance;
  final String postedBy;
  final String price;
  final String time;

  ServiceMarker({
    required this.id,
    required this.position,
    required this.title,
    required this.distance,
    required this.postedBy,
    required this.price,
    this.time = '2 hours ago',
  });
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskListItem extends ConsumerWidget {
  final Task task;
  final int index;
  final bool showStatus;

  const _TaskListItem({
    required this.task,
    required this.index,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posterName = task.posterProfile?['full_name'] as String? ?? 'Unknown User';
    final offerCount = task.offers?.length ?? 0;

    // Status color mapping (only used when showStatus is true)
    final statusColors = {
      'open': AppColors.warning,
      'pending_approval': AppColors.warning,
      'accepted': AppColors.info,
      'assigned': AppColors.info,
      'in_progress': Colors.purple,
      'completed': AppColors.success,
      'cancelled': AppColors.error,
    };
    final statusColor = statusColors[task.status.toLowerCase()] ?? AppColors.textTertiary;

    // User-friendly status labels
    final statusLabels = {
      'open': 'Open',
      'pending_approval': 'Pending',
      'accepted': 'Accepted',
      'assigned': 'Assigned',
      'in_progress': 'In Progress',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    };
    final statusLabel = statusLabels[task.status.toLowerCase()] ?? task.status;

    return InkWell(
      onTap: () {
        context.go('/home/tasks/${task.id}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: AppColors.borderDefault,
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Task details
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'By ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          posterName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Bidding • $offerCount Offer${offerCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Due date ${_formatDate(task.scheduledTime)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right side - Price, Status, Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Price
                  Text(
                    'RM ${task.price.toStringAsFixed(0)}',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Status Badge - Only for Ongoing Job
                  if (showStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: AppRadius.lg,
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),

                  // Spacer to push button to bottom
                  const Spacer(),

                  // Button - Always at bottom (Apply Job for Find Job, View Details for Ongoing Job)
                  SizedBox(
                    height: 24,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/home/tasks/${task.id}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gray900,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                        minimumSize: const Size(0, 24),
                      ),
                      child: Text(
                        showStatus ? 'View Details' : 'Apply Job',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: AppTypography.semiBold,
                          fontSize: 10,
                        ),
                      ),
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

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return '${weekdays[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}