import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/task_controller.dart';
import '../models/task.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../messages/controllers/message_controller.dart';
import '../../messages/models/channel.dart';

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
                backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
  @override
  Widget build(BuildContext context) {
    final taskAsyncValue = ref.watch(taskProvider(widget.taskId));
    final currentUser = ref.watch(currentUserProvider);
    final currentProfileAsyncValue = ref.watch(currentProfileProvider);
    final currentProfile = currentProfileAsyncValue.asData?.value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () {
            // Navigate back to home screen
            context.go('/home');
          },
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: 0.48,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE4E4E4),
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
              padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 24),
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
                                color: Colors.grey[200],
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
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey,
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
                                    fontFamily: 'Instrument Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                    letterSpacing: 0.24,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ...List.generate(5, (index) => Icon(
                                      Icons.star,
                                      size: 17,
                                      color: index < 4 ? const Color(0xFFFCC133) : const Color(0xFFFCC133),
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Error loading poster'),
                      ),
                      const SizedBox(height: 20),
                      // Task Title
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                                    borderRadius: BorderRadius.circular(6),
                                    color: Colors.grey[200],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
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
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 30,
                                            color: Colors.grey,
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
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFEDEDED)),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    size: 24,
                                    color: Color(0xFF777676),
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
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFEDEDED)),
                          color: Colors.grey[50],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 32,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'No images',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Description Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202020),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF788494),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Category: ${task.category}',
                        style: const TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF788494),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.location,
                        style: const TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF788494),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 21),

                  // Schedule Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule',
                        style: TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202020),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('d MMM yyyy').format(task.scheduledTime),
                        style: const TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF788494),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('h:mm a').format(task.scheduledTime),
                        style: const TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF788494),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 21),

                  // Task Budget Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Budget',
                        style: TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202020),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM ${task.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202020),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  if (isPoster && task.status == 'open') ...[
                    // Revise Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showReviseBudgetDialog(context, task);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFDB5B),
                          side: const BorderSide(color: Color(0xFFFFC333)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Revise',
                          style: TextStyle(
                            fontFamily: 'Instrument Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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
                          side: const BorderSide(color: Color(0xFFE4E4E4)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        child: const Text(
                          'Cancel Task',
                          style: TextStyle(
                            fontFamily: 'Instrument Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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

                        return Row(
                          children: [
                            // Make an Offer Button or Submitted Offer Button
                            if (task.status == 'open' && currentUser.id != task.taskerId)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: hasExistingOffer ? null : () {
                                    // Navigate to apply/offer screen
                                    context.push('/home/browse/${widget.taskId}/apply');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasExistingOffer
                                        ? Colors.grey.shade300
                                        : const Color(0xFFFFDB5B),
                                    side: BorderSide(
                                      color: hasExistingOffer
                                          ? Colors.grey.shade400
                                          : const Color(0xFFFFC333),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    elevation: 0,
                                    disabledBackgroundColor: Colors.grey.shade300,
                                  ),
                                  child: Text(
                                    hasExistingOffer ? 'Submitted Offer' : 'Make an Offer',
                                    style: TextStyle(
                                      fontFamily: 'Instrument Sans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: hasExistingOffer
                                          ? Colors.grey.shade600
                                          : Colors.black,
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
                                  side: const BorderSide(color: Color(0xFFE4E4E4)),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.message_outlined,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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
          color: Colors.black.withOpacity(0.3),
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
        title: const Text('Revise Budget'),
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
            child: const Text('Cancel'),
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
              backgroundColor: const Color(0xFFFFDB5B),
            ),
            child: const Text(
              'Update',
              style: TextStyle(color: Colors.black),
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
        title: const Text('Cancel Task?'),
        content: const Text(
          'Are you sure you want to cancel this task? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
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
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}