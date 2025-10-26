import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('[FCM] Background message received: ${message.messageId}');
  print('[FCM] Background notification: ${message.notification?.title}');
}

final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  // Callback for when a notification is tapped
  Function(RemoteMessage)? onNotificationTapped;

  // Stream controller for notification events
  final _notificationStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get notificationStream => _notificationStreamController.stream;

  /// Initialize FCM service
  /// This should be called early in the app lifecycle (in main.dart)
  Future<void> initialize({Function(RemoteMessage)? onTap}) async {
    try {
      onNotificationTapped = onTap;

      // Request permissions (iOS and Android 13+)
      await requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure foreground notification presentation options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps (when app is in background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state via notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_handleTokenRefresh);

      _logger.i('FCM: Service initialized successfully');
    } catch (e) {
      _logger.e('FCM: Error initializing service', error: e);
    }
  }

  /// Initialize local notifications plugin for Android/iOS
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize with callback for when notification is tapped
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _logger.i('FCM: Local notification tapped - ${response.payload}');
          // Handle local notification tap if needed
        },
      );

      // Create notification channel for Android
      if (!kIsWeb && Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'taskaway_notifications', // id
          'Taskaway Notifications', // name
          description: 'Notifications for new tasks and updates',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      _logger.i('FCM: Local notifications initialized');
    } catch (e) {
      _logger.e('FCM: Error initializing local notifications', error: e);
    }
  }

  /// Request notification permissions
  /// For Android 13+, this uses permission_handler to request POST_NOTIFICATIONS
  /// For iOS, this uses FirebaseMessaging.requestPermission()
  Future<NotificationSettings> requestPermission() async {
    try {
      // Android-specific permission handling (Android 13+)
      if (!kIsWeb && Platform.isAndroid) {
        _logger.i('FCM: Requesting Android notification permission');

        // Request POST_NOTIFICATIONS permission for Android 13+
        final status = await Permission.notification.request();

        _logger.i('FCM: Android permission status - $status');

        if (status.isGranted) {
          _logger.i('FCM: Android notification permission granted');
        } else if (status.isDenied) {
          _logger.w('FCM: Android notification permission denied');
        } else if (status.isPermanentlyDenied) {
          _logger.e('FCM: Android notification permission permanently denied');
          // User needs to go to app settings to enable permissions
        }
      }

      // Request Firebase Messaging permissions (primarily for iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _logger.i('FCM: Firebase permission status - ${settings.authorizationStatus}');
      return settings;
    } catch (e) {
      _logger.e('FCM: Error requesting permission', error: e);
      rethrow;
    }
  }

  /// Get FCM token for this device
  /// On iOS, this will first ensure APNS token is available before requesting FCM token
  Future<String?> getToken() async {
    try {
      // On iOS, we need to ensure APNS token is available first
      if (!kIsWeb && Platform.isIOS) {
        _logger.i('FCM: Getting APNS token first (iOS requirement)');

        // Try to get APNS token with retries
        String? apnsToken;
        for (int i = 0; i < 3; i++) {
          apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            _logger.i('FCM: APNS token retrieved');
            break;
          }
          _logger.w('FCM: APNS token not available yet, retrying... (${i + 1}/3)');
          await Future.delayed(Duration(seconds: 1));
        }

        if (apnsToken == null) {
          _logger.w('FCM: APNS token still null after retries - FCM token may fail');
        }
      }

      // Now get FCM token
      final token = await _firebaseMessaging.getToken();

      if (token == null) {
        _logger.w('FCM: Token is null - may be running on iOS simulator or device not configured');
      } else {
        _logger.i('FCM: Token retrieved - ${token.substring(0, 20)}...');
      }

      return token;
    } catch (e) {
      _logger.e('FCM: Error getting token', error: e);
      return null;
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      _logger.i('FCM: Foreground message received - ${message.messageId}');
      _logger.i('FCM: Title: ${message.notification?.title}');
      _logger.i('FCM: Body: ${message.notification?.body}');
      _logger.i('FCM: Data: ${message.data}');

      // Show local notification for foreground messages
      _showLocalNotification(message);

      // Emit to stream for in-app handling
      _notificationStreamController.add(message);
    } catch (e) {
      _logger.e('FCM: Error handling foreground message', error: e);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'taskaway_notifications',
        'Taskaway Notifications',
        channelDescription: 'Notifications for new tasks and updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        details,
        payload: message.data.toString(),
      );

      _logger.i('FCM: Local notification shown');
    } catch (e) {
      _logger.e('FCM: Error showing local notification', error: e);
    }
  }

  /// Handle notification tap (when user taps on notification)
  void _handleNotificationTap(RemoteMessage message) {
    try {
      _logger.i('FCM: Notification tapped - ${message.messageId}');
      _logger.i('FCM: Data: ${message.data}');

      // Call the callback if provided
      onNotificationTapped?.call(message);

      // Emit to stream
      _notificationStreamController.add(message);
    } catch (e) {
      _logger.e('FCM: Error handling notification tap', error: e);
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String token) {
    try {
      _logger.i('FCM: Token refreshed - ${token.substring(0, 20)}...');
      // This should trigger an update to the user's profile in the database
      // You can emit this to a stream or use a callback to update the database
      _notificationStreamController.add(
        RemoteMessage(
          data: {'type': 'token_refresh', 'token': token},
        ),
      );
    } catch (e) {
      _logger.e('FCM: Error handling token refresh', error: e);
    }
  }

  /// Delete FCM token (useful when user logs out)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _logger.i('FCM: Token deleted');
    } catch (e) {
      _logger.e('FCM: Error deleting token', error: e);
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _logger.i('FCM: Subscribed to topic - $topic');
    } catch (e) {
      _logger.e('FCM: Error subscribing to topic', error: e);
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _logger.i('FCM: Unsubscribed from topic - $topic');
    } catch (e) {
      _logger.e('FCM: Error unsubscribing from topic', error: e);
    }
  }

  /// Check if notifications are enabled
  /// For Android, checks permission_handler status
  /// For iOS, checks Firebase Messaging authorization status
  Future<bool> areNotificationsEnabled() async {
    try {
      // Check Android-specific permission
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.notification.status;
        _logger.i('FCM: Android notification permission status - $status');
        return status.isGranted;
      }

      // Check iOS/Firebase Messaging permission
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      _logger.e('FCM: Error checking notification settings', error: e);
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationStreamController.close();
  }
}
