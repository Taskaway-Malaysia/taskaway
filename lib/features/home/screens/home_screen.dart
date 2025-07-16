import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/home/screens/poster_home_screen.dart';
import 'package:taskaway/features/home/screens/tasker_home_screen.dart';
import 'package:taskaway/features/messages/controllers/message_controller.dart';

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
    final unreadCountAsync = ref.watch(totalUnreadCountProvider);
    
    // Determine the current index based on location
    int actualIndex;
    if (currentLocation == '/home/browse') {
      actualIndex = 0;
    } else if (currentLocation == '/home/tasks') {
      actualIndex = 1;
    } else if (currentLocation == '/home/post-task') {
      actualIndex = 2;
    } else if (currentLocation.startsWith('/home/chat')) {
      actualIndex = 3;
    } else if (currentLocation == '/home/profile') {
      actualIndex = 4;
    } else {
      actualIndex = ref.watch(currentIndexProvider);
    }

    // Determine which routes should show the bottom navigation bar
    final bool showBottomNav = !currentLocation.startsWith('/home/chat/');

    // The body of the scaffold will be the child for nested routes,
    // or the role-specific home screen for the main home route.
    Widget body;
    if (currentLocation == '/home/browse') {
      // Always show TaskerHomeScreen (browse screen) for all users
      body = profileAsync.when(
        data: (profile) => TaskerHomeScreen(profile: profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading profile: $error'),
        ),
      );
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
          ? NavigationBar(
              selectedIndex: actualIndex,
              onDestinationSelected: (index) {
                // Prevent navigating to the same page
                if (actualIndex == index) return;

                ref.read(currentIndexProvider.notifier).state = index;
                switch (index) {
                  case 0:
                    context.go('/home/browse');
                    break;
                  case 1:
                    context.go('/home/tasks');
                    break;
                  case 2:
                    // Navigate to post-task route to show poster home screen
                    // Both poster and tasker roles can create tasks
                    context.go('/home/post-task');
                    break;
                  case 3:
                    context.go('/home/chat');
                    break;
                  case 4:
                    context.go('/home/profile');
                    break;
                }
              },
              destinations: [
                const NavigationDestination(
                    icon: Icon(Icons.search), label: 'Browse'),
                const NavigationDestination(
                    icon: Icon(Icons.assignment_outlined), label: 'My Tasks'),
                const NavigationDestination(
                    icon: Icon(Icons.add_circle_outline), label: 'Post Task'),
                NavigationDestination(
                  icon: unreadCountAsync.when(
                    data: (unreadCount) => unreadCount > 0
                        ? Badge(
                            label: Text('$unreadCount'),
                            child: const Icon(Icons.chat_bubble_outline),
                          )
                        : const Icon(Icons.chat_bubble_outline),
                    loading: () => const Icon(Icons.chat_bubble_outline),
                    error: (_, __) => const Icon(Icons.chat_bubble_outline),
                  ),
                  label: 'Messages',
                ),
                const NavigationDestination(
                    icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
            )
          : null,
    );
  }
}

