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

class MapHomeScreen extends ConsumerStatefulWidget {
  const MapHomeScreen({super.key});

  @override
  ConsumerState<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends ConsumerState<MapHomeScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(3.1390, 101.6869); // KL default
  bool _isTaskerMode = true;
  bool _isMapView = true; // Toggle between map and list view
  final PageController _cardPageController = PageController(viewportFraction: 0.85);
  int _currentCardIndex = 0;
  final _locationService = LocationService();
  bool _isLoadingLocation = false;

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
    super.dispose();
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get your location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
                  SizedBox(height: AppSpacing.lg),
                  // Sort filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundPrimary,
                      borderRadius: AppRadius.smMd,
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: DropdownButton<String>(
                      value: ref.watch(sortFilterProvider),
                      hint: Text('Sort by'),
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down),
                      isExpanded: true,
                      dropdownColor: AppColors.backgroundPrimary,
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
                  if (ref.watch(categoryFilterProvider) != 'All Categories' ||
                      ref.watch(sortFilterProvider) != 'Latest')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(categoryFilterProvider.notifier).state = 'All Categories';
                          ref.read(sortFilterProvider.notifier).state = 'Latest';
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
                    onPressed: () => Navigator.of(context).pop(),
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
    // Use filtered tasks when in tasker mode
    final tasksAsync = _isTaskerMode
        ? ref.watch(filteredAvailableTasksProvider)  // Use filtered tasks for taskers
        : ref.watch(currentUserPostedTasksProvider);    // Show only user's posted tasks for posters

    return Scaffold(
      backgroundColor: _isMapView ? AppColors.backgroundPrimary : AppColors.backgroundDisabled,
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

          return Stack(
            children: [
            // Show either map or list view (map only available in Tasker mode)
            if (_isMapView && _isTaskerMode)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation,
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
                    markers: sortedTasks.asMap().entries.where((entry) {
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
              Positioned.fill(
                top: _isTaskerMode ? 140 : 150, // Adjusted space for "List" title without search bar
                bottom: _isTaskerMode ? 48 : 0, // Space for VIEW MAP button only in Tasker mode
                child: Container(
                  color: AppColors.backgroundSecondary, // Light gray background
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 24), // Increased padding to prevent overlap with tabs
                    itemCount: sortedTasks.length,
                    itemBuilder: (context, index) {
                      return _TaskListItem(
                        task: sortedTasks[index],
                        index: index,
                      );
                    },
                  ),
                ),
              ),
          
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.backgroundPrimary,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Show "List" title when in Poster mode
                    if (!_isTaskerMode)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: AppColors.backgroundPrimary,
                        child: const Center(
                          child: Text(
                            'List',
                            style: AppTypography.titleMedium,
                          ),
                        ),
                      ),
                    // Show Taskaway logo and search bar in Tasker mode
                    if (_isTaskerMode) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Image.asset(
                          'assets/images/taskaway_logo.png',
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                      MapSearchBar(
                        isTaskerMode: _isTaskerMode,
                        onFilterTap: () {
                          print('Filter tap received in MapHomeScreen');
                          _showFilterBottomSheet(context);
                        },
                        onToggle: (isTasker) {
                          setState(() {
                            _isTaskerMode = isTasker;
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
                      // Show only tabs in Poster mode
                      Column(
                        children: [
                          Container(
                            color: AppColors.backgroundPrimary,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _TabButton(
                                    label: 'TASKER',
                                    isSelected: _isTaskerMode,
                                    onTap: () => setState(() {
                                      _isTaskerMode = true;
                                      _isMapView = true; // Switch to map view when going to Tasker
                                    }),
                                  ),
                                ),
                                Expanded(
                                  child: _TabButton(
                                    label: 'POSTER',
                                    isSelected: !_isTaskerMode,
                                    onTap: () => setState(() {
                                      _isTaskerMode = false;
                                      _isMapView = false; // Switch to list view when going to Poster
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    // Availability Switch - Show for all users
                    _buildAvailabilitySwitch(),
                  ],
                ),
              ),
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
                    Container(
                      height: 245,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: PageView.builder(
                        controller: _cardPageController,
                        itemCount: sortedTasks.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentCardIndex = index;
                          });
                          final task = sortedTasks[index];
                          // Move map to actual task location if available
                          if (task.latitude != null && task.longitude != null) {
                            final position = LatLng(task.latitude!, task.longitude!);
                            try {
                              _mapController.move(position, 16);
                            } catch (e) {
                              dev.log('[MapHomeScreen] Error moving map on page change: $e');
                            }
                          }
                        },
                        itemBuilder: (context, index) {
                          final task = sortedTasks[index];
                          // Use actual task location if available, fallback to user location
                          final position = (task.latitude != null && task.longitude != null)
                              ? LatLng(task.latitude!, task.longitude!)
                              : _currentLocation;
                          final distance = _calculateDistance(_currentLocation, position);

                          return Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ServiceCard(
                              task: task,
                              distance: distance,
                              isFocused: index == _currentCardIndex,
                              onViewDetails: () {
                                context.go('/home/tasks/${task.id}');
                              },
                            ),
                          );
                        },
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

  const _TaskListItem({
    required this.task,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Status color mapping
    final statusColors = {
      'open': AppColors.warning,
      'accepted': AppColors.info,
      'in_progress': Colors.purple,
      'completed': AppColors.success,
      'cancelled': AppColors.error,
    };

    final statusColor = statusColors[task.status.toLowerCase()] ?? AppColors.textTertiary;
    final posterName = task.posterProfile?['full_name'] as String? ?? 'Unknown User';
    final offerCount = task.offers?.length ?? 0;

    return InkWell(
      onTap: () {
        context.go('/home/tasks/${task.id}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderDefault,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Task info
            Expanded(
              child: Column(
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
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 2),
                  Text(
                    'Bidding • $offerCount Offer${offerCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
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

            // Right side - Price and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${task.price.toStringAsFixed(0)}',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: AppTypography.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: AppRadius.lg,
                  ),
                  child: Text(
                    task.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
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