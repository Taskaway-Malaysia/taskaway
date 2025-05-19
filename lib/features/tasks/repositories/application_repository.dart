import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepository(
    supabase: Supabase.instance.client,
  );
});

class ApplicationRepository {
  final SupabaseClient supabase;
  static const String _tableName = 'taskaway_applications';
  static const String _profilesTable = 'taskaway_profiles';

  ApplicationRepository({required this.supabase});

  Future<Application> createApplication(Application application) async {
    final response = await supabase
        .from(_tableName)
        .insert({
          'task_id': application.taskId,
          'tasker_id': application.taskerId,
          'message': application.message,
          'status': application.status,
        })
        .select('*, profiles:taskaway_profiles(full_name)')
        .single();

    return Application.fromJson(response);
  }

  Future<List<Application>> getApplications({
    String? taskId,
    String? taskerId,
    String? status,
  }) async {
    var query = supabase
        .from(_tableName)
        .select('*, profiles:taskaway_profiles(full_name)');

    if (taskId != null) {
      query = query.eq('task_id', taskId);
    }
    if (taskerId != null) {
      query = query.eq('tasker_id', taskerId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('created_at', ascending: false);

    return response
        .map((json) => Application.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Application> getApplicationById(String id) async {
    final data = await supabase
        .from(_tableName)
        .select('*, profiles:taskaway_profiles(full_name)')
        .eq('id', id)
        .single();
    
    return Application.fromJson(data as Map<String, dynamic>);
  }

  Future<void> updateApplication(String id, Map<String, dynamic> updates) async {
    await supabase
        .from(_tableName)
        .update(updates)
        .eq('id', id);
  }

  Future<void> deleteApplication(String id) async {
    await supabase
        .from(_tableName)
        .delete()
        .eq('id', id);
  }

  Future<void> acceptApplication(String applicationId) async {
    // Get the application to find the taskId and taskerId
    final application = await getApplicationById(applicationId);
    final taskId = application.taskId;
    final taskerId = application.taskerId;

    // Accept the selected application
    await supabase
        .from(_tableName)
        .update({'status': 'accepted'})
        .eq('id', applicationId);

    // Reject all other applications for the same task
    await supabase
        .from(_tableName)
        .update({'status': 'rejected'})
        .eq('task_id', taskId)
        .neq('id', applicationId);

    // Update the task's tasker_id and status to 'in_progress'
    await supabase
        .from('taskaway_tasks')
        .update({'tasker_id': taskerId, 'status': 'in_progress'})
        .eq('id', taskId);
  }

  Stream<List<Application>> watchApplications({
    String? taskId,
    String? taskerId,
    String? status,
  }) async* {
    // Initial fetch to get profile data
    final initialData = await getApplications(
      taskId: taskId,
      taskerId: taskerId,
      status: status,
    );

    // Create a map of tasker IDs to names
    final taskerNames = Map.fromEntries(
      initialData.map((app) => MapEntry(app.taskerId, app.taskerName))
    );

    yield initialData;

    // Stream updates
    await for (final list in supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])) {
      final applications = list
          .map((json) {
            final app = Application.fromJson({
              ...json as Map<String, dynamic>,
              'profiles': {'full_name': taskerNames[json['tasker_id']] ?? 'Unknown Tasker'}
            });
            return app;
          })
          .where((app) {
            bool matches = true;
            if (taskId != null && taskId.isNotEmpty) {
              matches = matches && app.taskId == taskId;
            }
            if (taskerId != null && taskerId.isNotEmpty) {
              matches = matches && app.taskerId == taskerId;
            }
            if (status != null && status.isNotEmpty) {
              matches = matches && app.status == status;
            }
            return matches;
          })
          .toList();
      
      // Sort by created date descending
      applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield applications;
    }
  }

  Stream<Application> watchApplication(String id) async* {
    // Initial fetch to get profile data
    final initialData = await getApplicationById(id);
    yield initialData;

    // Stream updates
    await for (final list in supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', id)) {
      if (list.isEmpty) continue;
      
      final json = list.first as Map<String, dynamic>;
      yield Application.fromJson({
        ...json,
        'profiles': {'full_name': initialData.taskerName}
      });
    }
  }
} 