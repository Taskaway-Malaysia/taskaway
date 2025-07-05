import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskaway/core/services/supabase_service.dart';
import 'package:taskaway/features/tasks/models/review.dart';

final reviewControllerProvider = Provider((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return ReviewController(supabase);
});

class ReviewController {
  final SupabaseService _supabase;

  ReviewController(this._supabase);

  Future<void> submitReview({
    required String taskerId,
    required String taskId,
    required int rating,
    required List<String> tags,
    String? comment,
  }) async {
    final currentUser = await _supabase.getCurrentUser();
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final data = {
      'task_id': taskId,
      'tasker_id': taskerId,
      'poster_id': currentUser.id,
      'rating': rating,
      'tags': tags,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _supabase.client
        .from('reviews')
        .insert(data);
  }
} 