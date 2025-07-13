import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/db_constants.dart';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../constants/api_constants.dart';

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

  // Upload a single file to Supabase Storage
  Future<String?> uploadFile({
    required String filePath,
    required dynamic file,
    String? bucket,
    FileOptions? options,
  }) async {
    // Use the constant from ApiConstants or fallback to the provided bucket
    final storageBucket = bucket ?? ApiConstants.taskImagesBucket;
    try {
      // Handle different file types based on platform
      if (kIsWeb) {
        // For web platform
        if (file is XFile) {
          // Handle XFile (from image_picker) for web
          final bytes = await _readBytesFromXFile(file);
          await client.storage.from(storageBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: options ?? const FileOptions(cacheControl: '3600', upsert: false),
          );
        } else {
          // Try direct upload which might work for some types
          await client.storage.from(storageBucket).upload(
            filePath,
            file,
            fileOptions: options ?? const FileOptions(cacheControl: '3600', upsert: false),
          );
        }
      } else {
        // For mobile platforms
        if (file is File) {
          await client.storage.from(storageBucket).upload(
            filePath,
            file,
            fileOptions: options ?? const FileOptions(cacheControl: '3600', upsert: false),
          );
        } else if (file is XFile) {
          // Handle XFile for mobile
          final bytes = await _readBytesFromXFile(file);
          await client.storage.from(storageBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: options ?? const FileOptions(cacheControl: '3600', upsert: false),
          );
        } else {
          throw Exception('Unsupported file type: ${file.runtimeType}');
        }
      }

      final response = client.storage.from(storageBucket).getPublicUrl(filePath);
      return response;
    } catch (e) {
      dev.log('Error uploading file: $e');
      return null;
    }
  }

  // Helper method to read bytes from XFile (works on both web and mobile)
  Future<Uint8List> _readBytesFromXFile(XFile file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      dev.log('Error reading XFile bytes: $e');
      throw Exception('Failed to read file: $e');
    }
  }

  // Upload multiple files to Supabase Storage
  Future<List<String>> uploadFiles({
    required List<dynamic> files,
    String? bucket,
    String? folderPath,
    FileOptions? options,
  }) async {
    // Use the constant from ApiConstants or fallback to the provided bucket
    final storageBucket = bucket ?? ApiConstants.taskImagesBucket;
    final List<String> uploadedUrls = [];
    
    try {
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${timestamp}_$i.png';
        final filePath = folderPath != null ? '$folderPath/$fileName' : fileName;
        
        final url = await uploadFile(
          bucket: storageBucket,
          filePath: filePath,
          file: file,
          options: options,
        );
        
        if (url != null) {
          uploadedUrls.add(url);
        }
      }
      return uploadedUrls;
    } catch (e) {
      dev.log('Error uploading files: $e');
      return [];
    }
  }

  Future<bool> deleteFile({
    required String bucket,
    required String filePath,
  }) async {
    try {
      await client.storage.from(bucket).remove([filePath]);
      return true;
    } catch (e) {
      dev.log('Error deleting file: $e');
      return false;
    }
  }
  
  Future<bool> deleteFiles({
    required String bucket,
    required List<String> filePaths,
  }) async {
    try {
      await client.storage.from(bucket).remove(filePaths);
      return true;
    } catch (e) {
      dev.log('Error deleting files: $e');
      return false;
    }
  }
}