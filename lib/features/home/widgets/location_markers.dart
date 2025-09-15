import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:taskaway/features/auth/models/profile.dart';

class LocationMarkers extends ConsumerWidget {
  final List<Profile> taskers;
  final Function(Profile)? onTaskerTap;

  const LocationMarkers({
    super.key,
    required this.taskers,
    this.onTaskerTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(); // This will be integrated into the map widget
  }

  List<Marker> buildTaskerMarkers() {
    return taskers.map((tasker) {
      final latLng = _getTaskerLocation(tasker);
      
      return Marker(
        point: latLng,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => onTaskerTap?.call(tasker),
          child: _buildTaskerMarker(tasker),
        ),
      );
    }).toList();
  }

  LatLng _getTaskerLocation(Profile tasker) {
    // TODO: Implement proper geocoding for tasker location
    // For now, generate random positions around Kuala Lumpur area
    final random = tasker.id.hashCode % 1000;
    final lat = 3.139 + (random % 200) * 0.001 - 0.1; // Wider area around KL
    final lng = 101.687 + (random % 200) * 0.001 - 0.1;
    return LatLng(lat, lng);
  }

  Widget _buildTaskerMarker(Profile tasker) {
    return Container(
      width: 30.19,
      height: 30.19,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFDFDF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Profile image or avatar
          Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF0F0F0),
                image: tasker.profileImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(tasker.profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: tasker.profileImageUrl == null
                  ? const Icon(
                      Icons.person,
                      size: 16,
                      color: Color(0xFF666666),
                    )
                  : null,
            ),
          ),
          // Flag indicators (representing user location/nationality)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1D1A69), // Malaysia flag blue
              ),
              child: const Icon(
                Icons.flag,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}