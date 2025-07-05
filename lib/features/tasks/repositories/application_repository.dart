import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/db_constants.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepository(
    supabase: Supabase.instance.client,
  );
});

class ApplicationRepository {
  final SupabaseClient supabase;
  final String _tableName = DbConstants.applicationsTable;

  ApplicationRepository({required this.supabase});

  // Create a new application
  Future<Map<String, dynamic>> createApplication({
    required String taskId,
    required String taskerId,
    required String message,
    required double offerPrice,
  }) async {
    final response = await supabase
        .from(_tableName)
        .insert({
          'task_id': taskId,
          'tasker_id': taskerId,
          'message': message,
          'offer_price': offerPrice,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    
    return response;
  }

  // Get all applications for a task
  Future<List<Map<String, dynamic>>> getApplicationsForTask(String taskId) async {
    final response = await supabase
        .from(_tableName)
        .select('*, tasker:tasker_id(full_name, avatar_url)')
        .eq('task_id', taskId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Update application status
  Future<Map<String, dynamic>> updateApplicationStatus(String applicationId, String status) async {
    final response = await supabase
        .from(_tableName)
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', applicationId)
        .select()
        .single();
    
    return response;
  }

  // Get application by ID
  Future<Map<String, dynamic>> getApplicationById(String applicationId) async {
    final response = await supabase
        .from(_tableName)
        .select('*, tasker:tasker_id(full_name, avatar_url)')
        .eq('id', applicationId)
        .single();
    
    return response;
  }

  // Delete application
  Future<void> deleteApplication(String applicationId) async {
    await supabase
        .from(_tableName)
        .delete()
        .eq('id', applicationId);
  }
} 