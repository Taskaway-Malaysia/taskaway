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
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: actualIndex,
                onTap: (index) {
                  // Prevent navigating to the same page
                  if (actualIndex == index) return;

                  ref.read(currentIndexProvider.notifier).state = index;
                  switch (index) {
                    case 0:
                      context.go('/home/browse');
                      break;
                    case 1:
                      context.go('/home/chat');
                      break;
                    case 2:
                      context.go('/home/profile');
                      break;
                  }
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: Colors.amber.shade800,
                unselectedItemColor: Colors.grey.shade600,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                iconSize: 24,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.mail_outline),
                    activeIcon: Icon(Icons.mail),
                    label: 'Message',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

