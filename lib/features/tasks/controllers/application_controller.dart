import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application.dart';
import '../repositories/application_repository.dart';

final applicationControllerProvider = Provider<ApplicationController>((ref) {
  return ApplicationController(
    repository: ref.watch(applicationRepositoryProvider),
  );
});

final taskApplicationsProvider = StreamProvider.family<List<Application>, String>((ref, taskId) {
  return ref.watch(applicationRepositoryProvider).watchApplications(taskId: taskId);
});

final userApplicationsProvider = StreamProvider.family<List<Application>, String>((ref, taskerId) {
  final repository = ref.watch(applicationRepositoryProvider);
  return repository.watchApplications(taskerId: taskerId);
});

class ApplicationController {
  final ApplicationRepository repository;

  ApplicationController({required this.repository});

  Future<bool> createApplication({
    required String taskId,
    required String taskerId,
    required String message,
  }) async {
    try {
      final application = Application(
        taskId: taskId,
        taskerId: taskerId,
        taskerName: 'Unknown Tasker', // This will be replaced by the repository join
        message: message,
      );

      await repository.createApplication(application);
      return true;
    } catch (e) {
      print('Error creating application: $e');
      return false;
    }
  }

  Future<List<Application>> getApplications({
    String? taskId,
    String? taskerId,
    String? status,
  }) async {
    try {
      return await repository.getApplications(
        taskId: taskId,
        taskerId: taskerId,
        status: status,
      );
    } catch (e) {
      throw Exception('Failed to fetch applications: $e');
    }
  }

  Stream<List<Application>> watchApplications({
    String? taskId,
    String? taskerId,
    String? status,
  }) {
    return repository.watchApplications(
      taskId: taskId,
      taskerId: taskerId,
      status: status,
    );
  }

  Stream<Application> watchApplication(String id) {
    return repository.watchApplication(id);
  }

  Future<bool> updateApplication(String id, Map<String, dynamic> updates) async {
    try {
      await repository.updateApplication(id, updates);
      return true;
    } catch (e) {
      print('Error updating application: $e');
      return false;
    }
  }

  Future<bool> deleteApplication(String id) async {
    try {
      await repository.deleteApplication(id);
      return true;
    } catch (e) {
      print('Error deleting application: $e');
      return false;
    }
  }
} 