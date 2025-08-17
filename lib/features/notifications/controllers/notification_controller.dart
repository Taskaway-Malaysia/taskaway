import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import 'dart:developer' as dev;

part 'notification_controller.g.dart';

@riverpod
class NotificationController extends _$NotificationController {
  @override
  Future<void> build() async {
    // No-op
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAsRead(notificationId);
    });
  }

  // Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllAsRead(currentUser.id);
    });
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.deleteNotification(notificationId);
    });
  }

  // Trigger notification when a task is posted
  Future<void> notifyTaskersOfNewTask({
    required String taskId,
    required String taskTitle,
    required String posterName,
  }) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.notifyTaskersOfNewTask(
        taskId: taskId,
        taskTitle: taskTitle,
        posterName: posterName,
      );
    } catch (e) {
      print('Error in notifyTaskersOfNewTask: $e');
    }
  }

  // Trigger notification when an offer is received
  Future<void> notifyPosterOfOffer({
    required String posterId,
    required String taskId,
    required String applicationId,
    required String taskerName,
    required String taskTitle,
    required double offerPrice,
  }) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.notifyPosterOfOffer(
        posterId: posterId,
        taskId: taskId,
        applicationId: applicationId,
        taskerName: taskerName,
        taskTitle: taskTitle,
        offerPrice: offerPrice,
      );
    } catch (e) {
      print('Error in notifyPosterOfOffer: $e');
    }
  }

  // Trigger notification when an offer is accepted
  Future<void> notifyTaskerOfAcceptedOffer({
    required String taskerId,
    required String taskId,
    required String applicationId,
    required String taskTitle,
    required String posterName,
  }) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.notifyTaskerOfAcceptedOffer(
        taskerId: taskerId,
        taskId: taskId,
        applicationId: applicationId,
        taskTitle: taskTitle,
        posterName: posterName,
      );
    } catch (e) {
      print('Error in notifyTaskerOfAcceptedOffer: $e');
    }
  }

  // Trigger notification when task is completed
  Future<void> notifyPosterOfTaskCompletion({
    required String posterId,
    required String taskId,
    required String taskTitle,
    required String taskerName,
  }) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.notifyPosterOfTaskCompletion(
        posterId: posterId,
        taskId: taskId,
        taskTitle: taskTitle,
        taskerName: taskerName,
      );
    } catch (e) {
      print('Error in notifyPosterOfTaskCompletion: $e');
    }
  }

  // Trigger notification when payment is received
  Future<void> notifyTaskerOfPayment({
    required String taskerId,
    required String taskId,
    required String paymentId,
    required String taskTitle,
    required double amount,
    required String posterName,
  }) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.notifyTaskerOfPayment(
        taskerId: taskerId,
        taskId: taskId,
        paymentId: paymentId,
        taskTitle: taskTitle,
        amount: amount,
        posterName: posterName,
      );
    } catch (e) {
      print('Error in notifyTaskerOfPayment: $e');
    }
  }
}

// Stream provider for user notifications
@riverpod
Stream<List<Notification>> userNotifications(Ref ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchUserNotifications(currentUser.id);
}

// Provider for unread notification count
@riverpod
Future<int> unreadNotificationCount(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return 0;
  }

  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadNotificationCount(currentUser.id);
} 