import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/style_constants.dart';
import '../../auth/controllers/auth_controller.dart';

final currentIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  final Widget child;

  const HomeScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentIndexProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final currentLocation = GoRouterState.of(context).uri.toString();

    // Only show the home content if we're on the browse route
    final bool isHomeRoute = currentLocation.contains('/home/browse');

    // Hide bottom navigation bar when in chat screen (but not chat list)
    final bool showBottomNav = !currentLocation.contains('/home/chat/');

    return Scaffold(
      body: isHomeRoute
          ? _buildHomeContent(context, user)
          : child, // Show only the child for non-home routes
      bottomNavigationBar: showBottomNav
          ? NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                ref.read(currentIndexProvider.notifier).state = index;
                switch (index) {
                  case 0:
                    context.go('/home/browse');
                    break;
                  case 1:
                    context.go('/home/tasks');
                    break;
                  case 2:
                    context.go('/home/post');
                    break;
                  case 3:
                    context.go('/home/chat');
                    break;
                  case 4:
                    context.go('/home/profile');
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  label: 'Browse',
                ),
                NavigationDestination(
                  icon: Icon(Icons.article_outlined),
                  label: 'My Tasks',
                ),
                NavigationDestination(
                  selectedIcon: Icon(Icons.add_circle),
                  icon: Icon(Icons.add_circle),
                  label: 'Post Task',
                ),
                NavigationDestination(
                  icon: Icon(Icons.mail_outline),
                  label: 'Messages',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }

  // Extracted home content into a separate method
  Widget _buildHomeContent(BuildContext context, dynamic user) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight / 3; // 2/6 = 1/3 of screen height

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
                            user?.userMetadata?['name']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'U',
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
                              user?.userMetadata?['name']?.toString() ?? 'User',
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
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 0.0),
                    child: Text(
                      'Categories',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 0),
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

  Widget _buildCategoryItem(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        // Handle category tap
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
