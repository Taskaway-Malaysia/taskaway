import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final Logger _logger = Logger();

  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  // User Properties
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      _logger.i('Analytics: User ID set - $userId');
    } catch (e) {
      _logger.e('Analytics: Error setting user ID', error: e);
    }
  }

  Future<void> setUserProperties({
    String? userRole,
    String? userName,
    String? userEmail,
  }) async {
    try {
      if (userRole != null) {
        await _analytics.setUserProperty(name: 'user_role', value: userRole);
      }
      if (userName != null) {
        await _analytics.setUserProperty(name: 'user_name', value: userName);
      }
      if (userEmail != null) {
        await _analytics.setUserProperty(name: 'user_email', value: userEmail);
      }
      _logger.i('Analytics: User properties set');
    } catch (e) {
      _logger.e('Analytics: Error setting user properties', error: e);
    }
  }

  // Authentication Events
  Future<void> logSignUp({required String signUpMethod}) async {
    try {
      await _analytics.logSignUp(signUpMethod: signUpMethod);
      _logger.i('Analytics: Sign up logged - $signUpMethod');
    } catch (e) {
      _logger.e('Analytics: Error logging sign up', error: e);
    }
  }

  Future<void> logLogin({required String loginMethod}) async {
    try {
      await _analytics.logLogin(loginMethod: loginMethod);
      _logger.i('Analytics: Login logged - $loginMethod');
    } catch (e) {
      _logger.e('Analytics: Error logging login', error: e);
    }
  }

  Future<void> logLogout() async {
    try {
      await _analytics.logEvent(name: 'logout');
      _logger.i('Analytics: Logout logged');
    } catch (e) {
      _logger.e('Analytics: Error logging logout', error: e);
    }
  }

  // Task Events
  Future<void> logTaskCreated({
    required String taskId,
    required String category,
    required double price,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'task_created',
        parameters: {
          'task_id': taskId,
          'category': category,
          'price': price,
        },
      );
      _logger.i('Analytics: Task created - $taskId');
    } catch (e) {
      _logger.e('Analytics: Error logging task created', error: e);
    }
  }

  Future<void> logTaskViewed({
    required String taskId,
    required String category,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'task_viewed',
        parameters: {
          'task_id': taskId,
          'category': category,
        },
      );
      _logger.i('Analytics: Task viewed - $taskId');
    } catch (e) {
      _logger.e('Analytics: Error logging task viewed', error: e);
    }
  }

  Future<void> logTaskApplied({
    required String taskId,
    required String taskerId,
    required double proposedPrice,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'task_applied',
        parameters: {
          'task_id': taskId,
          'tasker_id': taskerId,
          'proposed_price': proposedPrice,
        },
      );
      _logger.i('Analytics: Task applied - $taskId by $taskerId');
    } catch (e) {
      _logger.e('Analytics: Error logging task applied', error: e);
    }
  }

  Future<void> logTaskCompleted({
    required String taskId,
    required String category,
    required double finalPrice,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'task_completed',
        parameters: {
          'task_id': taskId,
          'category': category,
          'final_price': finalPrice,
        },
      );
      _logger.i('Analytics: Task completed - $taskId');
    } catch (e) {
      _logger.e('Analytics: Error logging task completed', error: e);
    }
  }

  // Payment Events
  Future<void> logPaymentInitiated({
    required String paymentId,
    required double amount,
    required String currency,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'payment_initiated',
        parameters: {
          'payment_id': paymentId,
          'amount': amount,
          'currency': currency,
        },
      );
      _logger.i('Analytics: Payment initiated - $paymentId');
    } catch (e) {
      _logger.e('Analytics: Error logging payment initiated', error: e);
    }
  }

  Future<void> logPaymentCompleted({
    required String paymentId,
    required double amount,
    required String currency,
    required String paymentMethod,
  }) async {
    try {
      await _analytics.logPurchase(
        currency: currency,
        value: amount,
        transactionId: paymentId,
        parameters: {
          'payment_method': paymentMethod,
        },
      );
      _logger.i('Analytics: Payment completed - $paymentId');
    } catch (e) {
      _logger.e('Analytics: Error logging payment completed', error: e);
    }
  }

  Future<void> logPaymentFailed({
    required String paymentId,
    required String reason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'payment_failed',
        parameters: {
          'payment_id': paymentId,
          'failure_reason': reason,
        },
      );
      _logger.i('Analytics: Payment failed - $paymentId');
    } catch (e) {
      _logger.e('Analytics: Error logging payment failed', error: e);
    }
  }

  // Message Events
  Future<void> logMessageSent({
    required String conversationId,
    required String messageType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'message_sent',
        parameters: {
          'conversation_id': conversationId,
          'message_type': messageType,
        },
      );
      _logger.i('Analytics: Message sent in conversation - $conversationId');
    } catch (e) {
      _logger.e('Analytics: Error logging message sent', error: e);
    }
  }

  // Search Events
  Future<void> logSearch({
    required String searchTerm,
    String? category,
    String? location,
  }) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
        parameters: {
          if (category != null) 'category': category,
          if (location != null) 'location': location,
        },
      );
      _logger.i('Analytics: Search performed - $searchTerm');
    } catch (e) {
      _logger.e('Analytics: Error logging search', error: e);
    }
  }

  // Screen View Events (automatically tracked by FirebaseAnalyticsObserver)
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      _logger.i('Analytics: Screen viewed - $screenName');
    } catch (e) {
      _logger.e('Analytics: Error logging screen view', error: e);
    }
  }

  // Custom Events
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters?.map((key, value) => MapEntry(key, value as Object)),
      );
      _logger.i('Analytics: Custom event - $eventName');
    } catch (e) {
      _logger.e('Analytics: Error logging custom event', error: e);
    }
  }

  // App Lifecycle Events
  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
      _logger.i('Analytics: App opened');
    } catch (e) {
      _logger.e('Analytics: Error logging app open', error: e);
    }
  }

  // Rating Events
  Future<void> logRatingGiven({
    required String targetId,
    required String targetType, // 'tasker' or 'poster'
    required double rating,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'rating_given',
        parameters: {
          'target_id': targetId,
          'target_type': targetType,
          'rating': rating,
        },
      );
      _logger.i('Analytics: Rating given - $rating stars to $targetType $targetId');
    } catch (e) {
      _logger.e('Analytics: Error logging rating', error: e);
    }
  }
}