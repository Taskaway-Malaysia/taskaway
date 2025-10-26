import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(supabase: Supabase.instance.client);
});

class ProfileRepository {
  final SupabaseClient supabase;
  final Logger _logger = Logger();

  ProfileRepository({required this.supabase});

  /// Update FCM token for a user
  /// This should be called when the app starts and when the token refreshes
  Future<bool> updateFCMToken(String userId, String token) async {
    try {
      await supabase.from('taskaway_profiles').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      _logger.i('Profile: FCM token updated for user $userId');
      return true;
    } catch (e) {
      _logger.e('Profile: Error updating FCM token', error: e);
      return false;
    }
  }

  /// Remove FCM token for a user (useful when logging out)
  Future<bool> removeFCMToken(String userId) async {
    try {
      await supabase.from('taskaway_profiles').update({
        'fcm_token': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      _logger.i('Profile: FCM token removed for user $userId');
      return true;
    } catch (e) {
      _logger.e('Profile: Error removing FCM token', error: e);
      return false;
    }
  }

  /// Update notification settings for a user
  Future<bool> updateNotificationSettings(String userId, bool enabled) async {
    try {
      await supabase.from('taskaway_profiles').update({
        'notifications_enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      _logger.i('Profile: Notifications ${enabled ? 'enabled' : 'disabled'} for user $userId');
      return true;
    } catch (e) {
      _logger.e('Profile: Error updating notification settings', error: e);
      return false;
    }
  }

  /// Update last seen timestamp for a user
  /// This should be called periodically while the app is active
  Future<bool> updateLastSeen(String userId) async {
    try {
      await supabase.from('taskaway_profiles').update({
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      _logger.i('Profile: Last seen updated for user $userId');
      return true;
    } catch (e) {
      _logger.e('Profile: Error updating last seen', error: e);
      return false;
    }
  }

  /// Get notification settings for a user
  Future<bool?> getNotificationSettings(String userId) async {
    try {
      final response = await supabase
          .from('taskaway_profiles')
          .select('notifications_enabled')
          .eq('id', userId)
          .single();

      final enabled = response['notifications_enabled'] as bool?;
      _logger.i('Profile: Notification settings retrieved for user $userId - enabled: $enabled');
      return enabled ?? true; // Default to true if not set
    } catch (e) {
      _logger.e('Profile: Error getting notification settings', error: e);
      return null;
    }
  }

  /// Update profile with FCM token, notification settings, and last seen
  /// Useful for bulk update during login
  Future<bool> updateProfileWithNotificationData({
    required String userId,
    String? fcmToken,
    bool? notificationsEnabled,
    bool updateLastSeen = true,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fcmToken != null) {
        updates['fcm_token'] = fcmToken;
      }

      if (notificationsEnabled != null) {
        updates['notifications_enabled'] = notificationsEnabled;
      }

      if (updateLastSeen) {
        updates['last_seen'] = DateTime.now().toIso8601String();
      }

      await supabase.from('taskaway_profiles').update(updates).eq('id', userId);

      _logger.i('Profile: Notification data updated for user $userId');
      return true;
    } catch (e) {
      _logger.e('Profile: Error updating profile with notification data', error: e);
      return false;
    }
  }

  /// Get users within a radius (in km) of a location who have notifications enabled
  /// This is useful for finding users to notify about new tasks
  Future<List<Profile>> getNearbyUsersWithNotifications({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? excludeUserId, // Exclude the task poster
  }) async {
    try {
      // Use Haversine formula to calculate distance
      // This query finds users within the radius who:
      // 1. Have notifications enabled
      // 2. Are available (is_available = true)
      // 3. Have an FCM token (to receive push notifications)
      // 4. Are not the excluded user (task poster)

      final response = await supabase.rpc(
        'get_nearby_users',
        params: {
          'user_lat': latitude,
          'user_lng': longitude,
          'radius_km': radiusKm,
          'exclude_user_id': excludeUserId,
        },
      );

      final List<Profile> users = [];
      for (final data in response) {
        try {
          users.add(Profile.fromJson(data));
        } catch (e) {
          _logger.e('Profile: Error parsing profile from nearby users', error: e);
        }
      }

      _logger.i('Profile: Found ${users.length} nearby users with notifications enabled');
      return users;
    } catch (e) {
      _logger.e('Profile: Error getting nearby users', error: e);
      return [];
    }
  }

  /// Get all users with FCM tokens and notifications enabled
  /// Useful for broadcast notifications (if needed in the future)
  Future<List<String>> getAllFCMTokens({bool onlineOnly = false}) async {
    try {
      var query = supabase
          .from('taskaway_profiles')
          .select('fcm_token')
          .eq('notifications_enabled', true)
          .not('fcm_token', 'is', null);

      if (onlineOnly) {
        // Consider users online if they were active in the last 5 minutes
        final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
        query = query.gte('last_seen', fiveMinutesAgo);
      }

      final response = await query;

      final List<String> tokens = [];
      for (final row in response) {
        final token = row['fcm_token'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      _logger.i('Profile: Retrieved ${tokens.length} FCM tokens (onlineOnly: $onlineOnly)');
      return tokens;
    } catch (e) {
      _logger.e('Profile: Error getting FCM tokens', error: e);
      return [];
    }
  }
}
