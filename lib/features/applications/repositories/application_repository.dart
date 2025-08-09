import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:taskaway/core/services/supabase_service.dart';
import 'package:taskaway/features/applications/models/application.dart';

part 'application_repository.g.dart';

class ApplicationRepository {
  final _supabaseClient = SupabaseService.client;

  Future<Map<String, dynamic>> acceptOfferViaFunction({
    required String applicationId,
    required String taskId,
    required String taskerId,
  }) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'accept-task-offer',
        body: {
          'applicationId': applicationId,
          'taskId': taskId,
          'taskerId': taskerId,
        },
      );
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Log the error but rethrow for the caller to handle
      dev.log('Edge function error: $e');
      rethrow;
    }
  }

  Future<Application> createApplication(Map<String, dynamic> data) async {
    // Ensure default status is set to 'pending' for new applications
    final payload = {
      ...data,
      'status': data['status'] ?? 'pending',
    };
    final response = await _supabaseClient
        .from('taskaway_applications')
        .insert(payload)
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

  Future<List<Application>> getUserApplications(
    String userId, {
    List<String>? statuses,
  }) async {
    var query = _supabaseClient
        .from('taskaway_applications')
        .select()
        .eq('tasker_id', userId);

    if (statuses != null && statuses.isNotEmpty) {
      if (statuses.length == 1) {
        query = query.eq('status', statuses.first);
      } else {
        // Use OR expression for broader compatibility across versions
        final orExpr = statuses.map((s) => 'status.eq.$s').join(',');
        query = query.or(orExpr);
      }
    }

    final response = await query;
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

  Future<Application?> getApplicationById(String id) async {
    final response = await _supabaseClient
        .from('taskaway_applications')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }
    return Application.fromJson(response);
  }

  Future<void> rejectOtherOffers(String taskId, String acceptedApplicationId) async {
    await _supabaseClient
        .from('taskaway_applications')
        .update({'status': 'rejected'})
        .eq('task_id', taskId)
        .neq('id', acceptedApplicationId);
  }
}

@riverpod
ApplicationRepository applicationRepository(Ref ref) {
  return ApplicationRepository();
}
