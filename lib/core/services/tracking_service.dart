import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Provider for TrackingService
/// This service manages App Tracking Transparency (ATT) for iOS
final trackingServiceProvider = Provider<TrackingService>((ref) {
  return TrackingService();
});

/// TrackingService handles App Tracking Transparency (ATT) on iOS
///
/// Apple requires apps to request permission before tracking users across
/// apps and websites owned by other companies. This service:
/// - Requests ATT permission on iOS devices
/// - Manages tracking authorization status
/// - Integrates with Firebase Analytics consent mode
/// - No-ops gracefully on Android and Web platforms
///
/// Reference: https://developer.apple.com/documentation/apptrackingtransparency
class TrackingService {
  final Logger _logger = Logger();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Request App Tracking Transparency permission on iOS
  ///
  /// This method should be called after the app is fully initialized and
  /// the user has had a chance to understand the value of the app.
  ///
  /// Best practices:
  /// - Call this AFTER Firebase initialization
  /// - Call this AFTER user sees the main app screen
  /// - Don't call on first app launch immediately
  /// - Provide context to users about why tracking is needed
  ///
  /// Returns the authorization status after the request
  Future<TrackingStatus> requestTrackingAuthorization() async {
    // Only request on iOS platform
    if (!Platform.isIOS) {
      _logger.i('[ATT] Not on iOS platform, skipping ATT request');
      return TrackingStatus.notSupported;
    }

    try {
      // First check if we can request tracking
      // This returns 'notDetermined' if we haven't asked yet
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      _logger.i('[ATT] Current tracking status: $status');

      // Only request if status is notDetermined
      // If user has already made a choice, respect it
      if (status == TrackingStatus.notDetermined) {
        _logger.i('[ATT] Requesting tracking authorization...');

        // Request the authorization
        final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
        _logger.i('[ATT] User response: $newStatus');

        // Update Firebase Analytics consent based on response
        await _updateAnalyticsConsent(newStatus);

        return newStatus;
      } else {
        _logger.i('[ATT] Tracking status already determined: $status');
        // Update analytics consent with current status
        await _updateAnalyticsConsent(status);
        return status;
      }
    } catch (e, stackTrace) {
      _logger.e('[ATT] Error requesting tracking authorization', error: e, stackTrace: stackTrace);
      // On error, assume tracking is not authorized
      await _updateAnalyticsConsent(TrackingStatus.denied);
      return TrackingStatus.denied;
    }
  }

  /// Get the current tracking authorization status
  ///
  /// Possible values:
  /// - authorized: User has granted permission to track
  /// - denied: User has explicitly denied permission
  /// - restricted: Tracking is restricted (parental controls, etc.)
  /// - notDetermined: User hasn't been asked yet
  /// - notSupported: Platform doesn't support ATT (Android/Web)
  Future<TrackingStatus> getTrackingStatus() async {
    if (!Platform.isIOS) {
      return TrackingStatus.notSupported;
    }

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      _logger.i('[ATT] Current tracking status: $status');
      return status;
    } catch (e) {
      _logger.e('[ATT] Error getting tracking status', error: e);
      return TrackingStatus.notDetermined;
    }
  }

  /// Get the device's advertising identifier (IDFA)
  ///
  /// This is only available if user has authorized tracking.
  /// Returns null if tracking is not authorized or on non-iOS platforms.
  Future<String?> getAdvertisingIdentifier() async {
    if (!Platform.isIOS) {
      _logger.i('[ATT] IDFA not available on non-iOS platforms');
      return null;
    }

    try {
      final status = await getTrackingStatus();

      if (status == TrackingStatus.authorized) {
        final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
        _logger.i('[ATT] IDFA obtained: ${idfa.substring(0, 8)}...');
        return idfa;
      } else {
        _logger.i('[ATT] Cannot get IDFA - tracking not authorized: $status');
        return null;
      }
    } catch (e) {
      _logger.e('[ATT] Error getting advertising identifier', error: e);
      return null;
    }
  }

  /// Update Firebase Analytics consent based on tracking authorization
  ///
  /// This ensures Firebase Analytics respects the user's tracking preference.
  /// When tracking is denied, Firebase Analytics will:
  /// - Not collect IDFA
  /// - Not send data to Google for remarketing
  /// - Still collect anonymous analytics data
  ///
  /// Note: Using available consent parameters based on firebase_analytics version 11.3.0
  Future<void> _updateAnalyticsConsent(TrackingStatus status) async {
    try {
      switch (status) {
        case TrackingStatus.authorized:
          // User authorized tracking - enable full analytics
          await _analytics.setConsent(
            analyticsStorageConsentGranted: true,
            adStorageConsentGranted: true,
            adUserDataConsentGranted: true,
          );
          _logger.i('[ATT] Firebase Analytics: Full consent granted');
          break;

        case TrackingStatus.denied:
        case TrackingStatus.restricted:
          // User denied or restricted - disable ad tracking but keep analytics
          await _analytics.setConsent(
            analyticsStorageConsentGranted: true, // Keep basic analytics
            adStorageConsentGranted: false, // Disable ad tracking
            adUserDataConsentGranted: false, // Disable user data for ads
          );
          _logger.i('[ATT] Firebase Analytics: Limited consent (analytics only)');
          break;

        case TrackingStatus.notDetermined:
          // Not yet determined - use conservative defaults
          await _analytics.setConsent(
            analyticsStorageConsentGranted: true,
            adStorageConsentGranted: false,
            adUserDataConsentGranted: false,
          );
          _logger.i('[ATT] Firebase Analytics: Default consent (conservative)');
          break;

        case TrackingStatus.notSupported:
          // Not supported (Android/Web) - enable all analytics
          await _analytics.setConsent(
            analyticsStorageConsentGranted: true,
            adStorageConsentGranted: true,
            adUserDataConsentGranted: true,
          );
          _logger.i('[ATT] Firebase Analytics: Full consent (platform not iOS)');
          break;
      }
    } catch (e) {
      _logger.e('[ATT] Error updating analytics consent', error: e);
    }
  }

  /// Check if tracking is authorized
  ///
  /// Convenience method to quickly check if tracking is allowed.
  /// Returns true only if explicitly authorized on iOS, or on non-iOS platforms.
  Future<bool> isTrackingAuthorized() async {
    if (!Platform.isIOS) {
      return true; // Android/Web don't require ATT
    }

    final status = await getTrackingStatus();
    return status == TrackingStatus.authorized;
  }

  /// Initialize tracking service and request permission if needed
  ///
  /// This is a convenience method that:
  /// 1. Checks current tracking status
  /// 2. Updates analytics consent accordingly
  /// 3. Optionally requests permission if not yet determined
  ///
  /// Use this during app initialization, but AFTER:
  /// - Firebase has been initialized
  /// - User has seen the main app screen
  /// - User understands the value of the app
  ///
  /// @param requestIfNeeded: If true, will request permission if not yet determined
  Future<TrackingStatus> initialize({bool requestIfNeeded = false}) async {
    _logger.i('[ATT] Initializing tracking service...');

    if (!Platform.isIOS) {
      _logger.i('[ATT] Not on iOS, no ATT required');
      return TrackingStatus.notSupported;
    }

    try {
      // Get current status
      final status = await getTrackingStatus();

      // Update analytics consent based on current status
      await _updateAnalyticsConsent(status);

      // Request permission if needed and requested
      if (requestIfNeeded && status == TrackingStatus.notDetermined) {
        _logger.i('[ATT] Requesting tracking authorization...');
        return await requestTrackingAuthorization();
      }

      return status;
    } catch (e) {
      _logger.e('[ATT] Error initializing tracking service', error: e);
      return TrackingStatus.denied;
    }
  }
}

/* =============================================================================
 * GEOFENCING STRATEGY NOTES
 * =============================================================================
 *
 * For location-based notifications in Taskaway, we use a "When In Use"
 * permission strategy instead of "Always Allow" for better user privacy
 * and App Store compliance.
 *
 * APPROACH:
 * --------
 * 1. Request "When In Use" location permission (not "Always Allow")
 * 2. Use background fetch/silent push notifications to wake the app
 * 3. When app wakes, check user's location against task locations
 * 4. Send local notification if user is near a relevant task
 *
 * IMPLEMENTATION:
 * --------------
 * - Use geolocator package (already in pubspec.yaml) for location services
 * - Use firebase_messaging for background fetch/silent push
 * - Use flutter_local_notifications for displaying geofence notifications
 *
 * CODE EXAMPLE:
 * ------------
 * ```dart
 * // In location_service.dart:
 *
 * // Check if user is near a task location
 * Future<bool> isNearLocation(double taskLat, double taskLng, double radiusMeters) async {
 *   // Get current position with "When In Use" permission
 *   final position = await Geolocator.getCurrentPosition(
 *     desiredAccuracy: LocationAccuracy.medium,
 *   );
 *
 *   // Calculate distance using geolocator's distanceBetween
 *   final distance = Geolocator.distanceBetween(
 *     position.latitude,
 *     position.longitude,
 *     taskLat,
 *     taskLng,
 *   );
 *
 *   return distance <= radiusMeters;
 * }
 *
 * // In fcm_service.dart background handler:
 *
 * @pragma('vm:entry-point')
 * Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
 *   // Handle background message
 *   if (message.data['type'] == 'location_check') {
 *     // Wake up and check location
 *     final locationService = LocationService();
 *     final taskLat = double.parse(message.data['task_lat']);
 *     final taskLng = double.parse(message.data['task_lng']);
 *
 *     if (await locationService.isNearLocation(taskLat, taskLng, 1000)) {
 *       // User is within 1km of task - show local notification
 *       await _showGeofenceNotification(message.data);
 *     }
 *   }
 * }
 * ```
 *
 * BACKEND STRATEGY:
 * ----------------
 * 1. Store user's last known location when they use the app
 * 2. When new tasks are posted, calculate which users might be nearby
 * 3. Send silent push notification to those users
 * 4. App wakes up, checks actual current location, shows notification if near
 *
 * BENEFITS:
 * --------
 * - Respects user privacy (no "Always Allow" permission needed)
 * - Better battery life (location checked only when needed)
 * - App Store compliant (doesn't require background location)
 * - Users more likely to grant "When In Use" permission
 *
 * LIMITATIONS:
 * -----------
 * - Not real-time geofencing (relies on silent push timing)
 * - Requires network connectivity for silent push
 * - iOS limits background notification frequency
 * - Location check only happens when app receives silent push
 *
 * TESTING:
 * -------
 * - Test "When In Use" permission flow
 * - Test silent push notifications waking the app
 * - Test location check triggering local notification
 * - Test with various iOS background app refresh settings
 * - Test battery impact over extended periods
 *
 * PRIVACY NOTES:
 * -------------
 * - Always explain to users why location is needed
 * - Only request location when user actively uses location features
 * - Store location data securely and minimally
 * - Provide clear opt-out mechanisms
 * - Update privacy policy to reflect location usage
 *
 * =============================================================================
 */
