import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/core/constants/route_constants.dart';
import 'package:taskaway/core/widgets/numpad_overlay.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/applications/controllers/application_controller.dart';
import 'package:taskaway/features/applications/models/application.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/tasks/models/task.dart';
import 'package:taskaway/features/messages/controllers/message_controller.dart';
import 'package:intl/intl.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;
  
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _revisionNotes;
  final TextEditingController _offerPriceController = TextEditingController();
  bool _showNumpad = false;

  // Accept offer method
  Future<void> _acceptOffer(String offerId, String taskerId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final taskController = ref.read(taskControllerProvider);
      await taskController.acceptOffer(widget.taskId, offerId, taskerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer accepted successfully!')),
        );
        
        // Get the chat channel for this task
        final messageController = ref.read(messageControllerProvider);
        final channel = await messageController.getChannelByTaskId(widget.taskId);
        
        // If a channel was created, navigate to it
        if (channel != null && mounted) {
          // Navigate to chat room
          await context.push('/home/chat/${channel.id}');
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

  @override
  void dispose() {
    _offerPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskAsyncValue = ref.watch(taskProvider(widget.taskId));
    final currentUser = ref.watch(currentUserProvider); // Directly a User object
    final currentProfileAsyncValue = ref.watch(currentProfileProvider);
    final currentProfile = currentProfileAsyncValue.asData?.value;
    
    // Watch for user's application for this task
    final userApplicationAsyncValue = ref.watch(userApplicationForTaskProvider(widget.taskId));
    final userApplication = userApplicationAsyncValue.asData?.value;
    
    // Determine if user is poster or tasker
    bool isPoster = false;
    bool isTasker = false;
    bool hasOffers = false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: taskAsyncValue.when(
        data: (taskData) {
          // Set role flags based on data
          isPoster = currentUser?.id == taskData.posterId;
          isTasker = currentProfile?.role == 'tasker';
          hasOffers = taskData.offers != null && taskData.offers!.isNotEmpty;
          
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPosterInfo(taskData, ref),
                    const SizedBox(height: 16),
                    _buildTaskHeader(taskData),
                    const SizedBox(height: 16),
                    _buildTaskDetails(taskData),
                    const SizedBox(height: 16),
                    _buildBudgetSection(taskData, isPoster, isTasker, userApplication),
                    const SizedBox(height: 24),
                    Text('Details', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(taskData.description),
                    if (taskData.images != null && taskData.images!.isNotEmpty)
                      _buildTaskImages(taskData),
                    const SizedBox(height: 24),
                    // Task schedule
                    _buildTaskSchedule(taskData),
                    const SizedBox(height: 24),
                    
                    // Apply button (for non-posters when task is open)
                    if (!isPoster && taskData.status == 'open')
                      _buildApplyButton(context),
                      
                    // Error message
                    if (_errorMessage != null)
                      _buildErrorMessage(),
                      
                    const SizedBox(height: 24),
                    
                    // Offers section (only for poster)
                    if (isPoster && hasOffers)
                      _buildOffersSection(taskData, currentUser?.id ?? ''),
                      
                    // Status section (for assigned tasks)
                    if (taskData.status != 'open')
                      _buildStatusSection(taskData, isPoster, isTasker),
                  ],
                ),
              ),
              if (_showNumpad)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: NumpadOverlay(
                    onDigitPressed: (digit) {
                      setState(() {
                        final currentText = _offerPriceController.text;
                        // Only allow one decimal point
                        if (digit == '.' && currentText.contains('.')) {
                          return;
                        }
                        // Max 2 decimal places
                        if (currentText.contains('.') && 
                            currentText.split('.')[1].length >= 2) {
                          return;
                        }
                        // Max 6 digits before decimal
                        if (!currentText.contains('.') && 
                            currentText.length >= 6) {
                          return;
                        }
                        
                        _offerPriceController.text += digit;
                      });
                    },
                    onBackspacePressed: () {
                      setState(() {
                        final currentText = _offerPriceController.text;
                        if (currentText.isNotEmpty) {
                          _offerPriceController.text = 
                              currentText.substring(0, currentText.length - 1);
                        }
                      });
                    },
                    onConfirmPressed: () async {
                      if (currentUser == null) return;

                      // --- Capture context and state before any async gaps ---
                      final localContext = context;
                      final isUpdate = userApplication != null;
                      final price = _offerPriceController.text;
                      // --- End capture ---

                      final offerPrice = double.tryParse(price);
                      if (offerPrice == null || offerPrice <= 0) {
                        if (mounted) {
                          setState(() {
                            _errorMessage = 'Please enter a valid offer price.';
                          });
                        }
                        return;
                      }

                      if (mounted) {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                          _showNumpad = false;
                        });
                      }

                      try {
                        // Submit offer through application controller
                        final applicationController = ref.read(applicationControllerProvider.notifier);
                        await applicationController.submitOffer(
                          taskId: widget.taskId,
                          taskerId: currentUser.id,
                          offerPrice: offerPrice,
                        );

                        if (localContext.mounted) {
                          ScaffoldMessenger.of(localContext).showSnackBar(
                            SnackBar(
                              content: Text(isUpdate
                                  ? 'Your offer has been updated'
                                  : 'Your offer has been submitted'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          final errorMsg = e.toString();
                          setState(() {
                            _errorMessage = errorMsg;
                          });
                          if (localContext.mounted) {
                            ScaffoldMessenger.of(localContext).showSnackBar(
                              SnackBar(content: Text('Error: $errorMsg')),
                            );
                          }
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                    confirmButtonText: 'Done',
                    previewController: _offerPriceController,
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
  
  Widget _buildTaskHeader(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          task.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        
        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(task.status),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getReadableStatus(task.status),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Price
        Text(
          'RM${task.price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: StyleConstants.primaryColor,
              ),
        ),
      ],
    );
  }
  
  Widget _buildTaskDetails(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(task.description),
        const SizedBox(height: 16),
        
        // Category
        _buildDetailItem(Icons.category_outlined, task.category),
        
        // Location
        _buildDetailItem(Icons.location_on_outlined, task.location),
      ],
    );
  }
  
  Widget _buildDetailItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  Widget _buildTaskSchedule(Task task) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _buildDetailItem(
          Icons.calendar_today_outlined,
          dateFormat.format(task.scheduledTime),
        ),
        _buildDetailItem(
          Icons.access_time_outlined,
          timeFormat.format(task.scheduledTime),
        ),
      ],
    );
  }
  
  Widget _buildPosterInfo(Task task, WidgetRef ref) {
    final posterProfileAsyncValue = ref.watch(profileProvider(task.posterId));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          posterProfileAsyncValue.when(
            data: (profile) => CircleAvatar(
              radius: 24,
              backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              child: (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            loading: () => const CircleAvatar(radius: 24, child: CircularProgressIndicator()),
            error: (err, stack) => const CircleAvatar(radius: 24, child: Icon(Icons.error)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Posted by', style: TextStyle(color: Colors.grey)),
                posterProfileAsyncValue.when(
                  data: (profile) => Text(
                    profile?.fullName ?? 'Unknown Poster',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  loading: () => const Text('Loading...'),
                  error: (err, stack) => const Text('Error'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTaskImages(Task task) {
    final images = task.images ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Images',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageUrl = images[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.error_outline, color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildBudgetSection(Task task, bool isPoster, bool isTasker, Application? userApplication) {
    final backgroundColor = isTasker ? StyleConstants.taskerColorPrimary : StyleConstants.primaryColor;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Budget',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'RM${task.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isTasker && task.status == 'open' && !isPoster)
                  Expanded(
                    child: ElevatedButton(
                    onPressed: () {
                      // Initialize price controller with current offer if exists
                      if (userApplication != null) {
                        _offerPriceController.text = userApplication.offerPrice.toStringAsFixed(2);
                      } else {
                        _offerPriceController.text = task.price.toStringAsFixed(2);
                      }
                      
                      // Show numpad overlay
                      setState(() {
                        _showNumpad = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: backgroundColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(userApplication != null ? 'Re-offer' : 'Offer'),
                  ),
                  ),
              ],
            ),
            
            // Show user's offer if they've made one
            if (isTasker && userApplication != null) ...[  // Use spread operator instead
              // Add SizedBox for spacing and to fix constraints
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Offer', style: TextStyle(color: Colors.grey)),
                      Text(
                        'RM${userApplication.offerPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => context.push('${RouteConstants.applyTask}/${widget.taskId}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: StyleConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Apply for this Task'),
      ),
    );
  }
  
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
  
  // Method to update task status based on the action
  Future<void> _updateTaskStatus(String action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final taskController = ref.read(taskControllerProvider);
      
      switch (action) {
        case 'start':
          await taskController.startTask(widget.taskId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task started! You can now begin work.')),
            );
          }
          break;
          
        case 'complete':
          await taskController.completeTask(widget.taskId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task marked as complete! Waiting for poster approval.')),
            );
          }
          break;
          
        case 'approve':
          await taskController.approveTask(widget.taskId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task approved! Payment will be processed.')),
            );
          }
          break;
          
        case 'revise':
          if (_revisionNotes != null) {
            await taskController.requestRevisions(widget.taskId, _revisionNotes);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Revision requested. The tasker has been notified.')),
              );
            }
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Show dialog to enter revision notes
  void _showRevisionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Revisions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide details about what needs to be revised:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Revision details',
              ),
              maxLines: 3,
              onChanged: (value) {
                _revisionNotes = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateTaskStatus('revise');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: StyleConstants.primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOffersSection(Task task, String currentUserId) {
    final offers = task.offers ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offers (${offers.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (offers.isEmpty)
          const Text('No offers yet.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              final offerId = offer['id'];
              final taskerId = offer['tasker_id'];
              final amount = (offer['amount'] is num) ? (offer['amount'] as num).toDouble() : 0.0;
              final message = offer['message'];
              final status = offer['status'] ?? 'pending';
              final taskerProfile = task.offers?[index]['tasker_profile'] as Map<String, dynamic>?;
              final taskerName = taskerProfile?['full_name'] as String? ?? 'Unknown Tasker';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tasker name and offer amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            taskerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'RM${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: StyleConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Message
                      Text(message),
                      const SizedBox(height: 16),
                      
                      // Accept button
                      if (status == 'pending')
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _acceptOffer(offerId, taskerId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade500,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Accept Offer'),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: status == 'accepted' ? Colors.green.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status == 'accepted' ? 'Accepted' : 'Rejected',
                            style: TextStyle(
                              color: status == 'accepted' ? Colors.green.shade800 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
  
  Widget _buildStatusSection(Task task, bool isPoster, bool isTasker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        
        // Status info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusDescription(task.status),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              
              if (isTasker && (task.status == 'assigned' || task.status == 'in_progress')) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (task.status == 'assigned')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _updateTaskStatus('start');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Work'),
                        ),
                      ),
                    if (task.status == 'in_progress')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _updateTaskStatus('complete');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StyleConstants.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Mark as Completed'),
                        ),
                      ),
                  ],
                ),
              ],
              
              if (isPoster && task.status == 'pending_approval') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _updateTaskStatus('approve');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _showRevisionDialog();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Request Revisions'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  String _getReadableStatus(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'pending_approval':
        return 'Pending Approval';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
  
  String _getStatusDescription(String status) {
    switch (status) {
      case 'assigned':
        return 'This task has been assigned. The tasker should start work soon.';
      case 'in_progress':
        return 'The tasker is currently working on this task.';
      case 'pending_approval':
        return 'The tasker has marked this task as complete. Please review and approve or request revisions.';
      case 'completed':
        return 'This task has been completed successfully.';
      case 'cancelled':
        return 'This task has been cancelled.';
      default:
        return 'This task is open for applications.';
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return StyleConstants.primaryColor;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'pending_approval':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
