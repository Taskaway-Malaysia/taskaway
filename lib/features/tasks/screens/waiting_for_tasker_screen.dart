import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/task.dart';
import '../controllers/task_controller.dart';
import '../../auth/models/profile.dart';
import '../../../core/services/supabase_service.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;

class WaitingForTaskerScreen extends ConsumerStatefulWidget {
  final String taskId;

  const WaitingForTaskerScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<WaitingForTaskerScreen> createState() => _WaitingForTaskerScreenState();
}

class _WaitingForTaskerScreenState extends ConsumerState<WaitingForTaskerScreen> {
  Timer? _pollTimer;
  Task? _currentTask;
  Profile? _taskerProfile;
  final MapController _mapController = MapController();
  bool _initialZoomDone = false;

  @override
  void initState() {
    super.initState();

    // Poll for task and tasker location updates every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkTaskStatusAndLocation();
    });

    // Initial check
    _checkTaskStatusAndLocation();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkTaskStatusAndLocation() async {
    try {
      final taskController = ref.read(taskControllerProvider);
      final task = await taskController.getTaskById(widget.taskId);

      if (mounted) {
        setState(() {
          _currentTask = task;
        });

        // Check if task status has changed from 'accepted'
        if (task.status != 'accepted') {
          _pollTimer?.cancel();

          // Navigate to task details
          if (mounted) {
            context.go('/home/browse/${task.id}');
          }
          return;
        }

        // Fetch tasker profile if we have a tasker ID
        if (task.taskerId != null) {
          try {
            final supabase = SupabaseService.client;
            final profileData = await supabase
                .from('taskaway_profiles')
                .select()
                .eq('id', task.taskerId!)
                .single();

            final profile = Profile.fromJson(profileData);

            if (mounted) {
              setState(() {
                _taskerProfile = profile;
              });

              // Zoom to fit both markers on first load
              if (!_initialZoomDone && task.latitude != null && task.longitude != null && profile.latitude != null && profile.longitude != null) {
                _initialZoomDone = true;
                _fitBounds(
                  LatLng(task.latitude!, task.longitude!),
                  LatLng(profile.latitude!, profile.longitude!),
                );
              }
            }
          } catch (e) {
            print('Error fetching tasker profile: $e');
          }
        }
      }
    } catch (e) {
      print('Error checking task status: $e');
    }
  }

  void _fitBounds(LatLng point1, LatLng point2) {
    final bounds = LatLngBounds(point1, point2);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Haversine formula to calculate distance in kilometers
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((point2.latitude - point1.latitude) * p) / 2 +
              cos(point1.latitude * p) * cos(point2.latitude * p) *
              (1 - cos((point2.longitude - point1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  String _estimateTime(double km) {
    // Assuming average speed of 30 km/h in city
    final hours = km / 30;
    final minutes = (hours * 60).round();

    if (minutes < 1) {
      return 'Arriving soon';
    } else if (minutes < 60) {
      return '$minutes min';
    } else {
      final hrs = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hrs}h ${mins}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTaskLocation = _currentTask?.latitude != null && _currentTask?.longitude != null;
    final hasTaskerLocation = _taskerProfile?.latitude != null && _taskerProfile?.longitude != null;

    final taskLocation = hasTaskLocation
        ? LatLng(_currentTask!.latitude!, _currentTask!.longitude!)
        : null;
    final taskerLocation = hasTaskerLocation
        ? LatLng(_taskerProfile!.latitude!, _taskerProfile!.longitude!)
        : null;

    final distance = (taskLocation != null && taskerLocation != null)
        ? _calculateDistance(taskLocation, taskerLocation)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map
          if (hasTaskLocation)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: taskLocation!,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.taskaway.app',
                ),
                MarkerLayer(
                  markers: [
                    // Task location marker (destination)
                    Marker(
                      point: taskLocation,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFDB5B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Task',
                              style: TextStyle(
                                fontFamily: 'Instrument Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tasker location marker (moving)
                    if (taskerLocation != null)
                      Marker(
                        point: taskerLocation,
                        width: 80,
                        height: 80,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Tasker',
                                style: TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            )
          else
            // Loading state
            Container(
              color: const Color(0xFFF5F5F5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFDB5B),
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF000000)),
                      onPressed: () => context.go('/home/tasks'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tasker on the way',
                            style: TextStyle(
                              fontFamily: 'Instrument Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF000000),
                            ),
                          ),
                          if (_taskerProfile != null)
                            Text(
                              _taskerProfile!.fullName ?? 'Tasker',
                              style: const TextStyle(
                                fontFamily: 'Instrument Sans',
                                fontSize: 12,
                                color: Color(0xFF788494),
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

          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Distance and ETA
                    if (distance != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(
                                Icons.straighten,
                                color: Color(0xFF788494),
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDistance(distance),
                                style: const TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              const Text(
                                'Distance',
                                style: TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 12,
                                  color: Color(0xFF788494),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: const Color(0xFFE5E5E5),
                          ),
                          Column(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFF788494),
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _estimateTime(distance),
                                style: const TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              const Text(
                                'Est. Time',
                                style: TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 12,
                                  color: Color(0xFF788494),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // Task details
                    if (_currentTask != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFDB5B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _currentTask!.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Instrument Sans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'RM ${_currentTask!.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'Instrument Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currentTask!.title,
                            style: const TextStyle(
                              fontFamily: 'Instrument Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF000000),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Color(0xFF788494),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _currentTask!.location,
                                  style: const TextStyle(
                                    fontFamily: 'Instrument Sans',
                                    fontSize: 12,
                                    color: Color(0xFF788494),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Contact button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFDB5B),
                          foregroundColor: const Color(0xFF000000),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                            side: const BorderSide(
                              color: Color(0xFFFFC333),
                              width: 1,
                            ),
                          ),
                        ),
                        onPressed: () {
                          // TODO: Navigate to chat with tasker
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chat feature coming soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text(
                          'Message Tasker',
                          style: TextStyle(
                            fontFamily: 'Instrument Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator while fetching data
          if (_currentTask == null || (_taskerProfile == null && _currentTask?.taskerId != null))
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFDB5B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
