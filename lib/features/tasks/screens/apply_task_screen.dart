import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/tasks/controllers/application_controller.dart';
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

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final applicationController = ref.read(applicationControllerProvider);
      final amount = double.parse(_amountController.text);
      final message = _messageController.text;

      // Submit the application
      await applicationController.submitApplication(
        taskId: widget.taskId,
        offerPrice: amount,
        message: message,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
        // Navigate back to the previous screen
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit application: ${e.toString()}';        
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
                  // Task Title
                  Text(
                    taskData.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Offer Amount
                  Text(
                    'Your Offer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      hintText: 'Enter your offer amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null) {
                        return 'Please enter a valid number';
                      }
                      if (amount <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Message
                  Text(
                    'Message to Task Poster',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Explain why you\'re the best person for this task...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a message';
                      }
                      if (value.length < 10) {
                        return 'Message must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Error Message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Application'),
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
