import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:taskaway/features/applications/models/application.dart';
import 'package:taskaway/features/applications/repositories/application_repository.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/notifications/controllers/notification_controller.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/messages/repositories/message_repository.dart';
import 'package:taskaway/core/services/supabase_service.dart';
import 'package:taskaway/features/payments/services/stripe_service.dart';
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

    Application? createdOrUpdatedApp;

    if (existingApp != null && existingApp.id != null) {
      // Re-offer
      state = await AsyncValue.guard(() async {
        createdOrUpdatedApp = await repo.updateApplication(existingApp.id!, {
          'offer_price': offerPrice,
          'status': 'pending',
        });
      });
    } else {
      // New offer
      state = await AsyncValue.guard(() async {
        createdOrUpdatedApp = await repo.createApplication({
          'task_id': taskId,
          'tasker_id': taskerId,
          'offer_price': offerPrice,
        });
      });
    }

    // Trigger notification to poster about the new offer
    if (createdOrUpdatedApp != null) {
      try {
        // Get task details and user names for notification
        final task = await ref.read(taskControllerProvider).getTaskById(taskId);
        final currentUser = ref.read(currentUserProvider);
        final taskerName = currentUser?.userMetadata?['full_name'] ?? 'Someone';

        await ref.read(notificationControllerProvider.notifier).notifyPosterOfOffer(
          posterId: task.posterId,
          taskId: taskId,
          applicationId: createdOrUpdatedApp!.id!,
          taskerName: taskerName,
          taskTitle: task.title,
          offerPrice: offerPrice,
        );
      } catch (e) {
        print('Failed to send offer notification: $e');
        // Don't fail the offer submission if notification fails
      }
    }
  }

  /// Initiates offer acceptance by validating data and preparing for payment
  /// Returns payment initialization data for the payment screen
  Future<Map<String, dynamic>> initiateOfferAcceptance({
    required String applicationId,
    required String taskId,
    required String taskerId, // The user who made the offer
  }) async {
    print('initiateOfferAcceptance started for appId: $applicationId, taskId: $taskId');
    state = const AsyncValue.loading();
    
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check that poster is not the same as tasker
      final task = await ref.read(taskControllerProvider).getTaskById(taskId);
      if (task.posterId == taskerId) {
        throw Exception('Cannot accept your own offer');
      }

      // Get application data
      final repo = ref.read(applicationRepositoryProvider);
      final acceptedApplication = await repo.getApplicationById(applicationId);
      if (acceptedApplication == null) {
        throw Exception('Application not found');
      }
      final offerPrice = acceptedApplication.offerPrice;
      print('Retrieved offer price: $offerPrice');

      // Don't create PaymentIntent here - it will be created based on payment method
      // Card: needs PaymentIntent upfront
      // FPX/GrabPay: create their own PaymentIntents
      
      print('Offer data validated successfully - proceeding to payment method selection');
      state = const AsyncValue.data(null);
      
      // Calculate platform fee here for display purposes
      final platformFee = offerPrice * 0.05; // 5% platform fee
      final taskerAmount = offerPrice - platformFee;
      
      return {
        'applicationId': applicationId,
        'taskId': taskId,
        'taskerId': taskerId,
        'taskTitle': task.title,
        'offerPrice': offerPrice,
        'paymentIntentId': '', // Will be created based on payment method
        'clientSecret': '', // Will be created based on payment method
        'amount': offerPrice,
        'platformFee': platformFee,
        'taskerAmount': taskerAmount,
      };
    } catch (e, st) {
      print('initiateOfferAcceptance failed with error: $e\nStackTrace: $st');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Completes offer acceptance AFTER payment is successfully authorized
  /// Updates all database records and creates messaging channel
  Future<bool> completeOfferAcceptance({
    required String applicationId,
    required String taskId,
    required String taskerId,
    required String paymentIntentId,
    required double offerPrice,
  }) async {
    print('completeOfferAcceptance started for appId: $applicationId, taskId: $taskId');
    state = const AsyncValue.loading();
    final repo = ref.read(applicationRepositoryProvider);
    
    try {
      // Update application status to 'accepted'
      print('Step 1: Updating application status...');
      await repo.updateApplication(applicationId, {'status': 'accepted'});
      
      // Update task status to 'accepted' (not 'pending') and set price
      print('Step 2: Updating task data...');
      final supabase = SupabaseService.client;
      final taskData = {
        'status': 'accepted', // Set status to 'accepted' after payment is authorized
        'tasker_id': taskerId,
        'price': offerPrice,
        'payment_intent_id': paymentIntentId, // Save payment_intent_id
        'updated_at': DateTime.now().toIso8601String(),
      };
      await supabase
          .from('taskaway_tasks')
          .update(taskData)
          .eq('id', taskId);
      print('Task updated successfully');
      
      // Update payment record status (only for card payments that need manual capture)
      print('Step 2b: Checking payment method and updating status if needed...');
      try {
        // First, get the existing payment record to check payment method
        var paymentRecord = await supabase
            .from('taskaway_payments')
            .select('payment_method_type, capture_method, payment_status')
            .eq('stripe_payment_intent_id', paymentIntentId)
            .maybeSingle();
        
        if (paymentRecord != null) {
          final paymentMethodType = paymentRecord['payment_method_type'];
          final captureMethod = paymentRecord['capture_method'];
          final currentStatus = paymentRecord['payment_status'];
          
          print('Payment method: $paymentMethodType, capture method: $captureMethod, current status: $currentStatus');
          
          // Only update to 'requires_capture' for card payments with manual capture
          // Skip update for FPX/GrabPay which are already captured
          if (paymentMethodType == 'card' || paymentMethodType == null) {
            // Card payment or legacy payment (assume card) - update to requires_capture
            var paymentUpdateResult = await supabase
                .from('taskaway_payments')
                .update({
                  'status': 'authorized',
                  'payment_status': 'requires_capture', // Payment is authorized but not captured yet
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('stripe_payment_intent_id', paymentIntentId)
                .select();
            
            if (paymentUpdateResult.isNotEmpty) {
              print('Card payment record updated to authorized/requires_capture status');
            }
          } else if (paymentMethodType == 'fpx' || paymentMethodType == 'grabpay') {
            // FPX/GrabPay - these are automatically captured, don't change status
            print('FPX/GrabPay payment detected - keeping existing status: $currentStatus');
            // Optionally update only the timestamp to track the return
            await supabase
                .from('taskaway_payments')
                .update({
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('stripe_payment_intent_id', paymentIntentId);
          }
        } else {
          print('Warning: No payment record found to update');
        }
      } catch (e) {
        print('Warning: Failed to update payment status: $e');
        // Don't fail the whole process if payment status update fails
      }
      
      // Reject other offers
      print('Step 3: Rejecting other offers...');
      await repo.rejectOtherOffers(taskId, applicationId);
      print('Other offers rejected successfully');
      
      // Create messaging channel for communication
      print('Step 4: Creating messaging channel...');
      try {
        // Get task details for channel creation
        final task = await ref.read(taskControllerProvider).getTaskById(taskId);
        
        // Get poster and tasker profile information
        final posterProfile = await supabase
            .from('taskaway_profiles')
            .select()
            .eq('id', task.posterId)
            .single();
        
        final taskerProfile = await supabase
            .from('taskaway_profiles')
            .select()
            .eq('id', taskerId)
            .single();
        
        print('Poster profile: ${posterProfile['full_name']} (ID: ${task.posterId})');
        print('Tasker profile: ${taskerProfile['full_name']} (ID: $taskerId)');
        
        // Create the message repository and initiate conversation
        final messageRepo = MessageRepository(supabase: supabase);
        final channel = await messageRepo.initiateTaskConversation(
          taskId: taskId,
          taskTitle: task.title,
          posterId: task.posterId,
          posterName: posterProfile['full_name'] ?? 'Poster',
          taskerId: taskerId,
          taskerName: taskerProfile['full_name'] ?? 'Tasker',
          welcomeMessage: 'Hi! I\'ve accepted your offer for "${task.title}". Let\'s discuss the details.',
        );
        print('Messaging channel created successfully with ID: ${channel.id}');
      } catch (e, stackTrace) {
        print('ERROR: Failed to create messaging channel - Error: $e\nStackTrace: $stackTrace');
        // Note: We don't throw here to avoid failing the entire acceptance process
      }
      
      print('completeOfferAcceptance completed successfully');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      print('completeOfferAcceptance failed with error: $e\nStackTrace: $st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// DEPRECATED: This method will be removed in future versions.
  /// Use initiateOfferAcceptance + completeOfferAcceptance for payment-first flow.
  /// 
  /// Legacy method that processes offer acceptance without payment authorization.
  /// This bypasses the new payment-first flow and should not be used for new implementations.
  @Deprecated('Use initiateOfferAcceptance + completeOfferAcceptance instead')
  Future<bool> acceptOffer({
    required String applicationId,
    required String taskId,
    required String taskerId, // The user who made the offer
  }) async {
    print('acceptOffer started for appId: $applicationId, taskId: $taskId');
    state = const AsyncValue.loading();
    final repo = ref.read(applicationRepositoryProvider);
    try {
      // Fetch the application to get the offer price
      print('Step 1: Getting application data...');
      final acceptedApplication = await repo.getApplicationById(applicationId);
      if (acceptedApplication == null) {
        throw Exception('Application not found');
      }
      final offerPrice = acceptedApplication.offerPrice;
      print('Retrieved offer price: $offerPrice');

      // Prepare all the data we'll need to update
      print('Step 2: Preparing data updates...');
      final taskData = {
        'status': 'accepted', // Set status to 'accepted' after an offer is accepted
        'tasker_id': taskerId,
        'price': offerPrice, // Use the 'price' field for the final agreed price
      };
      
      // Execute each update in sequence
      print('Step 3: Updating application status...');
      await repo.updateApplication(applicationId, {'status': 'accepted'});
      
      print('Step 4: Updating task data...');
      // Access TaskRepository directly rather than through ref to avoid any potential provider issues
      final supabase = SupabaseService.client;
      await supabase
          .from('taskaway_tasks')
          .update(taskData)
          .eq('id', taskId);
      print('Task updated successfully');
      
      print('Step 5: Rejecting other offers...');
      await repo.rejectOtherOffers(taskId, applicationId);
      print('Other offers rejected successfully');
      
      // Step 6: Create messaging channel for communication
      print('Step 6: Creating messaging channel...');
      try {
        // Get task details for channel creation
        final task = await ref.read(taskControllerProvider).getTaskById(taskId);
        
        // Get poster and tasker profile information
        // Note: task.posterId and taskerId are already profile IDs, not user IDs
        final posterProfile = await supabase
            .from('taskaway_profiles')
            .select()
            .eq('id', task.posterId)
            .single();
        
        final taskerProfile = await supabase
            .from('taskaway_profiles')
            .select()
            .eq('id', taskerId)
            .single();
        
        print('Poster profile: ${posterProfile['full_name']} (ID: ${task.posterId})');
        print('Tasker profile: ${taskerProfile['full_name']} (ID: $taskerId)');
        
        // Create the message repository and initiate conversation
        final messageRepo = MessageRepository(supabase: supabase);
        final channel = await messageRepo.initiateTaskConversation(
          taskId: taskId,
          taskTitle: task.title,
          posterId: task.posterId,
          posterName: posterProfile['full_name'] ?? 'Poster',
          taskerId: taskerId,
          taskerName: taskerProfile['full_name'] ?? 'Tasker',
          welcomeMessage: 'Hi! I\'ve accepted your offer for "${task.title}". Let\'s discuss the details.',
        );
        print('Messaging channel created successfully with ID: ${channel.id}');
      } catch (e, stackTrace) {
        // Log the full error with stack trace for debugging
        print('ERROR: Failed to create messaging channel - Error: $e\nStackTrace: $stackTrace');
        // Note: We don't throw here to avoid failing the entire acceptance process
        // The fallback in _navigateToChat will handle channel creation if needed
      }
      
      print('acceptOffer completed successfully');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      print('acceptOffer failed with error: $e\nStackTrace: $st');
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
