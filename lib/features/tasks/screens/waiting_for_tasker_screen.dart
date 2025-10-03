import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../controllers/task_controller.dart';
import 'dart:async';

class WaitingForTaskerScreen extends ConsumerStatefulWidget {
  final String taskId;

  const WaitingForTaskerScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<WaitingForTaskerScreen> createState() => _WaitingForTaskerScreenState();
}

class _WaitingForTaskerScreenState extends ConsumerState<WaitingForTaskerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _pollTimer;
  Task? _currentTask;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Poll for task updates every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkTaskStatus();
    });

    // Initial check
    _checkTaskStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkTaskStatus() async {
    try {
      final taskController = ref.read(taskControllerProvider);
      final task = await taskController.getTaskById(widget.taskId);

      if (mounted) {
        setState(() {
          _currentTask = task;
        });

        // Check if task has been accepted (status changed from 'open' to 'pending' or 'accepted')
        if (task.status != 'open') {
          _pollTimer?.cancel();

          // Navigate to task details
          if (mounted) {
            context.go('/home/browse/${task.id}');
          }
        }
      }
    } catch (e) {
      print('Error checking task status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000000)),
          onPressed: () => context.go('/home/tasks'),
        ),
        title: const Text(
          'Finding Tasker',
          style: TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated searching indicator
              RotationTransition(
                turns: _animationController,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFDB5B),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.search,
                    size: 60,
                    color: Color(0xFFFFDB5B),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Title
              const Text(
                'Looking for available taskers',
                style: TextStyle(
                  fontFamily: 'Instrument Sans',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF000000),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                _currentTask != null
                    ? 'We\'re notifying taskers who specialize in ${_currentTask!.category}.\nYou\'ll be notified once someone accepts your task.'
                    : 'We\'re notifying available taskers in your area.\nYou\'ll be notified once someone accepts your task.',
                style: const TextStyle(
                  fontFamily: 'Instrument Sans',
                  fontSize: 14,
                  color: Color(0xFF788494),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Task info card
              if (_currentTask != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDB5B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _currentTask!.category.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Instrument Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Color(0xFF000000),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'RM ${_currentTask!.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Instrument Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentTask!.title,
                        style: const TextStyle(
                          fontFamily: 'Instrument Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Color(0xFF788494),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _currentTask!.location,
                              style: const TextStyle(
                                fontFamily: 'Instrument Sans',
                                fontSize: 12,
                                color: Color(0xFF788494),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),

              // Tips section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE3F2FD),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Color(0xFF2196F3),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'What happens next?',
                            style: TextStyle(
                              fontFamily: 'Instrument Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF000000),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Taskers in your area will receive a notification\n'
                            '• You can view offers from interested taskers\n'
                            '• Choose the best tasker for your job\n'
                            '• Chat with them to discuss details',
                            style: TextStyle(
                              fontFamily: 'Instrument Sans',
                              fontSize: 12,
                              color: Color(0xFF788494),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // View My Tasks button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDB5B),
                    foregroundColor: const Color(0xFF000000),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                      side: const BorderSide(
                        color: Color(0xFFFFC333),
                        width: 1,
                      ),
                    ),
                  ),
                  onPressed: () => context.go('/home/tasks'),
                  child: const Text(
                    'View My Tasks',
                    style: TextStyle(
                      fontFamily: 'Instrument Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}