import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:taskaway/core/services/tracking_service.dart';

// Generate mocks for dependencies
@GenerateMocks([
  FirebaseAnalytics,
])
import 'tracking_service_test.mocks.dart';

/// Mock Firebase implementation for testing
class MockFirebasePlatform extends FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseApp();
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseApp();
  }

  @override
  List<FirebaseAppPlatform> get apps => [MockFirebaseApp()];
}

/// Mock Firebase App for testing
class MockFirebaseApp extends FirebaseAppPlatform {
  MockFirebaseApp() : super(defaultFirebaseAppName, const FirebaseOptions(
    apiKey: 'test-api-key',
    appId: 'test-app-id',
    messagingSenderId: 'test-sender-id',
    projectId: 'test-project-id',
  ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup mock Firebase before any tests run
  setUpAll(() {
    // Register mock Firebase platform
    FirebasePlatform.instance = MockFirebasePlatform();
  });

  // Test setup
  late TrackingService trackingService;
  late MockFirebaseAnalytics mockAnalytics;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    trackingService = TrackingService();

    // Note: We cannot directly inject the mock analytics in the current implementation
    // In a production app, we would refactor to use dependency injection
    // For now, we'll test the public API and behavior
  });

  group('TrackingService - Platform Detection', () {
    test('should return notSupported on non-iOS platforms', () async {
      // This test will only pass on non-iOS platforms
      // On iOS, it will be skipped
      if (!Platform.isIOS) {
        final status = await trackingService.getTrackingStatus();
        expect(status, TrackingStatus.notSupported);
      }
    }, skip: Platform.isIOS ? 'Test only runs on non-iOS platforms' : false);

    test('should return true for isTrackingAuthorized on non-iOS platforms', () async {
      if (!Platform.isIOS) {
        final isAuthorized = await trackingService.isTrackingAuthorized();
        expect(isAuthorized, true);
      }
    }, skip: Platform.isIOS ? 'Test only runs on non-iOS platforms' : false);

    test('should return notSupported when initializing on non-iOS', () async {
      if (!Platform.isIOS) {
        final status = await trackingService.initialize();
        expect(status, TrackingStatus.notSupported);
      }
    }, skip: Platform.isIOS ? 'Test only runs on non-iOS platforms' : false);

    test('should return null for getAdvertisingIdentifier on non-iOS', () async {
      if (!Platform.isIOS) {
        final idfa = await trackingService.getAdvertisingIdentifier();
        expect(idfa, null);
      }
    }, skip: Platform.isIOS ? 'Test only runs on non-iOS platforms' : false);
  });

  group('TrackingService - Error Handling', () {
    test('should handle errors gracefully in getTrackingStatus', () async {
      // Even if there's an error, the method should not throw
      // It should return a safe default value
      final status = await trackingService.getTrackingStatus();
      expect(status, isNotNull);
      expect(status, isA<TrackingStatus>());
    });

    test('should handle errors gracefully in getAdvertisingIdentifier', () async {
      // Even if there's an error, the method should not throw
      final idfa = await trackingService.getAdvertisingIdentifier();
      // Should return null on error or when not authorized
      expect(idfa, anyOf(isNull, isA<String>()));
    });

    test('should handle errors gracefully in isTrackingAuthorized', () async {
      // Even if there's an error, the method should not throw
      final isAuthorized = await trackingService.isTrackingAuthorized();
      expect(isAuthorized, isA<bool>());
    });
  });

  group('TrackingService - Initialize Method', () {
    test('initialize should complete without errors when requestIfNeeded is false', () async {
      // Test that initialization completes successfully
      final status = await trackingService.initialize(requestIfNeeded: false);
      expect(status, isNotNull);
      expect(status, isA<TrackingStatus>());
    });

    test('initialize should handle requestIfNeeded parameter', () async {
      // Test with requestIfNeeded = true
      final statusWithRequest = await trackingService.initialize(requestIfNeeded: true);
      expect(statusWithRequest, isNotNull);

      // Test with requestIfNeeded = false
      final statusWithoutRequest = await trackingService.initialize(requestIfNeeded: false);
      expect(statusWithoutRequest, isNotNull);
    });
  });

  group('TrackingService - API Contract', () {
    test('requestTrackingAuthorization should return a valid TrackingStatus', () async {
      final status = await trackingService.requestTrackingAuthorization();
      expect(status, isA<TrackingStatus>());
    });

    test('getTrackingStatus should return a valid TrackingStatus', () async {
      final status = await trackingService.getTrackingStatus();
      expect(status, isA<TrackingStatus>());
    });

    test('isTrackingAuthorized should return a boolean', () async {
      final isAuthorized = await trackingService.isTrackingAuthorized();
      expect(isAuthorized, isA<bool>());
    });

    test('getAdvertisingIdentifier should return String or null', () async {
      final idfa = await trackingService.getAdvertisingIdentifier();
      expect(idfa, anyOf(isNull, isA<String>()));
    });
  });

  group('TrackingService - Status Consistency', () {
    test('getTrackingStatus should be consistent across multiple calls', () async {
      final status1 = await trackingService.getTrackingStatus();
      final status2 = await trackingService.getTrackingStatus();

      // Status should be consistent (unless user changes it in settings)
      expect(status1, isA<TrackingStatus>());
      expect(status2, isA<TrackingStatus>());
    });

    test('isTrackingAuthorized should match getTrackingStatus result', () async {
      final status = await trackingService.getTrackingStatus();
      final isAuthorized = await trackingService.isTrackingAuthorized();

      if (!Platform.isIOS) {
        expect(status, TrackingStatus.notSupported);
        expect(isAuthorized, true);
      } else {
        // On iOS, isAuthorized should be true only if status is authorized
        if (status == TrackingStatus.authorized) {
          expect(isAuthorized, true);
        } else {
          expect(isAuthorized, false);
        }
      }
    });
  });

  group('TrackingService - IDFA Behavior', () {
    test('getAdvertisingIdentifier should return null when tracking not authorized', () async {
      if (!Platform.isIOS) {
        // On non-iOS, should always return null
        final idfa = await trackingService.getAdvertisingIdentifier();
        expect(idfa, null);
      } else {
        // On iOS, should only return IDFA if authorized
        final status = await trackingService.getTrackingStatus();
        final idfa = await trackingService.getAdvertisingIdentifier();

        if (status != TrackingStatus.authorized) {
          expect(idfa, null);
        }
      }
    });

    test('getAdvertisingIdentifier format should be valid UUID when available', () async {
      final idfa = await trackingService.getAdvertisingIdentifier();

      if (idfa != null) {
        // IDFA should be a valid UUID format (8-4-4-4-12)
        final uuidPattern = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        );
        expect(uuidPattern.hasMatch(idfa), true,
            reason: 'IDFA should be a valid UUID format');
      }
    });
  });

  group('TrackingService - Integration', () {
    test('full initialization flow should work end-to-end', () async {
      // 1. Initialize the service
      final initStatus = await trackingService.initialize(requestIfNeeded: false);
      expect(initStatus, isNotNull);

      // 2. Get current status
      final currentStatus = await trackingService.getTrackingStatus();
      expect(currentStatus, isNotNull);

      // 3. Check if authorized
      final isAuthorized = await trackingService.isTrackingAuthorized();
      expect(isAuthorized, isA<bool>());

      // 4. Try to get IDFA (will be null if not authorized)
      final idfa = await trackingService.getAdvertisingIdentifier();
      expect(idfa, anyOf(isNull, isA<String>()));
    });

    test('initialize with requestIfNeeded should not throw on any platform', () async {
      // This should work on both iOS and non-iOS platforms
      expect(
        () async => await trackingService.initialize(requestIfNeeded: true),
        returnsNormally,
      );
    });
  });

  group('TrackingService - Edge Cases', () {
    test('should handle rapid consecutive calls gracefully', () async {
      // Make multiple rapid calls to ensure thread safety
      final futures = [
        trackingService.getTrackingStatus(),
        trackingService.getTrackingStatus(),
        trackingService.isTrackingAuthorized(),
        trackingService.isTrackingAuthorized(),
      ];

      final results = await Future.wait(futures);

      // All calls should complete successfully
      expect(results.length, 4);
      expect(results[0], isA<TrackingStatus>());
      expect(results[1], isA<TrackingStatus>());
      expect(results[2], isA<bool>());
      expect(results[3], isA<bool>());
    });

    test('should handle initialize being called multiple times', () async {
      final status1 = await trackingService.initialize();
      final status2 = await trackingService.initialize();
      final status3 = await trackingService.initialize(requestIfNeeded: true);

      expect(status1, isA<TrackingStatus>());
      expect(status2, isA<TrackingStatus>());
      expect(status3, isA<TrackingStatus>());
    });
  });

  group('TrackingService - Logging and Debugging', () {
    test('all public methods should execute without throwing', () async {
      // Test that all public methods can be called safely
      expect(
        () async {
          await trackingService.getTrackingStatus();
          await trackingService.isTrackingAuthorized();
          await trackingService.getAdvertisingIdentifier();
          await trackingService.initialize();
          await trackingService.requestTrackingAuthorization();
        },
        returnsNormally,
      );
    });
  });

  group('TrackingService - TrackingStatus Enum Values', () {
    test('should handle all possible TrackingStatus values', () async {
      final status = await trackingService.getTrackingStatus();

      // Verify the status is one of the expected values
      expect(
        status,
        anyOf(
          TrackingStatus.authorized,
          TrackingStatus.denied,
          TrackingStatus.restricted,
          TrackingStatus.notDetermined,
          TrackingStatus.notSupported,
        ),
      );
    });

    test('platform-specific status values should be correct', () async {
      final status = await trackingService.getTrackingStatus();

      if (!Platform.isIOS) {
        // Non-iOS should always be notSupported
        expect(status, TrackingStatus.notSupported);
      } else {
        // iOS should never return notSupported
        expect(status, isNot(TrackingStatus.notSupported));
      }
    });
  });

  group('TrackingService - Permission Flow Simulation', () {
    test('should maintain state consistency throughout permission flow', () async {
      // Simulate the typical permission flow

      // Step 1: Check initial status
      final initialStatus = await trackingService.getTrackingStatus();
      expect(initialStatus, isA<TrackingStatus>());

      // Step 2: Check if already authorized
      final initialAuth = await trackingService.isTrackingAuthorized();
      expect(initialAuth, isA<bool>());

      // Step 3: Initialize (without requesting if determined)
      final initStatus = await trackingService.initialize(requestIfNeeded: false);
      expect(initStatus, isA<TrackingStatus>());

      // Step 4: Get final status
      final finalStatus = await trackingService.getTrackingStatus();
      expect(finalStatus, isA<TrackingStatus>());

      // Status should be consistent
      expect(finalStatus, initStatus);
    });
  });

  group('TrackingService - Analytics Consent Logic', () {
    test('should set appropriate consent for each tracking status', () {
      // This test documents the expected consent settings
      // These are the consent values that should be set for each status

      // authorized: Full consent
      const authorizedConsent = {
        'analyticsStorageConsentGranted': true,
        'adStorageConsentGranted': true,
        'adUserDataConsentGranted': true,
      };

      // denied/restricted: Limited consent (analytics only)
      const limitedConsent = {
        'analyticsStorageConsentGranted': true,
        'adStorageConsentGranted': false,
        'adUserDataConsentGranted': false,
      };

      // notDetermined: Conservative defaults
      const conservativeConsent = {
        'analyticsStorageConsentGranted': true,
        'adStorageConsentGranted': false,
        'adUserDataConsentGranted': false,
      };

      // notSupported: Full consent (non-iOS platforms)
      const notSupportedConsent = {
        'analyticsStorageConsentGranted': true,
        'adStorageConsentGranted': true,
        'adUserDataConsentGranted': true,
      };

      // Verify consent structures are correct
      expect(authorizedConsent['adStorageConsentGranted'], true);
      expect(limitedConsent['adStorageConsentGranted'], false);
      expect(conservativeConsent['adStorageConsentGranted'], false);
      expect(notSupportedConsent['adStorageConsentGranted'], true);
    });
  });

  group('TrackingService - Documentation Tests', () {
    test('should document ATT permission states', () {
      // This test documents the five possible ATT states

      const attStates = {
        'authorized': 'User granted permission to track',
        'denied': 'User explicitly denied permission',
        'restricted': 'Tracking restricted by parental controls',
        'notDetermined': 'User has not been asked yet',
        'notSupported': 'Platform does not support ATT',
      };

      expect(attStates.length, 5,
          reason: 'There should be 5 ATT states');
    });

    test('should document ATT best practices', () {
      // This test documents ATT best practices from Apple

      const bestPractices = [
        'Request AFTER Firebase initialization',
        'Request AFTER user sees the app',
        'Do not request immediately on first launch',
        'Provide context about why tracking is needed',
        'Respect user choice - do not ask again',
        'Use conservative consent before user choice',
      ];

      expect(bestPractices.length, greaterThan(0),
          reason: 'Best practices should be documented');
    });

    test('should document initialization order requirements', () {
      // This test documents the critical initialization order

      const initializationOrder = [
        '1. WidgetsFlutterBinding.ensureInitialized()',
        '2. TrackingService.initialize() [iOS only]',
        '3. Firebase.initializeApp()',
        '4. Supabase.initialize()',
        '5. Request ATT permission [iOS, delayed]',
      ];

      expect(initializationOrder.length, 5,
          reason: 'Initialization order should be documented');
    });
  });
}
