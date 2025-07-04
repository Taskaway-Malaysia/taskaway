import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/style_constants.dart';
import '../../../insert_sample_data_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/profile.dart';
import '../screens/create_task_screen.dart';

class PostTaskScreen extends ConsumerWidget {
  const PostTaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight / 3;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer(builder: (context, ref, child) {
        final profileAsync = ref.watch(currentProfileProvider);
        
        return profileAsync.when(
          data: (profile) => _buildContent(context, ref, headerHeight, profile),
          loading: () => _buildContent(context, ref, headerHeight, null),
          error: (error, stackTrace) => _buildContent(context, ref, headerHeight, null),
        );
      }),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, double headerHeight, Profile? profile) {
    // Get the first letter of the user's name for the avatar
    String avatarText = 'U';
    String displayName = 'User';
    
    if (profile != null) {
      displayName = profile.fullName;
      avatarText = profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'U';
    }
    
    return Column(
      children: [
        // Purple header with user info and notification
        Container(
          height: headerHeight,
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          decoration: const BoxDecoration(
            color: Color(0xFF6C5CE7),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // User profile and notification row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // User avatar and name
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          child: Text(
                            avatarText,
                            style: const TextStyle(
                                color: Color(0xFF6C5CE7), fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hello there,',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Notification bell
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      onPressed: () {
                        // Handle notification tap
                      },
                    ),
                  ],
                ),
              ),

              // Post a Task text
              const Padding(
                padding: EdgeInsets.only(left: 24.0, bottom: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Post a Task. Give it Away.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              // Search bar - positioned at bottom of header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(StyleConstants.defaultRadius),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Tell us what you need help with...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () {
                            // Handle search tap
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Categories section
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 0.0),
                        child: Text(
                          'Categories',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Sample data button
                      TextButton.icon(
                        onPressed: () => showSampleDataDialog(context),
                        icon: const Icon(Icons.message, size: 16),
                        label: const Text('Sample Data', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6C5CE7),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                    children: [
                      _buildCategoryItem(context, ref,
                          'Handyman', Icons.handyman_outlined),
                      _buildCategoryItem(context, ref, 'Cleaning',
                          Icons.cleaning_services_outlined),
                      _buildCategoryItem(context, ref,
                          'Gardening', Icons.yard_outlined),
                      _buildCategoryItem(context, ref,
                          'Painting', Icons.format_paint_outlined),
                      _buildCategoryItem(context, ref,
                          'Organizing', Icons.inventory_2_outlined),
                      _buildCategoryItem(context, ref,
                          'Pet Care', Icons.pets_outlined),
                      _buildCategoryItem(context, ref,
                          'Self Care', Icons.spa_outlined),
                      _buildCategoryItem(context, ref, 'Events & Photography',
                          Icons.camera_alt_outlined),
                      _buildCategoryItem(context, ref, 'Others', Icons.more_horiz),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build category item widget
  Widget _buildCategoryItem(BuildContext context, WidgetRef ref, String title, IconData icon) {
    // Convert display title to category ID format (lowercase with underscores)
    String categoryId = title.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_');
    
    // Handle special case for "Events & Photography"
    if (categoryId == 'events_photography') {
      categoryId = 'events_photography';
    }
    
    return InkWell(
      onTap: () {
        // Navigate to create task screen with pre-selected category
        final currentTaskData = ref.read(createTaskDataProvider);
        ref.read(createTaskDataProvider.notifier).state = {
          ...currentTaskData,
          'category': categoryId,
        };
        
        // Navigate to the create task screen
        context.go('/create-task');
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF6C5CE7),
            radius: 30,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
} 