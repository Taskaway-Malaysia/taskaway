import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/core/constants/route_constants.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final task = ref.watch(taskProvider(widget.taskId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: task.when(
        data: (taskData) {
          // Check if current user is the poster
          final isPoster = currentUser?.id == taskData.posterId;
          final isTasker = currentUser?.id == taskData.taskerId;
          final hasOffers = taskData.offers?.isNotEmpty ?? false;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task header
                _buildTaskHeader(taskData),
                const SizedBox(height: 24),
                
                // Task details
                _buildTaskDetails(taskData),
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
