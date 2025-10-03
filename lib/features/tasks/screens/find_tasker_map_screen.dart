import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/features/tasks/controllers/task_controller.dart';
import 'package:taskaway/features/tasks/controllers/tasker_controller.dart';
import 'package:taskaway/features/auth/models/profile.dart';
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
        title: const Text('Find Tasker'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
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
                      borderRadius: BorderRadius.circular(8),
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
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
                          fontFamily: 'Instrument Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${task.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Instrument Sans',
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                            fontFamily: 'Instrument Sans',
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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading task',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
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
            color: Colors.black.withOpacity(0.2),
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
        color: Colors.white,
        border: Border.all(
          color: _selectedTasker?.id == tasker.id
              ? const Color(0xFFFFDB5B)
              : const Color(0xFFE0E0E0),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
            fontFamily: 'Instrument Sans',
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

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
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tasker.fullName,
                      style: const TextStyle(
                        fontFamily: 'Instrument Sans',
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
                            fontFamily: 'Instrument Sans',
                            fontSize: 14,
                            color: Color(0xFF788494),
                          ),
                        ),
                      ],
                    ),
                    if (tasker.skills != null && tasker.skills!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: tasker.skills!.take(3).map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontFamily: 'Instrument Sans',
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

          const SizedBox(height: 16),

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
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
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
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      fontFamily: 'Instrument Sans',
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
            borderRadius: BorderRadius.circular(16),
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
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tasker Assigned!',
                  style: TextStyle(
                    fontFamily: 'Instrument Sans',
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
              const SizedBox(height: 16),
              // Tasker name
              Text(
                taskerProfile.fullName,
                style: const TextStyle(
                  fontFamily: 'Instrument Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Tasker rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 18, color: Color(0xFFFFDB5B)),
                  const SizedBox(width: 4),
                  Text(
                    '${taskerProfile.rating.toStringAsFixed(1)} (${taskerProfile.totalTasks} tasks)',
                    style: const TextStyle(
                      fontFamily: 'Instrument Sans',
                      fontSize: 14,
                      color: Color(0xFF788494),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Message
              const Text(
                'has accepted your task. View their profile to get started.',
                style: TextStyle(
                  fontFamily: 'Instrument Sans',
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Tasker Profile',
                  style: TextStyle(
                    fontFamily: 'Instrument Sans',
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
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Tasker Assigned!'),
          content: const Text('A tasker has accepted your task.'),
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
              child: const Text('View Profile'),
            ),
          ],
        ),
      );
    }
  }
}
