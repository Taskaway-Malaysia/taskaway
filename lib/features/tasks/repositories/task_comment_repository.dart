import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_comment.dart';
import '../../../core/constants/db_constants.dart';
import 'dart:developer' as dev;

final taskCommentRepositoryProvider = Provider<TaskCommentRepository>((ref) {
  return TaskCommentRepository(
    supabase: Supabase.instance.client,
  );
});

class TaskCommentRepository {
  final SupabaseClient supabase;
  final String _tableName = DbConstants.commentsTable;

  TaskCommentRepository({required this.supabase});

  /// Watch comments for a specific task (stream) with real-time updates
  Stream<List<TaskComment>> watchTaskComments(String taskId) {
    try {
      dev.log('[TaskCommentRepository] Setting up watch for comments on task: $taskId');

      // Use Supabase Real-time subscription
      return supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('task_id', taskId)
          .order('created_at', ascending: true) // Oldest first (like a conversation)
          .asyncMap((data) async {
            dev.log('[TaskCommentRepository] Received ${data.length} comments from stream');

            // For each comment, fetch the user profile
            final commentsWithProfiles = await Future.wait(
              data.map((commentJson) async {
                final userId = commentJson['user_id'];
                if (userId != null) {
                  try {
                    final profileResponse = await supabase
                        .from('taskaway_profiles')
                        .select()
                        .eq('id', userId)
                        .single();
                    commentJson['user_profile'] = profileResponse;
                  } catch (e) {
                    dev.log('[TaskCommentRepository] Error fetching user profile for $userId: $e');
                  }
                }
                return commentJson;
              }).toList(),
            );

            final comments = commentsWithProfiles
                .map((json) => TaskComment.fromJson(json))
                .toList();
            dev.log('[TaskCommentRepository] Returning ${comments.length} comments');
            return comments;
          })
          .handleError((error) {
            dev.log('[TaskCommentRepository] Realtime subscription error for comments: $error');
            // Fallback to polling if real-time fails
            return _createCommentsPollingStream(taskId);
          });
    } catch (e) {
      dev.log('[TaskCommentRepository] Error setting up Realtime stream for comments: $e');
      return _createCommentsPollingStream(taskId);
    }
  }

  /// Creates a polling-based stream for comments as a fallback when Realtime fails
  Stream<List<TaskComment>> _createCommentsPollingStream(String taskId) {
    return Stream.periodic(const Duration(seconds: 3), (_) => null)
        .asyncMap((_) async {
          try {
            final comments = await getTaskComments(taskId);
            return comments;
          } catch (e) {
            dev.log('[TaskCommentRepository] Error fetching comments: $e');
            return <TaskComment>[];
          }
        })
        .asBroadcastStream();
  }

  /// Get comments for a specific task (non-stream version)
  Future<List<TaskComment>> getTaskComments(String taskId) async {
    try {
      final response = await supabase
          .from(_tableName)
          .select('*, user_profile:taskaway_profiles!user_id(*)')
          .eq('task_id', taskId)
          .order('created_at', ascending: true);

      return response
          .map((json) => TaskComment.fromJson(json))
          .toList()
          .cast<TaskComment>();
    } catch (e) {
      dev.log('[TaskCommentRepository] Error fetching comments: $e');
      return [];
    }
  }

  /// Add a new comment to a task
  Future<TaskComment?> addComment({
    required String taskId,
    required String userId,
    required String comment,
  }) async {
    try {
      dev.log('[TaskCommentRepository] Adding comment to task $taskId by user $userId');

      final newComment = TaskComment(
        taskId: taskId,
        userId: userId,
        comment: comment,
      );

      final response = await supabase
          .from(_tableName)
          .insert(newComment.toJson())
          .select()
          .single();

      dev.log('[TaskCommentRepository] Comment added successfully');
      return TaskComment.fromJson(response);
    } catch (e) {
      dev.log('[TaskCommentRepository] Error adding comment: $e');
      return null;
    }
  }

  /// Delete a comment (optional - for moderation)
  Future<bool> deleteComment(String commentId) async {
    try {
      dev.log('[TaskCommentRepository] Deleting comment: $commentId');

      await supabase
          .from(_tableName)
          .delete()
          .eq('id', commentId);

      dev.log('[TaskCommentRepository] Comment deleted successfully');
      return true;
    } catch (e) {
      dev.log('[TaskCommentRepository] Error deleting comment: $e');
      return false;
    }
  }

  /// Get comment count for a task
  Future<int> getCommentCount(String taskId) async {
    try {
      final response = await supabase
          .from(_tableName)
          .select('id')
          .eq('task_id', taskId);

      return response.length;
    } catch (e) {
      dev.log('[TaskCommentRepository] Error getting comment count: $e');
      return 0;
    }
  }
}
