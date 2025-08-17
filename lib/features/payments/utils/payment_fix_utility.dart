import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility to fix tasks that have successful payments but incorrect status
class PaymentFixUtility {
  static final _supabase = Supabase.instance.client;

  /// Fixes all tasks that have payment_intent_id but status is still 'open'
  static Future<void> fixPendingPayments() async {
    try {
      print('[PaymentFix] Starting payment status fix...');
      
      // Find tasks with payment_intent_id but status is still 'open'
      final brokenTasks = await _supabase
          .from('taskaway_tasks')
          .select('id, payment_intent_id, status')
          .not('payment_intent_id', 'is', null)
          .eq('status', 'open');
      
      print('[PaymentFix] Found ${brokenTasks.length} tasks with payment but wrong status');
      
      for (final task in brokenTasks) {
        final taskId = task['id'] as String;
        final paymentIntentId = task['payment_intent_id'] as String;
        
        print('[PaymentFix] Processing task: $taskId with payment: $paymentIntentId');
        
        // Find the pending application for this task
        final application = await _supabase
            .from('taskaway_applications')
            .select('id, tasker_id, offer_price')
            .eq('task_id', taskId)
            .eq('status', 'pending')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (application != null) {
          final applicationId = application['id'] as String;
          final taskerId = application['tasker_id'] as String;
          final offerPrice = application['offer_price'];
          
          print('[PaymentFix] Found pending application: $applicationId');
          print('[PaymentFix] Updating task and application status...');
          
          // Update task status
          await _supabase
              .from('taskaway_tasks')
              .update({
                'status': 'accepted',
                'tasker_id': taskerId,
                'price': offerPrice,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', taskId);
          
          // Update application status
          await _supabase
              .from('taskaway_applications')
              .update({
                'status': 'accepted',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', applicationId);
          
          // Reject other applications
          await _supabase
              .from('taskaway_applications')
              .update({
                'status': 'rejected',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('task_id', taskId)
              .neq('id', applicationId)
              .eq('status', 'pending');
          
          print('[PaymentFix] Successfully fixed task: $taskId');
          
          // Create messaging channel if not exists
          try {
            // Check if channel already exists
            final existingChannel = await _supabase
                .from('taskaway_messages')
                .select('channel_id')
                .eq('task_id', taskId)
                .limit(1)
                .maybeSingle();
            
            if (existingChannel == null) {
              print('[PaymentFix] Creating messaging channel for task: $taskId');
              
              // Get profiles for channel creation
              final taskDetails = await _supabase
                  .from('taskaway_tasks')
                  .select('title, poster_id')
                  .eq('id', taskId)
                  .single();
              
              final posterProfile = await _supabase
                  .from('taskaway_profiles')
                  .select('full_name')
                  .eq('id', taskDetails['poster_id'])
                  .single();
              
              final taskerProfile = await _supabase
                  .from('taskaway_profiles')
                  .select('full_name')
                  .eq('id', taskerId)
                  .single();
              
              // Create channel
              final channelId = 'task_$taskId';
              await _supabase
                  .from('taskaway_messages')
                  .insert({
                    'channel_id': channelId,
                    'task_id': taskId,
                    'sender_id': taskDetails['poster_id'],
                    'receiver_id': taskerId,
                    'message': 'Offer accepted! Let\'s discuss the task details.',
                    'created_at': DateTime.now().toIso8601String(),
                  });
              
              print('[PaymentFix] Created messaging channel: $channelId');
            }
          } catch (e) {
            print('[PaymentFix] Error creating messaging channel: $e');
          }
        } else {
          print('[PaymentFix] No pending application found for task: $taskId');
          
          // Check if there's an accepted application
          final acceptedApp = await _supabase
              .from('taskaway_applications')
              .select('tasker_id, offer_price')
              .eq('task_id', taskId)
              .eq('status', 'accepted')
              .maybeSingle();
          
          if (acceptedApp != null) {
            print('[PaymentFix] Task already has accepted application, updating task status only');
            
            await _supabase
                .from('taskaway_tasks')
                .update({
                  'status': 'accepted',
                  'tasker_id': acceptedApp['tasker_id'],
                  'price': acceptedApp['offer_price'],
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', taskId);
            
            print('[PaymentFix] Updated task status to accepted');
          }
        }
      }
      
      print('[PaymentFix] Payment status fix completed');
    } catch (e, stackTrace) {
      print('[PaymentFix] Error fixing payment statuses: $e');
      print('[PaymentFix] Stack trace: $stackTrace');
    }
  }
}