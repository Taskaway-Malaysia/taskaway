import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/db_constants.dart';

// Define RealtimeListenTypes enum to match Supabase's expected values
enum RealtimeListenTypes {
  postgresChanges,
  broadcast,
  presence,
}

// Define ChannelFilter class for Realtime subscriptions
class ChannelFilter {
  final String event;
  final String schema;
  final String table;
  final String filter;

  ChannelFilter({
    required this.event,
    required this.schema,
    required this.table,
    required this.filter,
  });
}

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Authentication Methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Profile Methods
  Future<void> createProfile({
    required String userId,
    required String name,
    required String role,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    await client.from(DbConstants.profilesTable).insert({
      'user_id': userId,
      'name': name,
      'role': role,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
    });
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await client
        .from(DbConstants.profilesTable)
        .select()
        .eq('user_id', userId)
        .single();
    return response;
  }

  // Task Methods
  Future<List<Map<String, dynamic>>> getTasks({
    String? category,
    String? status,
    int? limit,
    int? offset,
  }) async {
    var query = client.from(DbConstants.tasksTable).select();

    if (category != null) {
      query = query.eq('category', category);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (limit != null) {
      query = query.limit(limit) as PostgrestFilterBuilder<PostgrestList>;
    }
    if (offset != null) {
      query = query.range(offset, offset + (limit ?? 10) - 1) as PostgrestFilterBuilder<PostgrestList>;
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createTask({
    required String title,
    required String description,
    required String category,
    required double price,
    required String location,
    required DateTime deadline,
    required String posterId,
  }) async {
    await client.from(DbConstants.tasksTable).insert({
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'location': location,
      'deadline': deadline.toIso8601String(),
      'poster_id': posterId,
      'status': 'open',
    });
  }

  // Application Methods
  Future<void> applyForTask({
    required String taskId,
    required String taskerId,
    required String coverLetter,
    required double proposedPrice,
  }) async {
    await client.from(DbConstants.applicationsTable).insert({
      'task_id': taskId,
      'tasker_id': taskerId,
      'cover_letter': coverLetter,
      'proposed_price': proposedPrice,
      'status': 'pending',
    });
  }

  // Message Methods
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final response = await client
        .from(DbConstants.messagesTable)
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    await client.from(DbConstants.messagesTable).insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
    });
  }

  // Real-time subscription for messages
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(Map<String, dynamic>) onMessage,
  ) {
    return client
        .channel('public:${DbConstants.messagesTable}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: DbConstants.messagesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) => onMessage(payload.newRecord),
        )
        .subscribe();
  }
} 