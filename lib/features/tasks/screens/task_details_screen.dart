import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/core/constants/route_constants.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/tasks/controllers/application_controller.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/features/messages/controllers/message_controller.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:taskaway/core/constants/api_constants.dart';
import 'package:taskaway/core/widgets/offer_price_modal.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;
  
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  // Accept application method
  Future<void> _acceptApplication(String applicationId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final applicationController = ref.read(applicationControllerProvider);
      await applicationController.acceptApplication(applicationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application accepted successfully!')),
        );
        
        // Get the chat channel for this task
        final messageController = ref.read(messageControllerProvider);
        final channel = await messageController.getChannelByTaskId(widget.taskId);
        
        // If a channel was created, navigate to it
        if (channel != null && mounted) {
          // Navigate to chat room
          context.push('/home/chat/${channel.id}');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _shareTask(Task task) {
    final taskUrl = kIsWeb 
      ? '${Uri.base.origin}/home/tasks/${task.id}'
      : 'taskaway://home/tasks/${task.id}';
      
    final shareText = '''
Check out this task on ${StyleConstants.appName}!

${task.title}
Price: RM ${task.price.toStringAsFixed(0)}
Location: ${task.location}

$taskUrl
''';

    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final task = ref.watch(taskProvider(widget.taskId));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Task Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: task.when(
          data: (taskData) => taskData.posterId == currentUser?.id 
            ? StyleConstants.posterColorPrimary  // Purple for poster
            : StyleConstants.taskerColorPrimary, // Orange for tasker
          loading: () => StyleConstants.taskerColorPrimary,
          error: (_, __) => StyleConstants.taskerColorPrimary,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {
              if (task.value != null) {
                _shareTask(task.value!);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.black),
            onPressed: () {
              // TODO: Implement report functionality
            },
          ),
        ],
      ),
      body: task.when(
        data: (taskData) {
          final isPoster = taskData.posterId == currentUser?.id;
          final themeColor = isPoster 
            ? StyleConstants.posterColorPrimary  // Purple for poster
            : StyleConstants.taskerColorPrimary; // Orange for tasker

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Posted by section
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey[200],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Posted by',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '1 day ago',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Mike J.',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      ...List.generate(5, (index) {
                                        return Icon(
                                          Icons.star_border,
                                          size: 16,
                                          color: Colors.grey[400],
                                        );
                                      }),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(No reviews yet)',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Task details
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'I am currently in need of maid services',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: themeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Open',
                                    style: TextStyle(
                                      color: themeColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Location',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Text(
                                      'USJ 4, Subang Jaya, Selangor',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Date
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'To be done before',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Text(
                                      'Tuesday, 6 February',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Time
                            Row(
                              children: [
                                Icon(Icons.access_time_outlined, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'At what time',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Text(
                                      '9AM to 2PM',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Details section
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Seeking maid service for household cleaning duties. Reliable and detail-oriented candidates preferred.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '* Materials are provided',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom section with budget and offer button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Task Budget',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'RM 100',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isPoster) {
                            // Show review screen for poster
                            context.push('/review', extra: {
                              'taskerId': taskData.taskerId!,
                              'taskId': taskData.id,
                              'taskerName': taskData.taskerProfile?['full_name'] ?? 'Unknown',
                              'taskerAvatarUrl': taskData.taskerProfile?['avatar_url'],
                              'totalPaid': taskData.price,
                            });
                          } else {
                            // Show offer price modal for tasker
                            showDialog(
                              context: context,
                              builder: (context) => OfferPriceModal(
                                initialPrice: taskData.price,
                                onPriceSubmitted: (price) {
                                  // Navigate to apply screen with the price
                                  context.go('/home/tasks/${taskData.id}/apply', extra: {'offerPrice': price});
                                },
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isPoster ? 'Release Payment' : 'Offer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading task: $error'),
        ),
      ),
    );
  }
}
