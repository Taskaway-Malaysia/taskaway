import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/core/constants/api_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:taskaway/core/widgets/numpad_overlay.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/applications/controllers/application_controller.dart';
import 'package:taskaway/features/applications/models/application.dart';
import 'package:taskaway/features/messages/controllers/message_controller.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/payments/controllers/payment_controller.dart';
import 'package:taskaway/features/tasks/models/task.dart';
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

  // Accept offer method - now uses payment-first flow
  Future<void> _acceptOffer(String offerId, String taskerId, double price) async {
    print('UI: _acceptOffer started with payment-first flow.');
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final applicationController = ref.read(applicationControllerProvider.notifier);
      print('UI: Calling controller.initiateOfferAcceptance...');
      final paymentData = await applicationController.initiateOfferAcceptance(
        applicationId: offerId,
        taskId: widget.taskId,
        taskerId: taskerId,
      );
      print('UI: controller.initiateOfferAcceptance returned payment data');

      if (mounted) {
        print('UI: Navigating to payment method selection screen...');
        context.push('/payment/method-selection', extra: {
          'paymentId': paymentData['paymentIntentId'],
          'clientSecret': paymentData['clientSecret'],
          'amount': paymentData['amount'],
          'taskTitle': paymentData['taskTitle'],
          'paymentType': 'offer_acceptance',
          'applicationId': paymentData['applicationId'],
          'taskId': paymentData['taskId'],
          'taskerId': paymentData['taskerId'],
          'offerPrice': paymentData['offerPrice'],
        });
      }
    } catch (e, st) {
      print('UI: _acceptOffer caught an error: $e\nStackTrace: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  // Navigate to chat method
  Future<void> _navigateToChat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messageController = ref.read(messageControllerProvider);
      var channel = await messageController.getChannelByTaskId(widget.taskId);
      
      // If no channel exists, try to create one as a fallback
      if (channel == null) {
        final task = ref.read(taskProvider(widget.taskId)).value;
        final currentUser = ref.read(currentUserProvider);
        
        if (task != null && currentUser != null) {
          // Determine if current user is poster or tasker
          final isPoster = currentUser.id == task.posterId;
          
          // Only create channel if task has both poster and tasker assigned
          if (task.taskerId != null) {
            try {
              // Get profile information for channel creation
              final supabase = Supabase.instance.client;
              final posterProfile = await supabase
                  .from('taskaway_profiles')
                  .select()
                  .eq('id', task.posterId)
                  .single();
              
              final taskerProfile = await supabase
                  .from('taskaway_profiles')
                  .select()
                  .eq('id', task.taskerId!)
                  .single();
              
              // Create the channel
              channel = await messageController.initiateTaskConversation(
                taskId: widget.taskId,
                taskTitle: task.title,
                posterId: task.posterId,
                posterName: posterProfile['full_name'] ?? 'Poster',
                taskerId: task.taskerId!,
                taskerName: taskerProfile['full_name'] ?? 'Tasker',
                welcomeMessage: isPoster 
                  ? 'Hi! Let\'s discuss the details of "${task.title}".'
                  : 'Hi! I\'m ready to work on "${task.title}". Let\'s discuss the details.',
              );
            } catch (e) {
              print('Failed to create channel as fallback: $e');
            }
          }
        }
      }
      
      if (channel != null && mounted) {
        // Navigate to chat screen with channel object
        await context.pushNamed('chat-room', 
          pathParameters: {'id': channel.id}, 
          extra: channel);
      } else {
        setState(() {
          _errorMessage = 'No conversation found for this task. Please ensure the task has been accepted.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to open chat: ${e.toString()}';
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

          // Debug logs
          final statusLc = taskData.status.trim().toLowerCase();
          final shouldShowCancel = isPoster &&
              (statusLc == 'open' || statusLc == 'accepted');
          print(
            'Task Details: id=${taskData.id}, status=${taskData.status}, '
            'statusLc=$statusLc, isPoster=$isPoster, currentUser=${currentUser?.id}, '
            'posterId=${taskData.posterId}, shouldShowCancel=$shouldShowCancel',
          );
          print('Offers: ${taskData.offers}');
          
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
                      child: _buildBudgetSection(
                        taskData,
                        isPoster,
                        isTasker,
                        userApplication,
                        currentUser?.id,
                      ),
                    ),
                    // Start button for tasker below the budget section when offer accepted
                    // Debug logging for Start Task button
                    () {
                      print('DEBUG Start Task Button Check:');
                      print('  - taskData.taskerId: ${taskData.taskerId}');
                      print('  - currentUser?.id: ${currentUser?.id}');
                      print('  - statusLc: $statusLc');
                      print('  - taskerId == currentUserId: ${taskData.taskerId == currentUser?.id}');
                      print('  - status is accepted: ${statusLc == 'accepted'}');
                      print('  - Should show button: ${taskData.taskerId == currentUser?.id && statusLc == 'accepted'}');
                      return const SizedBox.shrink();
                    }(),
                    if (taskData.taskerId == currentUser?.id &&
                        statusLc == 'accepted') ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _startTask,
                          child: const Text('Start Task'),
                        ),
                      ),
                    ],
                    _buildSectionContainer(
                      child: _buildDetailsSection(taskData),
                    ),
                    const SizedBox(height: 24),


                    // Show offers if any
                    if (isPoster) _buildOffersSection(taskData, currentUser!.id),
                    const SizedBox(height: 16),
                    _buildActionButtons(taskData, isPoster, currentUser?.id),

                    // Dev mode quick complete button removed - no longer needed with simplified flow

                    if (_errorMessage != null) _buildErrorMessage(),
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
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.grey, size: 16),
                      Icon(Icons.star, color: Colors.grey, size: 16),
                      Icon(Icons.star, color: Colors.grey, size: 16),
                      Icon(Icons.star, color: Colors.grey, size: 16),
                      Icon(Icons.star, color: Colors.grey, size: 16),
                      SizedBox(width: 4),
                      Text('(No reviews yet)', style: TextStyle(color: Colors.grey)),
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
      Task task,
      bool isPoster,
      bool isTasker,
      Application? userApplication,
      String? currentUserId,) {
    final statusLc = task.status.trim().toLowerCase();
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
        if (isTasker && userApplication != null)
          _buildOfferStatus(userApplication),
        if (!isPoster && task.status == 'open' && userApplication == null)
          SizedBox(
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
          ),
        if (isPoster && (statusLc == 'open' || statusLc == 'accepted')) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showCancelDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Cancel Task'),
            ),
          ),
        ],
      ],
    );
  } 

  Future<void> _startTask() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(taskControllerProvider).startTask(widget.taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task started')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  


  String _readableApplicationStatus(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  Widget _buildOfferStatus(Application application) {
    final label = _readableApplicationStatus(application.status);
    return Text(
      'Your offer: RM${application.offerPrice.toStringAsFixed(2)} - $label',
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
  
  // ignore: unused_element
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
          // Initialize payment flow instead of directly completing task
          final task = await ref
              .read(taskControllerProvider)
              .getTaskById(widget.taskId);
          final taskerId = task.taskerId;
          if (taskerId == null) {
            throw Exception('No tasker assigned to this task');
          }

          final init = await ref.read(paymentControllerProvider).handleTaskApproval(
                taskId: widget.taskId,
                posterId: task.posterId,
                taskerId: taskerId,
                amount: task.price,
                taskTitle: task.title,
              );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecting to payment authorization...'),
              ),
            );
            context.push('/payment/authorize', extra: init);
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
              // Safely extract all data from the offer map.
              final offer = offers[index];
              final taskerProfile = offer['tasker_profile'] as Map<String, dynamic>?;

              final offerId = offer['id'] as String;
              final taskerId = offer['tasker_id'] as String;
              final price = (offer['offer_price'] as num?)?.toDouble() ?? 0.0; // Changed from 'price' to 'offer_price'
              final message = offer['message'] as String? ?? 'No message provided';
              final status = offer['status'] as String? ?? 'pending';
              final taskerName = taskerProfile?['full_name'] as String? ?? 'Anonymous Tasker';
              final avatarUrl = taskerProfile?['avatar_url'] as String?;
              const timeAgo = '1 day ago'; // Placeholder

              // Build the UI for a single offer item.
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl == null ? const Icon(Icons.person, size: 24) : null,
                          ),
                          const SizedBox(width: 12),
                          // Tasker Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Offered by', style: TextStyle(color: Colors.grey)),
                                Text(taskerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.grey, size: 16),
                                    SizedBox(width: 4),
                                    Text('(No reviews yet)', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Price and Time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(timeAgo, style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                'RM${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: StyleConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Message
                      Text(message),
                      const SizedBox(height: 16),
                      // Accept Button
                      if (status == 'pending')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _acceptOffer(offerId, taskerId, price),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: StyleConstants.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Accept'),
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'accepted' ? Colors.green.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status == 'accepted' ? 'Accepted' : 'Rejected',
                              style: TextStyle(
                                color: status == 'accepted' ? Colors.green.shade800 : Colors.grey.shade800,
                                fontWeight: FontWeight.bold,
                              ),
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
      case 'pending':
        return 'Pending';
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
      case 'pending':
        return Colors.orange;
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

  Widget _buildActionButtons(Task task, bool isPoster, String? currentUserId) {
    final List<Widget> buttons = [];
    
    // Add Message button for active tasks (pending, in_progress, pending_approval)
    // Show for both poster and assigned tasker
    final canShowMessage = (task.status == 'accepted' || 
                            task.status == 'in_progress' || 
                            task.status == 'pending_approval') &&
                           (isPoster || currentUserId == task.taskerId);
    
    if (canShowMessage) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToChat,
            icon: const Icon(Icons.message),
            label: Text(isPoster ? 'Message Tasker' : 'Message Poster'),
            style: ElevatedButton.styleFrom(
              backgroundColor: StyleConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
      buttons.add(const SizedBox(height: 8));
    }
    
    // Existing action buttons
    if (isPoster) {
      if (task.status == 'pending_approval') {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _approveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve Completion'),
            ),
          ),
        );
      }
    } else {
      if (task.status == 'in_progress' && currentUserId == task.taskerId) {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completeTask,
              child: const Text('Submit for Review'),
            ),
          ),
        );
      }
    }
    
    return buttons.isEmpty ? const SizedBox.shrink() : Column(children: buttons);
  }

  Future<void> _approveTask() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      // Capture the existing payment from offer acceptance
      // No new payment needed - we're capturing the escrow payment
      await ref.read(paymentControllerProvider).captureTaskPayment(
        taskId: widget.taskId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task approved and payment captured successfully!')),
        );
        // Refresh the screen to show updated status
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeTask() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(taskControllerProvider).completeTask(widget.taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task submitted for review!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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

  Future<void> _cancelTask() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(taskControllerProvider).cancelTask(widget.taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Task?'),
        content: const Text(
          'Are you sure you want to cancel this task? This action cannot be undone.',
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 140,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelTask();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, cancel'),
            ),
          ),
        ],
      ),
    );
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
