import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:taskaway/core/theme/app_spacing.dart';
import '../controllers/task_controller.dart';
import '../models/task.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/profile.dart';
import '../../messages/controllers/message_controller.dart';
import '../../messages/models/channel.dart';
import '../../../core/theme/app_radius.dart';

class TaskDetailsScreenNew extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailsScreenNew({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailsScreenNew> createState() => _TaskDetailsScreenNewState();
}

class _TaskDetailsScreenNewState extends ConsumerState<TaskDetailsScreenNew> {
  bool _isLoading = false;
  String? _errorMessage;

  // Navigate to chat method - allows any user to message the poster
  Future<void> _navigateToChat(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messageController = ref.read(messageControllerProvider);
      final task = ref.read(taskProvider(widget.taskId)).value;
      final currentUser = ref.read(currentUserProvider);

      if (task == null || currentUser == null) {
        throw Exception('Unable to load task details. Please try again.');
      }

      // Try to find existing channel between current user and poster for this task
      // We need to check if a channel already exists for this specific user-task combination
      Channel? channel;

      try {
        // Query for a channel where:
        // - task_id matches this task
        // - current user is either the poster or tasker
        final supabase = Supabase.instance.client;
        final channelResponse = await supabase
            .from('taskaway_channels')
            .select()
            .eq('task_id', widget.taskId)
            .or('poster_id.eq.${currentUser.id},tasker_id.eq.${currentUser.id}')
            .maybeSingle();

        if (channelResponse != null) {
          channel = Channel.fromJson(channelResponse);
        }
      } catch (e) {
        print('Error checking for existing channel: $e');
        // Continue to create a new channel if query fails
      }

      // If no channel exists for this user-poster pair, create one
      if (channel == null) {
        try {
          // Get profile information for both users
          final supabase = Supabase.instance.client;
          final posterProfile = await supabase
              .from('taskaway_profiles')
              .select()
              .eq('id', task.posterId)
              .single();

          final currentUserProfile = await supabase
              .from('taskaway_profiles')
              .select()
              .eq('id', currentUser.id)
              .single();

          // Create channel between current user and poster
          // We use the current user in the "tasker" fields for channel structure
          channel = await messageController.initiateTaskConversation(
            taskId: widget.taskId,
            taskTitle: task.title,
            posterId: task.posterId,
            posterName: posterProfile['full_name'] ?? 'Poster',
            taskerId: currentUser.id,  // Current user as "tasker" for channel creation
            taskerName: currentUserProfile['full_name'] ?? 'User',
            welcomeMessage: 'Hi! I\'m interested in your task "${task.title}". I\'d like to know more about the requirements and discuss how I can help.',
          );

          // Show success message for new channel creation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat channel created! You can now message the poster.'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          print('Failed to create channel: $e');
          throw Exception('Failed to create chat channel. Please try again.');
        }
      }

      if (channel != null && mounted) {
        // Navigate to chat screen with channel object
        await context.pushNamed('chat-room',
          pathParameters: {'id': channel.id},
          extra: channel);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFFFFDB5B); // Yellow
      case 'in_progress':
        return Colors.blue;
      case 'pending_approval':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.access_time;
      case 'in_progress':
        return Icons.work_outline;
      case 'pending_approval':
        return Icons.rate_review;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusTitle(String status, bool isPoster) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return isPoster ? 'Waiting for Tasker to Start' : 'Ready to Start';
      case 'in_progress':
        return isPoster ? 'Tasker is Working' : 'Task in Progress';
      case 'pending_approval':
        return isPoster ? 'Review Required' : 'Awaiting Approval';
      case 'completed':
        return 'Task Completed';
      default:
        return 'Task Status';
    }
  }

  String _getStatusDescription(String status, bool isPoster) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return isPoster
            ? 'Your offer has been accepted. The tasker will start working on your task soon.'
            : 'You have accepted this task. Click "Start Task" when you\'re ready to begin work.';
      case 'in_progress':
        return isPoster
            ? 'The tasker is currently working on your task. You\'ll be notified when it\'s complete.'
            : 'You are currently working on this task. Click "Mark Complete" when you finish.';
      case 'pending_approval':
        return isPoster
            ? 'The tasker has marked this task as complete. Please review the work and approve or request changes.'
            : 'You have marked this task as complete. Waiting for the poster to review and approve your work.';
      case 'completed':
        return isPoster
            ? 'This task has been completed and approved. Payment has been released to the tasker.'
            : 'This task has been completed and approved. Payment has been released to you.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskAsyncValue = ref.watch(taskProvider(widget.taskId));
    final currentUser = ref.watch(currentUserProvider);
    final currentProfileAsyncValue = ref.watch(currentProfileProvider);
    final currentProfile = currentProfileAsyncValue.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppColors.textPrimary),
          onPressed: () {
            // Try to pop if possible, otherwise navigate to home
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home/browse');
            }
          },
        ),
        title: Text(
          'Task Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.48,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.borderLight,
            height: 1,
          ),
        ),
      ),
      body: Stack(
        children: [
          taskAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (task) {
              final isPoster = currentUser?.id == task.posterId;
              final posterProfileAsyncValue = ref.watch(profileProvider(task.posterId));

              return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Profile and Task Title Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster Profile Row
                      posterProfileAsyncValue.when(
                        data: (posterProfile) => Row(
                          children: [
                            // Profile Image
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.backgroundTertiary,
                              ),
                              child: posterProfile?.avatarUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        posterProfile!.avatarUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.person,
                                            size: 30,
                                            color: AppColors.textTertiary,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: AppColors.textTertiary,
                                    ),
                            ),
                            const SizedBox(width: 8),
                            // Name and Rating
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  posterProfile?.fullName ?? 'Unknown User',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ...List.generate(5, (index) => Icon(
                                      Icons.star,
                                      size: 17,
                                      color: index < 4 ? AppColors.star : AppColors.star,
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => Text('Error loading poster'),
                      ),
                      const SizedBox(height: 20),
                      // Task Title
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
                  const SizedBox(height: 16),

                  // Status Banner for Both Poster and Tasker
                  if (['accepted', 'in_progress', 'pending_approval', 'completed'].contains(task.status.toLowerCase())) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(task.status).withOpacity(0.1),
                        borderRadius: AppRadius.md,
                        border: Border.all(
                          color: _getStatusColor(task.status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getStatusColor(task.status).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getStatusIcon(task.status),
                              color: _getStatusColor(task.status),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getStatusTitle(task.status, isPoster),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(task.status),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getStatusDescription(task.status, isPoster),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Task Images Row - Scrollable
                  if (task.images != null && task.images!.isNotEmpty) ...[
                    SizedBox(
                      height: 100,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            // Display real task images
                            ...task.images!.asMap().entries.map((entry) {
                              final index = entry.key;
                              final imageUrl = entry.value;
                              // First image is slightly narrower (94px), others are 96px
                              final width = index == 0 ? 94.0 : 96.0;

                              return Padding(
                                padding: EdgeInsets.only(right: index < task.images!.length - 1 ? 7 : 0),
                                child: Container(
                                  width: width,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: AppRadius.smMd,
                                    color: AppColors.backgroundTertiary,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: AppRadius.smMd,
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: AppColors.backgroundTertiary,
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 30,
                                            color: AppColors.textTertiary,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            // Add more images button if there are less than 4 images
                            if (task.images!.length < 4) ...[
                              const SizedBox(width: 7),
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.smMd,
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    size: 24,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Show placeholder when no images
                    SizedBox(
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.smMd,
                          border: Border.all(color: AppColors.borderLight),
                          color: AppColors.backgroundSecondary,
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 32,
                                color: AppColors.textTertiary,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'No images',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
                  const SizedBox(height: 20),

                  // Description Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.category,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.tag,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              task.location,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
                  const SizedBox(height: 20),

                  // Schedule Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('d MMM yyyy').format(task.scheduledTime),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('h:mm a').format(task.scheduledTime),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
                  const SizedBox(height: 20),

                  // Task Budget Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Budget',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM ${task.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  if (isPoster && task.status == 'open') ...[
                    // View Offers Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.goNamed('find-tasker', pathParameters: {'taskId': widget.taskId});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primaryDark),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.xs,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'View Offers',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Revise Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _showReviseBudgetDialog(context, task);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.xs,
                          ),
                        ),
                        child: Text(
                          'Revise',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cancel Task Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _showCancelTaskDialog(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.xs,
                          ),
                        ),
                        child: Text(
                          'Cancel Task',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Make Offer and Message Buttons for non-poster users
                  if (!isPoster && currentUser != null) ...[
                    FutureBuilder<Map<String, dynamic>?>(
                      future: ref.read(taskControllerProvider).checkExistingApplication(
                        widget.taskId,
                        currentUser.id,
                      ),
                      builder: (context, snapshot) {
                        final hasExistingOffer = snapshot.data != null;
                        final isVerified = currentProfile?.bankVerificationStatus == 'verified';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Make an Offer Button or Submitted Offer Button
                                if (task.status == 'open' && currentUser.id != task.taskerId)
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: (hasExistingOffer || !isVerified) ? null : () {
                                        // Navigate to apply/offer screen
                                        context.push('/home/browse/${widget.taskId}/apply');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: (hasExistingOffer || !isVerified)
                                            ? AppColors.backgroundDisabled
                                            : AppColors.primary,
                                        side: BorderSide(
                                          color: (hasExistingOffer || !isVerified)
                                              ? AppColors.borderDark
                                              : AppColors.primaryDark,
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: AppRadius.xs,
                                        ),
                                        elevation: 0,
                                        disabledBackgroundColor: AppColors.backgroundDisabled,
                                      ),
                                      child: Text(
                                        hasExistingOffer ? 'Submitted Offer' : 'Make an Offer',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: (hasExistingOffer || !isVerified)
                                              ? AppColors.textTertiary
                                              : AppColors.textPrimary,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Add spacing only if Make an Offer button is shown
                                if (task.status == 'open' && currentUser.id != task.taskerId)
                                  const SizedBox(width: 11),

                                // Message Button (Icon only)
                                SizedBox(
                                  width: 44,
                                  height: 46,
                                  child: OutlinedButton(
                                    onPressed: () => _navigateToChat(context),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: AppColors.borderLight),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.xs,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.message_outlined,
                                      size: 20,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Bank verification warning
                            if (!isVerified && task.status == 'open' && currentUser.id != task.taskerId && !hasExistingOffer) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Bank verification required to apply for tasks',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.orange.shade900,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.push('/profile/bank-details'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.orange.shade700,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                      ),
                                      child: const Text('Verify Now'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],

                  // Task Workflow Action Buttons
                  if (currentUser != null) ...[
                    const SizedBox(height: 16),

                    // Tasker Actions
                    if (currentUser.id == task.taskerId) ...[
                      // Start Task Button (when status = 'accepted')
                      if (task.status.toLowerCase() == 'accepted')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await ref.read(taskControllerProvider).startTask(widget.taskId);
                                // Force refresh the task data
                                ref.invalidate(taskProvider(widget.taskId));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Task started! Good luck!')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryYellow,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Start Task',
                              style: TextStyle(
                                fontFamily: 'Instrument Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlack,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ),

                      // Mark Complete Button (when status = 'in_progress')
                      if (task.status.toLowerCase() == 'in_progress')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await ref.read(taskControllerProvider).completeTask(widget.taskId);
                                // Force refresh the task data
                                ref.invalidate(taskProvider(widget.taskId));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Task marked as complete! Waiting for poster approval.')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Mark Complete',
                              style: TextStyle(
                                fontFamily: 'Instrument Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textWhite,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ),
                    ],

                    // Poster Actions
                    if (isPoster) ...[
                      // Approve and Request Revisions Buttons (when status = 'pending_approval')
                      if (task.status.toLowerCase() == 'pending_approval') ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showRequestRevisionsDialog(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.borderDark),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                child: const Text(
                                  'Request Changes',
                                  style: TextStyle(
                                    fontFamily: 'Instrument Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlack,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showApproveTaskDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Approve Task',
                                  style: TextStyle(
                                    fontFamily: 'Instrument Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textWhite,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],

                  const SizedBox(height: 100), // Bottom padding for navigation bar
                ],
              ),
            ),
          );
        },
      ),
      if (_isLoading)
        Container(
          color: AppColors.backgroundOverlay,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
    ],
  ),
);
  }

  void _showReviseBudgetDialog(BuildContext context, Task task) {
    final TextEditingController priceController = TextEditingController(
      text: task.price.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Revise Budget'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Budget (RM)',
            prefixText: 'RM ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice != null && newPrice > 0) {
                ref.read(taskControllerProvider).updateTask(
                  widget.taskId,
                  {'price': newPrice},
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget updated successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Update',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cancel Task?'),
        content: Text(
          'Are you sure you want to cancel this task? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(taskControllerProvider).cancelTask(widget.taskId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task cancelled successfully')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Task?'),
        content: const Text(
          'Are you satisfied with the work? Approving will release the payment to the tasker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(taskControllerProvider).approveTask(widget.taskId);
                // Force refresh the task data
                ref.invalidate(taskProvider(widget.taskId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task approved! Payment released to tasker.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'Approve & Release Payment',
              style: TextStyle(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestRevisionsDialog(BuildContext context) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Changes'),
        content: TextField(
          controller: notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'What needs to be changed?',
            hintText: 'Please describe what needs to be revised...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notes = notesController.text.trim();
              if (notes.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please provide revision details')),
                );
                return;
              }

              Navigator.pop(dialogContext);
              try {
                await ref.read(taskControllerProvider).requestRevisions(widget.taskId, notes);
                // Force refresh the task data
                ref.invalidate(taskProvider(widget.taskId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Revision request sent to tasker.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
            ),
            child: const Text(
              'Send Request',
              style: TextStyle(color: AppColors.primaryBlack),
            ),
          ),
        ],
      ),
    );
  }
}