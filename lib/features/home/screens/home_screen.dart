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
    
    return Scaffold(
      body: isHomeRoute 
        ? _buildHomeContent(context, user)
        : child, // Show only the child for non-home routes
      bottomNavigationBar: NavigationBar(
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
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment),
            label: 'My Tasks',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.add_circle),
            icon: Icon(Icons.add_circle_outline),
            label: 'Post Task',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
  
  // Extracted home content into a separate method
  Widget _buildHomeContent(BuildContext context, dynamic user) {
    return Column(
      children: [
        // Purple header with user info and notification
        Container(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          decoration: const BoxDecoration(
            color: Color(0xFF6C5CE7), // Purple color from the image
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
          ),
          child: Column(
            children: [
              // User profile and notification row
              Row(
                children: [
                  // User avatar and name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Text(
                          user?.userMetadata?['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(color: Color(0xFF6C5CE7)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hello there,',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            user?.userMetadata?['name']?.toString() ?? 'User',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Notification bell
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      // Handle notification tap
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
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
                        ),
                        onTap: () {
                          // Handle search tap
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Categories section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildCategoryItem(context, 'Handyman', Icons.handyman),
                  _buildCategoryItem(context, 'Cleaning', Icons.cleaning_services),
                  _buildCategoryItem(context, 'Gardening', Icons.yard),
                  _buildCategoryItem(context, 'Painting', Icons.format_paint),
                  _buildCategoryItem(context, 'Organizing', Icons.inventory_2),
                  _buildCategoryItem(context, 'Pet Care', Icons.pets),
                  _buildCategoryItem(context, 'House Moving', Icons.local_shipping),
                  _buildCategoryItem(context, 'Events & Photography', Icons.camera_alt),
                  _buildCategoryItem(context, 'Others', Icons.more_horiz),
                ],
              ),
            ],
          ),
        ),
        
        // Expanded area for child content on home screen
        Expanded(child: Container()),
      ],
    );
  }
  
  Widget _buildCategoryItem(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        // Handle category tap
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6C5CE7).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF6C5CE7),
              radius: 20,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}