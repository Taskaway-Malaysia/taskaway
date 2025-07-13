import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as dev;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:taskaway/features/applications/models/application.dart';
import 'package:taskaway/features/applications/repositories/application_repository.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/core/services/supabase_service.dart';
part 'application_controller.g.dart';

@riverpod
class ApplicationController extends _$ApplicationController {
  @override
  Future<void> build() async {
    // No-op
  }

  Future<void> submitOffer({
    required String taskId,
    required String taskerId,
    required double offerPrice,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(applicationRepositoryProvider);
    final existingApp = await repo.getUserApplicationForTask(taskId, taskerId);

    if (existingApp != null && existingApp.id != null) {
      // Re-offer
      state = await AsyncValue.guard(() => repo.updateApplication(existingApp.id!, {
            'offer_price': offerPrice,
            'status': 'pending',
          }));
    } else {
      // New offer
      state = await AsyncValue.guard(() => repo.createApplication({
            'task_id': taskId,
            'tasker_id': taskerId,
            'offer_price': offerPrice,
          }));
    }
  }

  Future<bool> acceptOffer({
    required String applicationId,
    required String taskId,
    required String taskerId, // The user who made the offer
  }) async {
    dev.log('acceptOffer started for appId: $applicationId, taskId: $taskId');
    state = const AsyncValue.loading();
    final repo = ref.read(applicationRepositoryProvider);
    try {
      // Fetch the application to get the offer price
      dev.log('Step 1: Getting application data...');
      final acceptedApplication = await repo.getApplicationById(applicationId);
      if (acceptedApplication == null) {
        throw Exception('Application not found');
      }
      final offerPrice = acceptedApplication.offerPrice;
      dev.log('Retrieved offer price: $offerPrice');

      // Prepare all the data we'll need to update
      dev.log('Step 2: Preparing data updates...');
      final taskData = {
        'status': 'pending', // Set status to 'pending' after an offer is accepted
        'tasker_id': taskerId,
        'price': offerPrice, // Use the 'price' field for the final agreed price
      };
      
      // Execute each update in sequence
      dev.log('Step 3: Updating application status...');
      await repo.updateApplication(applicationId, {'status': 'accepted'});
      
      dev.log('Step 4: Updating task data...');
      // Access TaskRepository directly rather than through ref to avoid any potential provider issues
      final supabase = SupabaseService.client;
      await supabase
          .from('taskaway_tasks')
          .update(taskData)
          .eq('id', taskId);
      dev.log('Task updated successfully');
      
      dev.log('Step 5: Rejecting other offers...');
      await repo.rejectOtherOffers(taskId, applicationId);
      dev.log('Other offers rejected successfully');
      
      dev.log('acceptOffer completed successfully');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      dev.log('acceptOffer failed with error: $e', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

@riverpod
Future<Application?> userApplicationForTask(Ref ref, String taskId) async {
  final currentUser = ref.watch(currentUserProvider);
  final repo = ref.watch(applicationRepositoryProvider);
  
  if (currentUser == null) {
    return null;
  }
  
  return await repo.getUserApplicationForTask(taskId, currentUser.id);
}
