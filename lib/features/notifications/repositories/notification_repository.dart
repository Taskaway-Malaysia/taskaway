import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import 'dart:developer' as dev;

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    supabase: Supabase.instance.client,
  );
});

class NotificationRepository {
  final SupabaseClient supabase;
  final String _tableName = 'taskaway_notifications';

  NotificationRepository({required this.supabase});

  // Watch all notifications for a user (stream)
  Stream<List<Notification>> watchUserNotifications(String userId) {
    try {
      return supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => Notification.fromJson(json)).toList())
          .handleError((error) {
            dev.log('Realtime notification subscription error: $error');
            return _createNotificationPollingStream(userId);
          });
    } catch (e) {
      dev.log('Error setting up Realtime notification stream: $e');
      return _createNotificationPollingStream(userId);
    }
  }

  // Creates a polling-based stream as a fallback when Realtime fails
  Stream<List<Notification>> _createNotificationPollingStream(String userId) {
    return Stream.periodic(const Duration(seconds: 5), (_) => null)
        .asyncMap((_) => getUserNotifications(userId))
        .asBroadcastStream();
  }

  // Get all notifications for a user
  Future<List<Notification>> getUserNotifications(String userId) async {
    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map((json) => Notification.fromJson(json)).toList().cast<Notification>();
    } catch (e) {
      dev.log('Error fetching notifications: $e');
      return [];
    }
  }

  // Get unread notification count for a user
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await supabase
          .from(_tableName)
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .count();
      
      return response.count;
    } catch (e) {
      dev.log('Error fetching unread notification count: $e');
      return 0;
    }
  }

  // Create a new notification
  Future<Notification> createNotification(Map<String, dynamic> data) async {
    final response = await supabase
        .from(_tableName)
        .insert(data)
        .select()
        .single();
    
    return Notification.fromJson(response);
  }

  // Mark notification as read
  Future<Notification> markAsRead(String notificationId) async {
    final response = await supabase
        .from(_tableName)
        .update({'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId)
        .select()
        .single();
    
    return Notification.fromJson(response);
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    await supabase
        .from(_tableName)
        .update({'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId);
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await supabase
        .from(_tableName)
        .delete()
        .eq('id', notificationId);
  }

  // Create notification for all taskers when a task is posted
  Future<void> notifyTaskersOfNewTask({
    required String taskId,
    required String taskTitle,
    required String posterName,
  }) async {
    try {
      // Get all taskers (users with role 'tasker' or 'both')
      final taskers = await supabase
          .from('taskaway_profiles')
          .select('id')
          .inFilter('role', ['tasker', 'both']);

      // Create notifications for all taskers
      final notifications = taskers.map((tasker) => {
        'user_id': tasker['id'],
        'title': 'New Task Available',
        'message': '$posterName posted a new task: $taskTitle',
        'type': 'task_posted',
        'task_id': taskId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();

      if (notifications.isNotEmpty) {
        await supabase.from(_tableName).insert(notifications);
      }
    } catch (e) {
      dev.log('Error creating task notifications: $e');
    }
  }

  // Notify poster when an offer is received
  Future<void> notifyPosterOfOffer({
    required String posterId,
    required String taskId,
    required String applicationId,
    required String taskerName,
    required String taskTitle,
    required double offerPrice,
  }) async {
    try {
      await createNotification({
        'user_id': posterId,
        'title': 'New Offer Received',
        'message': '$taskerName offered RM${offerPrice.toStringAsFixed(2)} for "$taskTitle"',
        'type': 'offer_received',
        'task_id': taskId,
        'application_id': applicationId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      dev.log('Error creating offer notification: $e');
    }
  }

  // Notify tasker when their offer is accepted
  Future<void> notifyTaskerOfAcceptedOffer({
    required String taskerId,
    required String taskId,
    required String applicationId,
    required String taskTitle,
    required String posterName,
  }) async {
    try {
      await createNotification({
        'user_id': taskerId,
        'title': 'Offer Accepted',
        'message': '$posterName accepted your offer for "$taskTitle"',
        'type': 'offer_accepted',
        'task_id': taskId,
        'application_id': applicationId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      dev.log('Error creating offer accepted notification: $e');
    }
  }

  // Notify poster when task is completed
  Future<void> notifyPosterOfTaskCompletion({
    required String posterId,
    required String taskId,
    required String taskTitle,
    required String taskerName,
  }) async {
    try {
      await createNotification({
        'user_id': posterId,
        'title': 'Task Completed',
        'message': '$taskerName has completed "$taskTitle"',
        'type': 'task_completed',
        'task_id': taskId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      dev.log('Error creating task completion notification: $e');
    }
  }

  // Notify tasker when payment is received
  Future<void> notifyTaskerOfPayment({
    required String taskerId,
    required String taskId,
    required String paymentId,
    required String taskTitle,
    required double amount,
    required String posterName,
  }) async {
    try {
      await createNotification({
        'user_id': taskerId,
        'title': 'Payment Received',
        'message': 'You received RM${amount.toStringAsFixed(2)} from $posterName for "$taskTitle"',
        'type': 'payment_received',
        'task_id': taskId,
        'payment_id': paymentId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      dev.log('Error creating payment notification: $e');
    }
  }
} 