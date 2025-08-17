import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../repositories/task_repository.dart';
import '../repositories/category_repository.dart';
import '../../../core/services/supabase_service.dart';
import '../../messages/controllers/message_controller.dart';
import '../../auth/models/profile.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import 'dart:developer' as dev;
import '../../../core/constants/api_constants.dart';

final taskControllerProvider = Provider<TaskController>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  return TaskController(ref: ref, repository: repository, categoryRepository: categoryRepository);
});

// Stream of all tasks
final taskStreamProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskControllerProvider).watchTasks();
});

// Provider for a single task by ID
final taskProvider = StreamProvider.family<Task, String>((ref, taskId) {
  return ref.watch(taskControllerProvider).watchTask(taskId);
});

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasks = ref.watch(taskStreamProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCategories = ref.watch(selectedCategoriesProvider);
  final role = ref.watch(roleProvider);
  final status = ref.watch(statusProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  
  return tasks.whenData((tasks) {
    return tasks.where((task) {
      // Role filter
      final matchesRole = role == 'poster' 
          ? task.posterId == currentUserId 
          : task.taskerId == currentUserId;

      // Status filter
      final matchesStatus = mapStatusToFilter(task.status) == status;

      // Search filter
      final matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(searchQuery.toLowerCase());
          
      // Category filter
      final matchesCategories = selectedCategories.isEmpty ||
          selectedCategories.any((category) => category == task.category);
          
      return matchesRole && matchesStatus && matchesSearch && matchesCategories;
    }).toList();
  });
});

// Provider for current user ID
final currentUserIdProvider = Provider<String>((ref) {
  return Supabase.instance.client.auth.currentUser?.id ?? '';
});

// User role provider (poster/tasker)
final roleProvider = StateProvider<String>((ref) => 'poster');

// Task status provider
final statusProvider = StateProvider<String>((ref) => 'awaiting_offers');

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Selected categories provider
final selectedCategoriesProvider = StateProvider<List<String>>((ref) => []);

// Helper function to map task status to filter value
String mapStatusToFilter(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return 'awaiting_offers';
    case 'accepted':
    case 'in_progress':
    case 'pending_approval':
      return 'upcoming_tasks';
    case 'completed':
    case 'cancelled':
      return 'completed';
    default:
      return 'awaiting_offers';
  }
}

// Provider to expose categories
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(taskControllerProvider).getCategories();
});

class TaskController {
  final TaskRepository _repository;
  final CategoryRepository _categoryRepository;
  final Ref _ref;
  final _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();

  TaskController({
    required TaskRepository repository,
    required CategoryRepository categoryRepository,
    required Ref ref
  }) : _repository = repository,
       _categoryRepository = categoryRepository,
       _ref = ref;

  Stream<List<Task>> watchTasks() => _repository.watchTasks();
  
  Stream<Task> watchTask(String id) => _repository.watchTask(id);

  Future<Task> getTaskById(String id) => _repository.getTaskById(id);

  // Upload images to Supabase storage and return URLs
  Future<List<String>> _uploadTaskImages(List<dynamic> images, String taskId) async {
    return await _supabaseService.uploadFiles(
      bucket: ApiConstants.taskImagesBucket,
      folderPath: 'tasks/$taskId',
      files: images,
    );
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required String category,
    required double price,
    required String location,
    required DateTime scheduledTime,
    required String posterId,
    String? dateOption,
    bool? needsSpecificTime,
    String? timeOfDay,
    String? locationType,
    bool? providesMaterials,
    List<dynamic>? images,
  }) async {
    // Create the task first to get an ID
    final task = Task(
      id: '',
      title: title,
      description: description,
      category: category,
      price: price,
      location: location,
      scheduledTime: scheduledTime,
      status: 'open',
      posterId: posterId,
      dateOption: dateOption,
      needsSpecificTime: needsSpecificTime,
      timeOfDay: timeOfDay,
      locationType: locationType,
      providesMaterials: providesMaterials,
      images: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final createdTask = await _repository.createTask(task);
    
    // If there are images, upload them and update the task with image URLs
    Task finalTask = createdTask;
    if (images != null && images.isNotEmpty) {
      final imageUrls = await _uploadTaskImages(images, createdTask.id);
      
      if (imageUrls.isNotEmpty) {
        // Update the task with image URLs
        await _repository.updateTask(createdTask.id, {
          'images': imageUrls,
        });
        
        // Get the updated task
        finalTask = await _repository.getTaskById(createdTask.id);
      }
    }
    
    // Trigger notification to all taskers about the new task
    try {
      // Get poster name from current user profile - using a simple approach
      final currentUser = _ref.read(currentUserProvider);
      final posterName = currentUser?.userMetadata?['full_name'] ?? 'Someone';
      
      await _ref.read(notificationControllerProvider.notifier).notifyTaskersOfNewTask(
        taskId: finalTask.id,
        taskTitle: finalTask.title,
        posterName: posterName,
      );
    } catch (e) {
      print('Failed to send task notifications: $e');
      // Don't fail the task creation if notifications fail
    }
    
    return finalTask;
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    // Convert the data map to use snake_case for database compatibility
    final dbData = {
      if (data['title'] != null) 'title': data['title'],
      if (data['description'] != null) 'description': data['description'],
      if (data['category'] != null) 'category': data['category'],
      if (data['price'] != null) 'price': data['price'],
      if (data['location'] != null) 'location': data['location'],
      if (data['scheduledTime'] != null) 'scheduled_time': (data['scheduledTime'] as DateTime).toIso8601String(),
      if (data['status'] != null) 'status': data['status'],
      if (data['taskerId'] != null) 'tasker_id': data['taskerId'],
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await _repository.updateTask(id, dbData);
  }

  // Add an offer to a task
  Future<void> addOffer(String taskId, Map<String, dynamic> offer) async {
    // Get the current task first
    final task = await _repository.getTaskById(taskId);
    
    // Get the current offers or initialize an empty list
    final List<Map<String, dynamic>> currentOffers = 
        (task.offers ?? []).map((o) => Map<String, dynamic>.from(o)).toList();
    
    // Add the new offer
    currentOffers.add(offer);
    
    // Update the task with the new offers list
    await _repository.updateTask(taskId, {
      'offers': currentOffers,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Accept an offer for a task and create a chat channel
  Future<void> acceptOffer(String taskId, String offerId, String taskerId) async {
    // Get the current task
    final task = await _repository.getTaskById(taskId);
    final currentUserId = _supabase.auth.currentUser?.id;
    
    // Verify the current user is the poster
    if (currentUserId != task.posterId) {
      throw Exception('Only the task poster can accept offers');
    }
    
    // Verify the task is in the correct state
    if (task.status != 'open') {
      throw Exception('Offers can only be accepted for open tasks');
    }
    
    // Find the accepted offer
    final acceptedOffer = task.offers?.firstWhere((o) => o['id'] == offerId, orElse: () => throw Exception('Offer not found'));
    
    if (acceptedOffer == null) {
      throw Exception('Offer not found');
    }
    
    // Update the offers list: set the accepted offer's status to 'accepted' and others to 'rejected'
    final updatedOffers = task.offers?.map((offer) {
      if (offer['id'] == offerId) {
        return {...offer, 'status': 'accepted'};
      } else {
        return {...offer, 'status': 'rejected'};
      }
    }).toList();
    
    // Update the task with the new status (accepted), accepted offer, and tasker
    await _repository.updateTask(taskId, {
      'status': 'accepted',
      'tasker_id': taskerId,
      'accepted_offer_id': offerId,
      'final_price': acceptedOffer['price'],
      'offers': updatedOffers,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Trigger notification to tasker about accepted offer
    try {
      final currentUser = _ref.read(currentUserProvider);
      final posterName = currentUser?.userMetadata?['full_name'] ?? 'Someone';
      
      await _ref.read(notificationControllerProvider.notifier).notifyTaskerOfAcceptedOffer(
        taskerId: taskerId,
        taskId: taskId,
        applicationId: offerId, // Using offerId as applicationId for now
        taskTitle: task.title,
        posterName: posterName,
      );
    } catch (e) {
      print('Failed to send offer acceptance notification: $e');
      // Don't fail the acceptance if notification fails
    }

    // After successful offer acceptance, create a chat channel between poster and tasker
    try {
      // Get names for poster and tasker from profiles
      final posterProfile = await _fetchProfile(task.posterId);
      final taskerProfile = await _fetchProfile(taskerId);

      // Create a new chat channel with a welcome message
      final messageController = _ref.read(messageControllerProvider);
      await messageController.initiateTaskConversation(
        taskId: taskId,
        taskTitle: task.title,
        posterId: task.posterId,
        posterName: posterProfile?.fullName ?? 'Task Poster',
        taskerId: taskerId,
        taskerName: taskerProfile?.fullName ?? 'Tasker',
      );
    } catch (e) {
      // Log the error but don't fail the entire operation
      print('Error creating chat channel: $e');
    }
  }

  // Helper method to fetch a user profile by ID
  Future<Profile?> _fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('taskaway_profiles')
          .select()
          .eq('id', userId)
          .single();
      return Profile.fromJson(data);
    } catch (e) {
      print('Error fetching profile for $userId: $e');
      return null;
    }
  }
  
  // Start a task (update status to in_progress)
  Future<void> startTask(String taskId) async {
    // Get the current task
    final task = await _repository.getTaskById(taskId);
    final currentUserId = _supabase.auth.currentUser?.id;
    
    // Verify the current user is the tasker
    if (currentUserId != task.taskerId) {
      throw Exception('Only the tasker for this task can start it');
    }
    
    // Verify the task is in the correct state (offer accepted)
    if (task.status != 'accepted') {
      throw Exception(
        'This task cannot be started. Current status: ${task.status}',
      );
    }
    
    // Update the task
    await _repository.updateTask(taskId, {
      'status': 'in_progress',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Mark a task as completed (update status to pending_approval)
  Future<void> completeTask(String taskId) async {
    // Get the current task
    final task = await _repository.getTaskById(taskId);
    final currentUserId = _supabase.auth.currentUser?.id;
    
    // Verify the current user is the tasker
    if (currentUserId != task.taskerId) {
      throw Exception('Only the tasker for this task can complete it');
    }
    
    // Verify the task is in the correct state
    if (task.status != 'in_progress') {
      throw Exception('This task cannot be marked as complete. Current status: ${task.status}');
    }
    
    // Update the task
    await _repository.updateTask(taskId, {
      'status': 'pending_approval',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Approve a completed task and capture payment
  Future<void> approveTask(String taskId) async {
    // Get the current task
    final task = await _repository.getTaskById(taskId);
    final currentUserId = _supabase.auth.currentUser?.id;
    
    // Verify the current user is the poster
    if (currentUserId != task.posterId) {
      throw Exception('Only the task poster can approve this task');
    }
    
    // Verify the task is in the correct state
    if (task.status != 'pending_approval') {
      throw Exception('This task cannot be approved. Current status: ${task.status}');
    }
    
    // Check if there's a payment to capture
    if (task.paymentIntentId != null) {
      // Payment capture is handled by the payment controller
      // The payment controller will also update the task status
      // This method is called from UI which handles payment capture separately
      print('Task has payment_intent_id: ${task.paymentIntentId}');
    } else {
      // Legacy flow: No payment to capture, just update status
      print('No payment_intent_id found, using legacy approval flow');
      await _repository.updateTask(taskId, {
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }
  
  // Cancel a task (poster only) -> update status to cancelled
  Future<void> cancelTask(String taskId) async {
    // Get the current task
    final task = await _repository.getTaskById(taskId);
    final currentUserId = _supabase.auth.currentUser?.id;
    
    // Verify the current user is the poster
    if (currentUserId != task.posterId) {
      throw Exception('Only the task poster can cancel this task');
    }
    
    // Allow cancelling when task is open or accepted
    if (task.status != 'open' && task.status != 'accepted') {
      throw Exception(
        'This task can only be cancelled when it is open or accepted. '
        'Current status: ${task.status}',
      );
    }
    
    // Update the task to cancelled
    await _repository.updateTask(taskId, {
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Request revisions to a task (update status back to in_progress)
  Future<void> requestRevisions(String taskId, String? revisionNotes) async {
    // Get the current task
    final task = await _repository.getTaskById(taskId);
    final currentUserId = _supabase.auth.currentUser?.id;
    
    // Verify the current user is the poster
    if (currentUserId != task.posterId) {
      throw Exception('Only the task poster can request revisions');
    }
    
    // Verify the task is in the correct state
    if (task.status != 'pending_approval') {
      throw Exception('Revisions can only be requested for tasks pending approval');
    }
    
    // Update the task
    final Map<String, dynamic> updateData = {
      'status': 'in_progress',
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Add revision notes if provided
    if (revisionNotes != null && revisionNotes.isNotEmpty) {
      updateData['revision_notes'] = revisionNotes;
    }
    
    await _repository.updateTask(taskId, updateData);
  }

  Future<bool> deleteTask(String id) async {
    try {
      // Get the task to access its images
      final task = await _repository.getTaskById(id);
      
      // Delete the task from the database
      await _repository.deleteTask(id);
      
      // Delete associated images if they exist
      if (task.images?.isNotEmpty == true) {
        // Extract file paths from URLs
        final filePaths = task.images!.map((url) {
          final uri = Uri.parse(url);
          final pathSegments = uri.pathSegments;
          // Find the index of the bucket name in the path
          final bucketIndex = pathSegments.indexOf(ApiConstants.taskImagesBucket);
          if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
            // The actual file path is everything after the bucket name
            return pathSegments.sublist(bucketIndex + 1).join('/');
          }
          return ''; // Return an empty string if the path is invalid
        }).where((path) => path.isNotEmpty).toList();
        
        await _supabaseService.deleteFiles(
          bucket: ApiConstants.taskImagesBucket,
          filePaths: filePaths,
        );
      }
      
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }
  
  // Get all available categories from the database
  Future<List<Category>> getCategories() async {
    return await _categoryRepository.getCategories();
  }
  
  // Watch available tasks for taskers to browse
  Stream<List<Task>> watchAvailableTasks() {
    return _repository.watchAvailableTasks();
  }
}