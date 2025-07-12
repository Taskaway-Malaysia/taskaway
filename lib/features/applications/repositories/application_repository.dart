import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:taskaway/core/services/supabase_service.dart';
import 'package:taskaway/features/applications/models/application.dart';

part 'application_repository.g.dart';

class ApplicationRepository {
  final _supabaseClient = SupabaseService.client;

  Future<Application> createApplication(Map<String, dynamic> data) async {
    final response = await _supabaseClient
        .from('taskaway_applications')
        .insert(data)
        .select()
        .single();
    return Application.fromJson(response);
  }

  Future<Application> updateApplication(
      String id, Map<String, dynamic> data) async {
    final response = await _supabaseClient
        .from('taskaway_applications')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Application.fromJson(response);
  }

  Future<void> deleteApplication(String id) async {
    await _supabaseClient.from('taskaway_applications').delete().eq('id', id);
  }

  Future<List<Application>> getApplicationsForTask(String taskId) async {
    final response = await _supabaseClient
        .from('taskaway_applications')
        .select()
        .eq('task_id', taskId);

    return (response as List)
        .map((data) => Application.fromJson(data))
        .toList();
  }

  Future<Application?> getUserApplicationForTask(
      String taskId, String userId) async {
    final response = await _supabaseClient
        .from('taskaway_applications')
        .select()
        .eq('task_id', taskId)
        .eq('tasker_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }
    return Application.fromJson(response);
  }
}

@riverpod
ApplicationRepository applicationRepository(Ref ref) {
  return ApplicationRepository();
}
