import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Helper function to determine selected index from route
int _calculateSelectedIndex(String location) {
  if (location.startsWith('/home/browse')) {
    return 0;
  } else if (location.startsWith('/home/my-tasks')) {
    return 1;
  } else if (location.startsWith('/home/post-task')) {
    return 2;
  } else if (location.startsWith('/home/chat')) {
    return 3;
  } else if (location.startsWith('/home/profile')) {
    return 4;
  }
  return 0; // Default to browse, should align with initial redirect
}

// Provider for the current index of the navigation bar
final currentIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  final Widget child;
  
  const HomeScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Correctly get the current matched location from GoRouterState
    final String currentLocation = GoRouterState.of(context).matchedLocation;
    final int calculatedSelectedIndex = _calculateSelectedIndex(currentLocation);

    // Update the provider if its current value doesn't match the route-derived index.
    // This ensures that if other parts of the app listen to currentIndexProvider,
    // they get a value consistent with the route.
    // Do this in a post-frame callback to avoid modifying state during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(currentIndexProvider) != calculatedSelectedIndex) {
        ref.read(currentIndexProvider.notifier).state = calculatedSelectedIndex;
      }
    });
    
    // User provider is watched elsewhere when needed

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        // Use the calculated index directly for the NavigationBar's selected state
        selectedIndex: calculatedSelectedIndex,
        onDestinationSelected: (index) {
          ref.read(currentIndexProvider.notifier).state = index;
          switch (index) {
            case 0: // Browse
              context.go('/home/browse');
              break;
            case 1: // My Tasks
              context.go('/home/my-tasks');
              break;
            case 2: // Post Task
              context.go('/home/post-task');
              break;
            case 3: // Messages
              context.go('/home/chat');
              break;
            case 4: // Profile
              context.go('/home/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'My Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
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
      ),
    );
  }
} 