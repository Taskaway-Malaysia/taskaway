import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../tasks/models/task.dart';
import '../../tasks/controllers/task_controller.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/service_card.dart';

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
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      _mapController.move(_currentLocation, 15);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use different providers based on mode
    final tasksAsync = _isTaskerMode
        ? ref.watch(availableTasksWithPosterProvider)  // Show all open tasks for taskers
        : ref.watch(currentUserPostedTasksProvider);    // Show only user's posted tasks for posters

    return Scaffold(
      backgroundColor: _isMapView ? Colors.white : const Color(0xFFF5F5F5),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading tasks: $error')),
        data: (tasks) => Stack(
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
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                      ),
                      ...tasks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final task = entry.value;
                        final position = _generateRandomKLCoordinate(index);

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
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.black87,
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      }),
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
                  color: const Color(0xFFF8F8F8), // Light gray background
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 12), // Padding at the top
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return _TaskListItem(
                        task: tasks[index],
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
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Show "List" title when in Poster mode
                    if (!_isTaskerMode)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.white,
                        child: const Center(
                          child: Text(
                            'List',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    // Only show search bar in Tasker mode
                    if (_isTaskerMode)
                      MapSearchBar(
                        isTaskerMode: _isTaskerMode,
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
                      )
                    else
                      // Show only tabs in Poster mode
                      Container(
                        color: Colors.white,
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
                      height: 170,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: PageView.builder(
                        controller: _cardPageController,
                        itemCount: tasks.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentCardIndex = index;
                          });
                          final position = _generateRandomKLCoordinate(index);
                          _mapController.move(position, 16);
                        },
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final position = _generateRandomKLCoordinate(index);
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
                    color: Colors.white,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isMapView = false;
                        });
                      },
                      icon: const Icon(Icons.view_list, size: 18),
                      label: const Text(
                        'VIEW LIST',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
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
                color: Colors.white,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isMapView = true;
                    });
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text(
                    'VIEW MAP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.amber : Colors.transparent,
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
              color: isSelected ? Colors.black : Colors.grey.shade600,
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
      'open': Colors.orange,
      'accepted': Colors.blue,
      'in_progress': Colors.purple,
      'completed': Colors.green,
      'cancelled': Colors.red,
    };

    final statusColor = statusColors[task.status.toLowerCase()] ?? Colors.grey;
    final posterName = task.posterProfile?['full_name'] as String? ?? 'Unknown User';
    final offerCount = task.offers?.length ?? 0;

    return InkWell(
      onTap: () {
        context.go('/home/tasks/${task.id}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
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
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'By ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        posterName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bidding • $offerCount Offer${offerCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due date ${_formatDate(task.scheduledTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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