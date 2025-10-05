import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/theme/app_colors.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

final offerAmountProvider = StateProvider.autoDispose<double?>((ref) => null);
final offerMessageProvider = StateProvider.autoDispose<String>((ref) => '');
final isSubmittingProvider = StateProvider.autoDispose<bool>((ref) => false);

class ApplyTaskScreen extends ConsumerStatefulWidget {
  final String taskId;
  const ApplyTaskScreen({super.key, required this.taskId});

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

      // Check if user has already submitted an offer
      final existingApplication = await taskController.checkExistingApplication(
        widget.taskId,
        currentUser!.id,
      );

      if (existingApplication != null) {
        setState(() {
          _errorMessage = 'You have already submitted an offer for this task.';
          _isLoading = false;
        });
        return;
      }

      // Create the offer object
      final offer = {
        'id': offerId,
        'tasker_id': currentUser.id,
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

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Apply for Task'),
        elevation: 0,
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: task.when(
        data: (taskData) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task title and details
                  Text(
                    taskData.title,
                    style: AppTypography.titleMedium,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Budget: RM${taskData.budget.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  
                  // Amount field
                  Text(
                    'Your Offer Amount',
                    style: AppTypography.labelMedium,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundTertiary,
                      border: Border.all(color: AppColors.borderDefault),
                      borderRadius: AppRadius.md,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text(
                            'RM',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: AppTypography.bodyMedium,
                            decoration: const InputDecoration(
                              hintText: 'Enter amount',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundTertiary,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.only(right: 16, top: 14, bottom: 14),
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
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  
                  // Message field
                  Text(
                    'Message to Poster',
                    style: AppTypography.labelMedium,
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 6,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Describe why you\'re a good fit for this task',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundTertiary,
                      contentPadding: EdgeInsets.all(AppSpacing.lg),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.md,
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.md,
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.md,
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: AppRadius.md,
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: AppRadius.md,
                        borderSide: BorderSide(color: AppColors.borderDefault),
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
                    SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: AppRadius.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.error),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  SizedBox(height: AppSpacing.xxxl),
                  
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md,
                          side: const BorderSide(
                            color: AppColors.primaryDark,
                            width: 1,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: AppColors.textPrimary)
                          : Text(
                              'Submit Offer',
                              style: AppTypography.labelMedium,
                            ),
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
