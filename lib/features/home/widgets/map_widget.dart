import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:taskaway/core/constants/api_constants.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import '../../../core/theme/app_radius.dart';

// Provider for map view mode (map vs list)
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.map);

// Provider for map controller
final mapControllerProvider = StateProvider<MapController>((ref) => MapController());

// Provider for selected task on map
final selectedTaskProvider = StateProvider<Task?>((ref) => null);

enum ViewMode { map, list }

class MapWidget extends ConsumerStatefulWidget {
  final List<Task> tasks;
  final Function(Task)? onTaskTap;

  const MapWidget({
    super.key,
    required this.tasks,
    this.onTaskTap,
  });

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Marker> _buildTaskMarkers() {
    return widget.tasks.map((task) {
      // For now, use random positions around Kuala Lumpur
      // In real implementation, you'd geocode the task.location
      final latLng = _getTaskLocation(task);
      
      return Marker(
        point: latLng,
        width: 200,
        height: 120,
        child: GestureDetector(
          onTap: () {
            ref.read(selectedTaskProvider.notifier).state = task;
            widget.onTaskTap?.call(task);
          },
          child: _buildFloatingTaskCard(task),
        ),
      );
    }).toList();
  }

  List<Marker> _buildProfileMarkers() {
    // Add some profile markers around the map like in the Figma design
    final profileLocations = [
      const LatLng(3.160, 101.710), // Top right
      const LatLng(3.110, 101.650), // Bottom left  
      const LatLng(3.145, 101.680), // Center left
    ];
    
    return profileLocations.map((location) {
      return Marker(
        point: location,
        width: 30,
        height: 30,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: const Icon(
            Icons.person,
            size: 16,
            color: Color(0xFF666666),
          ),
        ),
      );
    }).toList();
  }

  LatLng _getTaskLocation(Task task) {
    // TODO: Implement proper geocoding for task.location
    // For now, generate random positions around Kuala Lumpur area
    final random = task.title.hashCode % 1000;
    final lat = 3.139 + (random % 100) * 0.001 - 0.05; // Small area around KL
    final lng = 101.687 + (random % 100) * 0.001 - 0.05;
    return LatLng(lat, lng);
  }

  Widget _buildFloatingTaskCard(Task task) {
    final isSelected = ref.watch(selectedTaskProvider)?.id == task.id;
    
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFDB5B) : Colors.white,
        borderRadius: AppRadius.mdLg,
        border: Border.all(
          color: isSelected ? const Color(0xFFFCC133) : const Color(0xFFD9D9D9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF202020),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${task.location}',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF788494),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'By ${task.posterName ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF788494),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'RM ${task.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskMarkers = _buildTaskMarkers();
    final profileMarkers = _buildProfileMarkers();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(3.139, 101.687), // Kuala Lumpur center
        initialZoom: 11.0,
        maxZoom: 18.0,
        minZoom: 8.0,
        onTap: (tapPosition, point) {
          // Clear selection when tapping on map
          ref.read(selectedTaskProvider.notifier).state = null;
        },
      ),
      children: [
        TileLayer(
          urlTemplate: '${ApiConstants.mapTilerStyleUrl}${ApiConstants.mapTilerApiKey}',
          userAgentPackageName: 'my.taskaway.taskaway',
          maxZoom: 18,
        ),
        MarkerLayer(
          markers: [...profileMarkers, ...taskMarkers],
        ),
      ],
    );
  }
}