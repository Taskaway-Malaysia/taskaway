import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/home/screens/poster_home_screen.dart';
import 'package:taskaway/features/home/screens/tasker_home_screen.dart';
import 'package:taskaway/features/home/screens/map_home_screen.dart';

final currentIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  final Widget child;

  const HomeScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final profileAsync = ref.watch(currentProfileProvider);
    
    // Determine the current index based on location
    int actualIndex;
    if (currentLocation == '/home/browse' || currentLocation == '/home/tasks' || currentLocation == '/home/post-task') {
      actualIndex = 0; // Home tab
    } else if (currentLocation.startsWith('/home/chat')) {
      actualIndex = 1; // Message tab
    } else if (currentLocation == '/home/profile') {
      actualIndex = 2; // Profile tab
    } else {
      actualIndex = ref.watch(currentIndexProvider);
    }

    // Determine which routes should show the bottom navigation bar
    final bool showBottomNav = !currentLocation.startsWith('/home/chat/');

    // The body of the scaffold will be the child for nested routes,
    // or the role-specific home screen for the main home route.
    Widget body;
    if (currentLocation == '/home/browse') {
      // Show the new map-based home screen
      body = const MapHomeScreen();
    } else if (currentLocation == '/home/post-task') {
      // Always show PosterHomeScreen when accessing post-task route
      body = profileAsync.when(
        data: (profile) => PosterHomeScreen(profile: profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading profile: $error'),
        ),
      );
    } else {
      body = child;
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: showBottomNav
          ? Container(
              color: Colors.white,
              child: SafeArea(
                child: Container(
                  height: 56,
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: 'Home',
                        isSelected: actualIndex == 0,
                        onTap: () {
                          if (actualIndex == 0) return;
                          ref.read(currentIndexProvider.notifier).state = 0;
                          context.go('/home/browse');
                        },
                      ),
                      const SizedBox(width: 46), // Figma design spacing
                      _buildNavItem(
                        index: 1,
                        icon: Icons.mail_outline,
                        activeIcon: Icons.mail,
                        label: 'Message',
                        isSelected: actualIndex == 1,
                        onTap: () {
                          if (actualIndex == 1) return;
                          ref.read(currentIndexProvider.notifier).state = 1;
                          context.go('/home/chat');
                        },
                      ),
                      const SizedBox(width: 46), // Figma design spacing
                      _buildNavItem(
                        index: 2,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profile',
                        isSelected: actualIndex == 2,
                        onTap: () {
                          if (actualIndex == 2) return;
                          ref.read(currentIndexProvider.notifier).state = 2;
                          context.go('/home/profile');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? const Color(0xFF202020) : const Color(0xFF575656),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: isSelected ? const Color(0xFF202020) : const Color(0xFF575656),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4, // 3.33% of 12px
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }
}

