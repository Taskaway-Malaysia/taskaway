import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/features/auth/models/profile.dart';
import 'dart:developer' as dev;
import 'dart:math' show cos, sqrt, asin;

/// TaskerRepository
///
/// Handles data operations related to taskers including:
/// - Fetching available taskers near a location
/// - Filtering by category/skills
/// - Managing task acceptance
class TaskerRepository {
  final SupabaseClient _supabase;

  TaskerRepository(this._supabase);

  /// Get available users near a specific location
  ///
  /// Filters users by:
  /// - isAvailable = true
  /// - Skills matching task category
  /// - Within specified radius (using Haversine formula)
  Future<List<Profile>> getAvailableTaskers({
    required String category,
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      dev.log('[TaskerRepository] Fetching available users for category: $category near ($latitude, $longitude)');

      // Query all available users with location data (anyone can accept tasks)
      final response = await _supabase
          .from('taskaway_profiles')
          .select()
          .eq('is_available', true)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      if (response == null || response.isEmpty) {
        dev.log('[TaskerRepository] No taskers found');
        return [];
      }

      // Parse profiles
      final allTaskers = (response as List)
          .map((json) => Profile.fromJson(json as Map<String, dynamic>))
          .toList();

      dev.log('[TaskerRepository] Found ${allTaskers.length} total taskers');

      // Filter by distance and category
      final nearbyTaskers = allTaskers.where((tasker) {
        // Check distance
        final distance = _calculateDistance(
          latitude,
          longitude,
          tasker.latitude!,
          tasker.longitude!,
        );

        if (distance > radiusKm) {
          return false;
        }

        // Check skills match category (case-insensitive)
        if (tasker.skills != null && tasker.skills!.isNotEmpty) {
          final categoryLower = category.toLowerCase();
          return tasker.skills!.any(
            (skill) => skill.toLowerCase().contains(categoryLower) ||
                categoryLower.contains(skill.toLowerCase()),
          );
        }

        // If no skills specified, include the tasker
        return true;
      }).toList();

      // Sort by distance
      nearbyTaskers.sort((a, b) {
        final distA = _calculateDistance(latitude, longitude, a.latitude!, a.longitude!);
        final distB = _calculateDistance(latitude, longitude, b.latitude!, b.longitude!);
        return distA.compareTo(distB);
      });

      dev.log('[TaskerRepository] Filtered to ${nearbyTaskers.length} nearby taskers');
      return nearbyTaskers;
    } catch (e, st) {
      dev.log('[TaskerRepository] Error fetching available taskers: $e\n$st');
      rethrow;
    }
  }

  /// Accept a task (called by tasker)
  ///
  /// Updates task status to 'accepted' and sets tasker_id
  Future<void> acceptTask({
    required String taskId,
    required String taskerId,
  }) async {
    try {
      dev.log('[TaskerRepository] Tasker $taskerId accepting task $taskId');

      await _supabase
          .from('taskaway_tasks')
          .update({
            'status': 'accepted',
            'tasker_id': taskerId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId);

      dev.log('[TaskerRepository] Task accepted successfully');
    } catch (e, st) {
      dev.log('[TaskerRepository] Error accepting task: $e\n$st');
      rethrow;
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    // Convert to radians
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2));

    final c = 2 * asin(sqrt(a));

    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Helper for accessing pi constant
  static const double pi = 3.141592653589793;

  // Helper for sin calculation
  double sin(double radians) {
    return _taylorSin(radians);
  }

  // Taylor series approximation for sin
  double _taylorSin(double x) {
    // Normalize to -π to π
    while (x > pi) x -= 2 * pi;
    while (x < -pi) x += 2 * pi;

    double result = x;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }
}
