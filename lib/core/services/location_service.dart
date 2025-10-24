import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

/// Service to handle location tracking for taskers
/// Updates location every 30 minutes when tasker is available
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _locationTimer;
  bool _isTracking = false;
  String? _userId;

  final _supabase = Supabase.instance.client;

  /// Start tracking location for the given user
  /// Updates location immediately and then every 30 minutes
  Future<void> startTracking(String userId) async {
    if (_isTracking && _userId == userId) {
      dev.log('[LocationService] Already tracking for user: $userId');
      return;
    }

    dev.log('[LocationService] Starting location tracking for user: $userId');
    _userId = userId;
    _isTracking = true;

    // Update location immediately
    await _updateLocation();

    // Set up periodic updates every 30 minutes
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _updateLocation(),
    );
  }

  /// Stop tracking location
  void stopTracking() {
    dev.log('[LocationService] Stopping location tracking');
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
    _userId = null;
  }

  /// Check if location services are enabled and permissions are granted
  Future<bool> checkPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      dev.log('[LocationService] Location services are disabled');
      return false;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        dev.log('[LocationService] Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      dev.log('[LocationService] Location permissions are permanently denied');
      return false;
    }

    dev.log('[LocationService] Location permissions granted');
    return true;
  }

  /// Request location permissions
  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      dev.log('[LocationService] Location services are disabled');
      // Optionally open location settings
      // await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        dev.log('[LocationService] Location permissions denied by user');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      dev.log('[LocationService] Location permissions permanently denied');
      // Optionally open app settings
      // await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  /// Update the user's location in the database
  Future<void> _updateLocation() async {
    if (_userId == null) {
      dev.log('[LocationService] No user ID set, skipping location update');
      return;
    }

    try {
      // Check permissions first
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        dev.log('[LocationService] No location permission, stopping tracking');
        stopTracking();
        return;
      }

      dev.log('[LocationService] Getting current position...');

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      dev.log('[LocationService] Got position: ${position.latitude}, ${position.longitude}');

      // Update in database
      await _supabase
          .from('taskaway_profiles')
          .update({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _userId!);

      dev.log('[LocationService] Location updated successfully');
    } catch (e, st) {
      dev.log('[LocationService] Error updating location: $e\n$st');
    }
  }

  /// Get current location without updating database
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      dev.log('[LocationService] Error getting current location: $e');
      return null;
    }
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Get the user ID being tracked
  String? get trackingUserId => _userId;

  /// Dispose the service
  void dispose() {
    stopTracking();
  }
}
