import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/profile/controllers/profile_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/features/auth/models/profile.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import 'dart:developer' as dev;

/// TaskerDetailsScreen
///
/// Displays full tasker profile after task acceptance
/// Features:
/// - Tasker profile info (name, rating, bio, skills)
/// - Task details and price
/// - Contact/chat button
/// - Task status tracking
class TaskerDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;
  final String taskerId;

  const TaskerDetailsScreen({
    super.key,
    required this.taskId,
    required this.taskerId,
  });

  @override
  ConsumerState<TaskerDetailsScreen> createState() => _TaskerDetailsScreenState();
}

class _TaskerDetailsScreenState extends ConsumerState<TaskerDetailsScreen> {
  Profile? _taskerProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTaskerProfile();
  }

  Future<void> _loadTaskerProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      dev.log('[TaskerDetails] Loading profile for tasker: ${widget.taskerId}');

      final response = await Supabase.instance.client
          .from('taskaway_profiles')
          .select()
          .eq('id', widget.taskerId)
          .single();

      if (mounted) {
        setState(() {
          _taskerProfile = Profile.fromJson(response as Map<String, dynamic>);
          _isLoading = false;
        });

        dev.log('[TaskerDetails] Loaded profile: ${_taskerProfile!.fullName}');
      }
    } catch (e, st) {
      dev.log('[TaskerDetails] Error loading profile: $e\n$st');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load tasker profile';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskAsync = ref.watch(taskProvider(widget.taskId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Tasker Details'),
        backgroundColor: AppColors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if we can pop, otherwise navigate to find tasker map
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('find-tasker', pathParameters: {'taskId': widget.taskId});
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppSpacing.xxl),
                        ElevatedButton(
                          onPressed: _loadTaskerProfile,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : taskAsync.when(
                  data: (task) => SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tasker header
                        Container(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Avatar
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFFDB5B),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _taskerProfile!.avatarUrl != null
                                      ? Image.network(
                                          _taskerProfile!.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                                        )
                                      : _buildDefaultAvatar(),
                                ),
                              ),
                              SizedBox(height: AppSpacing.lg),

                              // Name
                              Text(
                                _taskerProfile!.fullName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: AppSpacing.sm),

                              // Rating
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star, size: 20, color: Color(0xFFFFDB5B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_taskerProfile!.rating.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '${_taskerProfile!.totalTasks} tasks completed',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF788494),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Task info
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.assignment, size: 20, color: Colors.blue),
                                  SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Your Task',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFDB5B),
                                      borderRadius: AppRadius.sm,
                                    ),
                                    child: Text(
                                      task.category.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'RM ${task.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Skills
                        if (_taskerProfile!.skills != null && _taskerProfile!.skills!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Skills',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.md),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _taskerProfile!.skills!.map((skill) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: AppRadius.smMd,
                                        border: Border.all(color: const Color(0xFFE0E0E0)),
                                      ),
                                      child: Text(
                                        skill,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                        // Bio/About
                        if (_taskerProfile!.bio != null || _taskerProfile!.about != null)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.md),
                                Text(
                                  _taskerProfile!.about ?? _taskerProfile!.bio ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF000000),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 80), // Space for bottom button
                      ],
                    ),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: AppSpacing.lg),
                          Text(
                            'Error loading task',
                            style: theme.textTheme.titleLarge,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: _taskerProfile != null && !_isLoading
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to chat with tasker
                          // TODO: Implement chat navigation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chat feature coming soon'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFDB5B),
                          foregroundColor: const Color(0xFF000000),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.md,
                          ),
                        ),
                        child: Text(
                          'Contact Tasker',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          // Switch to poster role before navigating
                          if (currentUser != null) {
                            ref.read(profileControllerProvider).updateUserRole(
                              userId: currentUser.id,
                              role: 'As Poster',
                            );
                          }
                          context.go('/home/tasks');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.md,
                          ),
                        ),
                        child: Text(
                          'Back to My Tasks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  /// Build default avatar with initials
  Widget _buildDefaultAvatar() {
    final initials = _taskerProfile!.fullName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}
