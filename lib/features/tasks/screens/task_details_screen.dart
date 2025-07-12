import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';

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
  bool _isRevisingBudget = false;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        elevation: 0,
        backgroundColor: isTasker ? StyleConstants.taskerColorPrimary : Colors.white,
        foregroundColor: isTasker ? Colors.white : Colors.black,
      ),
      body: taskAsyncValue.when(
        data: (taskData) {
          // Set role flags based on data
          isPoster = currentUser?.id == taskData.posterId;
          isTasker = currentProfile?.role == 'tasker';
          
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionContainer(
                      child: _buildPosterInfo(taskData, ref),
                    ),
                    _buildSectionContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTaskHeader(taskData),
                          const SizedBox(height: 24),
                          _buildTaskDetails(taskData),
                          const SizedBox(height: 24),
                          _buildTaskSchedule(taskData),
                        ],
                      ),
                    ),
                    _buildSectionContainer(
                      child: _buildBudgetSection(taskData, isPoster, isTasker, userApplication),
                    ),
                    _buildSectionContainer(
                      child: _buildDetailsSection(taskData),
                    ),
                    const SizedBox(height: 24),
                    // Show offers if any
                    if (isPoster && (taskData.offers?.isNotEmpty ?? false)) 
                      _buildOffersSection(taskData, currentUser!.id),

                    if (_errorMessage != null) _buildErrorMessage(),

                    // Action buttons for poster when task is pending approval
                    if (isPoster && taskData.status == 'pending_approval') ...[
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
                        if (_isRevisingBudget) {
                          // Handle budget revision
                          final taskController = ref.read(taskControllerProvider);
                          await taskController.updateTask(widget.taskId, {'price': offerPrice});
                          if (localContext.mounted) {
                            ScaffoldMessenger.of(localContext).showSnackBar(
                              const SnackBar(content: Text('Budget updated successfully')),
                            );
                          }
                        } else {
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            task.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildStatusBadge(task.status),
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
    final posterProfileAsyncValue =
        ref.watch(profileProvider(task.posterId));
    return posterProfileAsyncValue.when(
      data: (posterProfile) {
        return Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: posterProfile?.avatarUrl != null
                ? NetworkImage(posterProfile!.avatarUrl!)
                : null,
              child: posterProfile?.avatarUrl == null
                  ? const Icon(Icons.person, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    posterProfile?.fullName ?? 'Unknown Poster',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.grey, size: 16),
                      const Icon(Icons.star, color: Colors.grey, size: 16),
                      const Icon(Icons.star, color: Colors.grey, size: 16),
                      const Icon(Icons.star, color: Colors.grey, size: 16),
                      const Icon(Icons.star, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      const Text('(No reviews yet)', style: TextStyle(color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            Text(
              '1 day ago', // This should be calculated
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Text('Error loading poster info'),
    );
  }
  
  Widget _buildDetailsSection(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(task.description),
        if (task.images != null && task.images!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Images', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: task.images!.length,
              itemBuilder: (context, index) {
                final imageUrl = task.images![index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, size: 40);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (task.providesMaterials == true) ...[
          const Text(
            '* Materials are provided by the poster.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
          ),
        ] else ...[
          const Text(
            '* You are expected to provide your own materials.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
          ),
        ],
      ],
    );
  }
  
  Widget _buildBudgetSection(
      Task task, bool isPoster, bool isTasker, Application? userApplication) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
      children: [
        const Text(
          'Task Budget',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'RM${task.price.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: StyleConstants.primaryColor),
        ),
        const SizedBox(height: 16),
        if (isPoster && task.status == 'open')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isRevisingBudget = true;
                  _offerPriceController.text = task.price.toStringAsFixed(2);
                  _showNumpad = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: StyleConstants.primaryColor, // Poster color
                foregroundColor: Colors.white,
              ),
              child: const Text('Revise'),
            ),
          ),
        if (isTasker && userApplication != null) ...[
          _buildOfferStatus(userApplication),
        ] else if (isTasker && task.status == 'open') ...[
          _buildApplyButton(context),
        ],
      ],
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _isRevisingBudget = false;
            _offerPriceController.clear();
            _showNumpad = true;
          });
        },
        child: const Text('Make an Offer'),
      ),
    );
  }

  Widget _buildOfferStatus(Application application) {
    // Placeholder for offer status
    return Text('Your offer: RM${application.offerPrice.toStringAsFixed(2)} - ${application.status}');
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
  
  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getReadableStatus(status),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
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

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
