import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/features/auth/models/profile.dart';
import 'package:taskaway/features/tasks/screens/create_task_screen.dart'; // For createTaskDataProvider

class PosterHomeScreen extends ConsumerWidget {
  final Profile? profile;
  const PosterHomeScreen({super.key, this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the header height (30% of screen height)
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.3;

    // Get the first letter of the user's name for the avatar
    String avatarText = 'U';
    String displayName = 'User';

    if (profile != null) {
      displayName = profile!.fullName;
      avatarText =
          profile!.fullName.isNotEmpty ? profile!.fullName[0].toUpperCase() : 'U';
    }

    return Column(
      children: [
        // Purple header with user info and notification
        Container(
          height: headerHeight,
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          decoration: const BoxDecoration(
            color: Color(0xFF6C5CE7), // Purple color from the image
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
                        context.push('/notifications');
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
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 0.0),
                    child: Text(
                      'Categories',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, top: 4.0),
                    child: Text(
                      'Choose a category that represents your task',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                    children: [
                      _buildCategoryItem(
                          context, 'Handyman', Icons.handyman_outlined),
                      _buildCategoryItem(context, 'Cleaning',
                          Icons.cleaning_services_outlined),
                      _buildCategoryItem(
                          context, 'Gardening', Icons.yard_outlined),
                      _buildCategoryItem(
                          context, 'Painting', Icons.format_paint_outlined),
                      _buildCategoryItem(
                          context, 'Organizing', Icons.inventory_2_outlined),
                      _buildCategoryItem(
                          context, 'Pet Care', Icons.pets_outlined),
                      _buildCategoryItem(
                          context, 'Self Care', Icons.spa_outlined),
                      _buildCategoryItem(context, 'Events & Photography',
                          Icons.camera_alt_outlined),
                      _buildCategoryItem(context, 'Others', Icons.more_horiz),
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
  Widget _buildCategoryItem(BuildContext context, String title, IconData icon) {
    // Convert display title to category ID format (lowercase with underscores)
    String categoryId =
        title.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_');

    // Handle special case for "Events & Photography"
    if (categoryId == 'events_photography') {
      categoryId = 'events_photography';
    }

    return Consumer(builder: (context, ref, _) {
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
    });
  }
}
