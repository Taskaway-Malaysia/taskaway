import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';

final offerAmountProvider = StateProvider.autoDispose<double?>((ref) => null);
final offerMessageProvider = StateProvider.autoDispose<String>((ref) => '');
final isSubmittingProvider = StateProvider.autoDispose<bool>((ref) => false);

class ApplyTaskScreen extends ConsumerStatefulWidget {
  final String taskId;
  final bool isBrowseContext;
  final Map<String, dynamic>? extra;
  const ApplyTaskScreen({super.key, required this.taskId, this.isBrowseContext = false, this.extra});

  @override
  ConsumerState<ApplyTaskScreen> createState() => _ApplyTaskScreenState();
}

class _ApplyTaskScreenState extends ConsumerState<ApplyTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set initial price from the modal if provided
    if (widget.extra?['offerPrice'] != null) {
      _amountController.text = widget.extra!['offerPrice'].toString();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final taskController = ref.read(taskControllerProvider);
      final currentUser = ref.read(currentUserProvider);
      final offerId = DateTime.now().millisecondsSinceEpoch.toString();
      final amount = double.parse(_amountController.text);
      final message = _messageController.text;

      // Get the task to check if the user is the poster
      final task = await taskController.getTaskById(widget.taskId);
      
      // Prevent users from applying to their own tasks
      if (task.posterId == currentUser?.id) {
        setState(() {
          _errorMessage = 'You cannot apply to your own task.';
          _isLoading = false;
        });
        return;
      }

      // Create the offer object
      final offer = {
        'id': offerId,
        'tasker_id': currentUser?.id,
        'amount': amount,
        'message': message,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add the offer to the task
      await taskController.addOffer(widget.taskId, offer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer submitted successfully!')),
        );
        // Navigate back to the previous screen
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit offer: ${e.toString()}';        
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
    final task = ref.watch(taskProvider(widget.taskId));
    final primaryColor = widget.isBrowseContext 
        ? const Color(0xFFFF9500) 
        : StyleConstants.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Task'),
        elevation: 0,
        backgroundColor: widget.isBrowseContext 
            ? const Color(0xFFFF9500) 
            : Colors.white,
        foregroundColor: widget.isBrowseContext 
            ? Colors.white 
            : Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, 
              color: widget.isBrowseContext ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: task.when(
        data: (taskData) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task title and details
                  Text(
                    taskData.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Budget: RM${taskData.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // Amount field
                  Text(
                    'Your Offer Amount (RM)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter your offer amount',
                      prefixText: 'RM ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      try {
                        final amount = double.parse(value);
                        if (amount <= 0) {
                          return 'Amount must be greater than 0';
                        }
                      } catch (e) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Message field
                  Text(
                    'Message to Poster',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe why you\'re a good fit for this task',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a message';
                      }
                      if (value.length < 10) {
                        return 'Message too short. Please provide more details.';
                      }
                      return null;
                    },
                  ),
                  
                  // Error message
                  if (_errorMessage != null) ...[  
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
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
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Offer'),
                    ),
                  ),
                ],
              ),
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
}
