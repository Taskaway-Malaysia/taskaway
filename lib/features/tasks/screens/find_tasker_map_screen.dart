import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/tasks/controllers/tasker_controller.dart';
import 'package:taskaway/features/auth/models/profile.dart';
import 'package:taskaway/features/applications/controllers/application_controller.dart';
import 'package:taskaway/features/applications/models/application.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import 'dart:developer' as dev;

/// FindTaskerMapScreen
///
/// Displays map with task location and nearby available taskers
/// Features:
/// - Shows task location marker
/// - Displays tasker markers on map
/// - Tap tasker marker to show preview card
/// - Auto-detects when tasker accepts task
/// - Navigates to tasker details when accepted
class FindTaskerMapScreen extends ConsumerStatefulWidget {
  final String taskId;

  const FindTaskerMapScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<FindTaskerMapScreen> createState() => _FindTaskerMapScreenState();
}

class _FindTaskerMapScreenState extends ConsumerState<FindTaskerMapScreen> {
  Profile? _selectedTasker;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskAsync = ref.watch(taskProvider(widget.taskId));
    final taskersAsync = ref.watch(availableTaskersProvider(widget.taskId));

    // Listen for task status changes and show dialog when accepted
    ref.listen<AsyncValue<dynamic>>(taskStatusStreamProvider(widget.taskId), (previous, next) {
      next.whenData((task) {
        if (task.status == 'accepted' && task.taskerId != null) {
          dev.log('[FindTaskerMap] Task accepted by tasker: ${task.taskerId}');

          if (mounted) {
            // Show assignment notification dialog with tasker info
            _showTaskerAssignedDialog(task.taskerId!);
          }
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Find Tasker'),
        backgroundColor: AppColors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if we can pop, otherwise navigate to my tasks
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home/tasks');
            }
          },
        ),
      ),
      body: taskAsync.when(
        data: (task) {
          final taskLocation = LatLng(
            task.latitude ?? 3.139,
            task.longitude ?? 101.687,
          );

          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: taskLocation,
                  initialZoom: 14.0,
                  minZoom: 10.0,
                  maxZoom: 18.0,
                ),
                children: [
                  // Tile layer
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.taskaway.app',
                  ),

                  // Task location marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: taskLocation,
                        width: 50,
                        height: 50,
                        child: _buildTaskMarker(),
                      ),
                    ],
                  ),

                  // Tasker markers
                  taskersAsync.when(
                    data: (taskers) {
                      return MarkerLayer(
                        markers: taskers.map((tasker) {
                          return Marker(
                            point: LatLng(tasker.latitude!, tasker.longitude!),
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTasker = tasker;
                                });
                              },
                              child: _buildTaskerMarker(tasker),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),

              // Loading indicator for taskers
              taskersAsync.when(
                data: (_) => const SizedBox.shrink(),
                loading: () => Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.xxl,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Finding taskers...'),
                        ],
                      ),
                    ),
                  ),
                ),
                error: (error, _) => Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: AppRadius.md,
                    ),
                    child: Text(
                      'Error loading taskers: $error',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ),
              ),

              // Selected tasker preview card
              if (_selectedTasker != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildTaskerPreviewCard(_selectedTasker!),
                ),

              // Task info card
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDB5B),
                    borderRadius: AppRadius.md,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${task.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tasker count badge
              taskersAsync.when(
                data: (taskers) => Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.xxl,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 16, color: Color(0xFF000000)),
                        const SizedBox(width: 4),
                        Text(
                          '${taskers.length} available',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Applications bottom sheet
              _buildApplicationsBottomSheet(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
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
    );
  }

  /// Build task location marker (yellow pin)
  Widget _buildTaskMarker() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on,
        size: 50,
        color: Color(0xFFFFDB5B),
      ),
    );
  }

  /// Build tasker marker (profile circle)
  Widget _buildTaskerMarker(Profile tasker) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(
          color: _selectedTasker?.id == tasker.id
              ? const Color(0xFFFFDB5B)
              : const Color(0xFFE0E0E0),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: tasker.avatarUrl != null
            ? Image.network(
                tasker.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(tasker),
              )
            : _buildDefaultAvatar(tasker),
      ),
    );
  }

  /// Build default avatar with initials
  Widget _buildDefaultAvatar(Profile tasker) {
    final initials = tasker.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase();
    return Container(
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  /// Build tasker preview card
  Widget _buildTaskerPreviewCard(Profile tasker) {
    return Container(
      margin: EdgeInsets.all(AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: AppRadius.xs,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Tasker info
          Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFDB5B), width: 2),
                ),
                child: ClipOval(
                  child: tasker.avatarUrl != null
                      ? Image.network(
                          tasker.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(tasker),
                        )
                      : _buildDefaultAvatar(tasker),
                ),
              ),
              SizedBox(width: AppSpacing.lg),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tasker.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Color(0xFFFFDB5B)),
                        const SizedBox(width: 4),
                        Text(
                          '${tasker.rating.toStringAsFixed(1)} (${tasker.totalTasks} tasks)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF788494),
                          ),
                        ),
                      ],
                    ),
                    if (tasker.skills != null && tasker.skills!.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: tasker.skills!.take(3).map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: AppRadius.sm,
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF000000),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTasker = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  child: Text('Close'),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to full tasker details
                    context.goNamed(
                      'tasker-details',
                      pathParameters: {
                        'taskId': widget.taskId,
                        'taskerId': tasker.id,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDB5B),
                    foregroundColor: const Color(0xFF000000),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    'View Profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build applications bottom sheet showing received offers
  Widget _buildApplicationsBottomSheet() {
    final applicationsAsync = ref.watch(taskApplicationsStreamProvider(widget.taskId));

    return applicationsAsync.when(
      data: (applications) {
        // Show waiting message if no applications yet
        if (applications.isEmpty) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.lg,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated waiting icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDB5B).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_empty,
                      size: 30,
                      color: Color(0xFFFFDB5B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Waiting for Offers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    'Your task is now visible to nearby taskers. You\'ll receive offers here once taskers apply for your task.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tips
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: AppRadius.md,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tip: Make sure your task details are clear to attract more offers!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: AppRadius.xs,
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Received Offers (${applications.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Applications list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: applications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final application = applications[index];
                      return _buildApplicationItem(application);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Build individual application item
  Widget _buildApplicationItem(Application application) {
    // Get tasker profile from the application model
    final taskerProfile = application.taskerProfile;
    final taskerName = taskerProfile?['full_name'] ?? 'Unknown';
    final avatarUrl = taskerProfile?['avatar_url'];
    final rating = (taskerProfile?['rating'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(color: const Color(0xFFFFDB5B), width: 2),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(avatarUrl, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        taskerName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(width: AppSpacing.md),

          // Tasker info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Color(0xFFFFDB5B)),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF788494),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Text(
                      'RM ${application.offerPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Accept button
          if (application.status == ApplicationStatus.pending)
            SizedBox(
              width: 60,
              child: ElevatedButton(
                onPressed: () {
                  _showOfferDetailsSheet(application);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFDB5B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.sm,
                  ),
                ),
                child: Text(
                  'View',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: application.status == ApplicationStatus.accepted
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: AppRadius.lg,
              ),
              child: Text(
                application.status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: application.status == ApplicationStatus.accepted
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Show offer details bottom sheet
  void _showOfferDetailsSheet(Application application) {
    final taskerProfile = application.taskerProfile;
    final taskerName = taskerProfile?['full_name'] ?? 'Unknown';
    final avatarUrl = taskerProfile?['avatar_url'];
    final rating = (taskerProfile?['rating'] as num?)?.toDouble() ?? 0.0;
    final totalTasks = taskerProfile?['total_tasks'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: AppRadius.xs,
              ),
            ),

            // Tasker profile section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      border: Border.all(color: const Color(0xFFFFDB5B), width: 2),
                    ),
                    child: ClipOval(
                      child: avatarUrl != null
                          ? Image.network(avatarUrl, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                taskerName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.lg),

                  // Tasker info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taskerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Color(0xFFFFDB5B)),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Text(
                              '$totalTasks tasks completed',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
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

            SizedBox(height: AppSpacing.xxl),
            const Divider(height: 1),
            SizedBox(height: AppSpacing.xxl),

            // Offer details section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Offer price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Offer Price',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'RM ${application.offerPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFDB5B),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: AppSpacing.xxl),

                    // Message/Description
                    Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: AppRadius.lg,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        application.message ?? 'No message provided',
                        style: TextStyle(
                          fontSize: 14,
                          color: application.message != null ? AppColors.textPrimary : Colors.grey.shade500,
                          height: 1.5,
                        ),
                      ),
                    ),

                    SizedBox(height: AppSpacing.xxl),

                    // Application date
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Applied ${_formatDate(application.createdAt)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Message button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to chat with tasker
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat feature coming soon')),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),

                  // Accept button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _handleAcceptOffer(application, context);
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: Text('Accept Offer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFDB5B),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Handle accepting an offer with payment-first flow
  Future<void> _handleAcceptOffer(Application application, BuildContext sheetContext) async {
    try {
      dev.log('[FindTaskerMap] _handleAcceptOffer started for application ${application.id}');

      // Close the bottom sheet first before navigating
      Navigator.of(sheetContext).pop();
      dev.log('[FindTaskerMap] Bottom sheet closed');

      // Small delay to ensure sheet is closed
      await Future.delayed(const Duration(milliseconds: 100));
      dev.log('[FindTaskerMap] Delay completed');

      if (!mounted) {
        dev.log('[FindTaskerMap] Widget not mounted after delay, returning');
        return;
      }

      // Initiate offer acceptance (validates and prepares payment data)
      // NO DIALOG - just do the work and navigate
      dev.log('[FindTaskerMap] Initiating offer acceptance...');
      final applicationController = ref.read(applicationControllerProvider.notifier);
      final paymentData = await applicationController.initiateOfferAcceptance(
        applicationId: application.id!,
        taskId: widget.taskId,
        taskerId: application.taskerId,
      );
      dev.log('[FindTaskerMap] Offer acceptance initiated, payment type: ${paymentData['paymentType']}');

      if (!mounted) {
        dev.log('[FindTaskerMap] Widget not mounted after initiate, returning');
        return;
      }

      // Check payment type - cash or online
      if (paymentData['paymentType'] == 'cash') {
        dev.log('[FindTaskerMap] Cash payment - completing offer acceptance');
        // Cash on delivery - complete offer acceptance directly
        await applicationController.completeOfferAcceptance(
          applicationId: paymentData['applicationId'],
          taskId: paymentData['taskId'],
          taskerId: paymentData['taskerId'],
          chipPaymentId: '', // No payment ID for cash
          offerPrice: paymentData['offerPrice'],
        );
        dev.log('[FindTaskerMap] Offer acceptance completed');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offer accepted! Task assigned to tasker.'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate directly - no dialog to conflict with
          dev.log('[FindTaskerMap] Navigating to task details: /task/${widget.taskId}');
          context.go('/task/${widget.taskId}');
          dev.log('[FindTaskerMap] Navigation command sent');
        }
      } else {
        // Online payment - navigate to CHIPP payment screen
        dev.log('[FindTaskerMap] Online payment - preparing navigation to CHIPP');
        // Navigate directly - no dialog Navigator to conflict with
        if (mounted) {
          dev.log('[FindTaskerMap] Navigating to /chip-payment with data: ${paymentData.keys.join(', ')}');
          context.go('/chip-payment', extra: {
            'checkoutUrl': paymentData['checkoutUrl'],
            'taskId': paymentData['taskId'],
            'amount': paymentData['amount'],
            'taskTitle': paymentData['taskTitle'],
            'paymentType': 'offer_acceptance',
            'applicationId': paymentData['applicationId'],
            'taskerId': paymentData['taskerId'],
            'chipPaymentId': paymentData['chipPaymentId'],
          });
          dev.log('[FindTaskerMap] Navigation to CHIPP payment sent');
        } else {
          dev.log('[FindTaskerMap] Widget not mounted, cannot navigate');
        }
      }
    } catch (e, st) {
      dev.log('[FindTaskerMap] Error in _handleAcceptOffer: $e\nStackTrace: $st');
      if (!mounted) return;

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show dialog when tasker accepts the task
  Future<void> _showTaskerAssignedDialog(String taskerId) async {
    try {
      // Fetch tasker profile from database
      final response = await Supabase.instance.client
          .from('taskaway_profiles')
          .select()
          .eq('id', taskerId)
          .single();

      final taskerProfile = Profile.fromJson(response as Map<String, dynamic>);

      if (!mounted) return;

      // Show dialog with tasker info
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xl,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDB5B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Tasker Assigned!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tasker avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFDB5B),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: taskerProfile.avatarUrl != null
                      ? Image.network(
                          taskerProfile.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(taskerProfile),
                        )
                      : _buildDefaultAvatar(taskerProfile),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              // Tasker name
              Text(
                taskerProfile.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              // Tasker rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 18, color: Color(0xFFFFDB5B)),
                  const SizedBox(width: 4),
                  Text(
                    '${taskerProfile.rating.toStringAsFixed(1)} (${taskerProfile.totalTasks} tasks)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF788494),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              // Message
              Text(
                'has accepted your task. View their profile to get started.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF788494),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Navigate to tasker details
                  context.goNamed(
                    'tasker-details',
                    pathParameters: {
                      'taskId': widget.taskId,
                      'taskerId': taskerId,
                    },
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
                  'View Tasker Profile',
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
      );
    } catch (e) {
      dev.log('[FindTaskerMap] Error fetching tasker profile: $e');
      // Fallback: show dialog without tasker info
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xl,
          ),
          title: Text('Tasker Assigned!'),
          content: Text('A tasker has accepted your task.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.goNamed(
                  'tasker-details',
                  pathParameters: {
                    'taskId': widget.taskId,
                    'taskerId': taskerId,
                  },
                );
              },
              child: Text('View Profile'),
            ),
          ],
        ),
      );
    }
  }
}
