import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:taskaway/features/applications/models/application.dart';
import 'package:taskaway/features/applications/repositories/application_repository.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/notifications/controllers/notification_controller.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'dart:developer' as dev;

part 'application_controller.g.dart';

@riverpod
class ApplicationController extends _$ApplicationController {
  @override
  Future<void> build() async {
    // No-op
  }

  Future<void> submitOffer({
    required String taskId,
    required String taskerId,
    required double offerPrice,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(applicationRepositoryProvider);
    final existingApp = await repo.getUserApplicationForTask(taskId, taskerId);

    Application? createdOrUpdatedApp;

    if (existingApp != null && existingApp.id != null) {
      // Re-offer
      state = await AsyncValue.guard(() async {
        createdOrUpdatedApp = await repo.updateApplication(existingApp.id!, {
          'offer_price': offerPrice,
          'status': 'pending',
        });
      });
    } else {
      // New offer
      state = await AsyncValue.guard(() async {
        createdOrUpdatedApp = await repo.createApplication({
          'task_id': taskId,
          'tasker_id': taskerId,
          'offer_price': offerPrice,
        });
      });
    }

    // Trigger notification to poster about the new offer
    if (createdOrUpdatedApp != null) {
      try {
        // Get task details and user names for notification
        final task = await ref.read(taskControllerProvider).getTaskById(taskId);
        final currentUser = ref.read(currentUserProvider);
        final taskerName = currentUser?.userMetadata?['full_name'] ?? 'Someone';

        await ref.read(notificationControllerProvider.notifier).notifyPosterOfOffer(
          posterId: task.posterId,
          taskId: taskId,
          applicationId: createdOrUpdatedApp!.id!,
          taskerName: taskerName,
          taskTitle: task.title,
          offerPrice: offerPrice,
        );
      } catch (e) {
        dev.log('Failed to send offer notification: $e');
        // Don't fail the offer submission if notification fails
      }
    }
  }
}

@riverpod
Future<Application?> userApplicationForTask(Ref ref, String taskId) async {
  final currentUser = ref.watch(currentUserProvider);
  final repo = ref.watch(applicationRepositoryProvider);
  
  if (currentUser == null) {
    return null;
  }
  
  return await repo.getUserApplicationForTask(taskId, currentUser.id);
}
