import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/application_repository.dart';
import '../repositories/task_repository.dart';
import '../../messages/controllers/message_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final applicationControllerProvider = Provider<ApplicationController>((ref) {
  final applicationRepository = ref.watch(applicationRepositoryProvider);
  final taskRepository = ref.watch(taskRepositoryProvider);
  return ApplicationController(
    applicationRepository: applicationRepository,
    taskRepository: taskRepository,
    ref: ref,
  );
});

class ApplicationController {
  final ApplicationRepository _applicationRepository;
  final TaskRepository _taskRepository;
  final Ref _ref;
  final _supabase = Supabase.instance.client;

  ApplicationController({
    required ApplicationRepository applicationRepository,
    required TaskRepository taskRepository,
    required Ref ref,
  })  : _applicationRepository = applicationRepository,
        _taskRepository = taskRepository,
        _ref = ref;

  // Submit an application for a task
  Future<Map<String, dynamic>> submitApplication({
    required String taskId,
    required double offerPrice,
    required String message,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Get the task to check if the user is the poster
    final task = await _taskRepository.getTaskById(taskId);
    if (task.posterId == currentUserId) {
      throw Exception('You cannot apply to your own task');
    }

    // Create the application
    return await _applicationRepository.createApplication(
      taskId: taskId,
      taskerId: currentUserId,
      message: message,
      offerPrice: offerPrice,
    );
  }

  // Get all applications for a task
  Future<List<Map<String, dynamic>>> getApplicationsForTask(String taskId) async {
    return await _applicationRepository.getApplicationsForTask(taskId);
  }

  // Accept an application
  Future<void> acceptApplication(String applicationId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Get the application
    final application = await _applicationRepository.getApplicationById(applicationId);
    final taskId = application['task_id'] as String;
    final taskerId = application['tasker_id'] as String;

    // Get the task to verify ownership
    final task = await _taskRepository.getTaskById(taskId);
    if (task.posterId != currentUserId) {
      throw Exception('Only the task poster can accept applications');
    }

    // Update the application status
    await _applicationRepository.updateApplicationStatus(applicationId, 'accepted');

    // Update the task status and assign the tasker
    await _taskRepository.updateTask(taskId, {
      'status': 'assigned',
      'tasker_id': taskerId,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Reject all other applications
    final otherApplications = await _applicationRepository.getApplicationsForTask(taskId);
    for (final app in otherApplications) {
      if (app['id'] != applicationId) {
        await _applicationRepository.updateApplicationStatus(app['id'], 'rejected');
      }
    }

    // Create a chat channel between poster and tasker
    final messageController = _ref.read(messageControllerProvider);
    await messageController.createChannel(
      taskId: taskId,
      taskTitle: task.title,
      posterId: task.posterId,
      posterName: task.posterName ?? 'Unknown Poster',
      taskerId: taskerId,
      taskerName: application['tasker']['full_name'] ?? 'Unknown Tasker',
    );
  }

  // Get application by ID
  Future<Map<String, dynamic>> getApplicationById(String applicationId) async {
    return await _applicationRepository.getApplicationById(applicationId);
  }
} 