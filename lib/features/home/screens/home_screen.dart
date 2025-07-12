import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/home/screens/poster_home_screen.dart';
import 'package:taskaway/features/home/screens/tasker_home_screen.dart';

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
    final currentLocation = GoRouterState.of(context).uri.toString();
    final profileAsync = ref.watch(currentProfileProvider);

    // Determine which routes should show the bottom navigation bar
    final bool showBottomNav = !currentLocation.startsWith('/home/chat/');

    // The body of the scaffold will be the child for nested routes,
    // or the role-specific home screen for the main home route.
    Widget body;
    if (currentLocation == '/home/browse') {
      body = profileAsync.when(
        data: (profile) {
          if (profile?.role == 'tasker') {
            return TaskerHomeScreen(profile: profile);
          } else {
            return PosterHomeScreen(profile: profile);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: SelectableText.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Error loading profile: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: '$error',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      body = child;
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: showBottomNav
          ? NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                // Prevent navigating to the same page
                if (currentIndex == index) return;

                ref.read(currentIndexProvider.notifier).state = index;
                switch (index) {
                  case 0:
                    context.go('/home/browse');
                    break;
                  case 1:
                    context.go('/home/tasks');
                    break;
                  case 2:
                    context.go('/create-task');
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
                    icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.assignment_outlined), label: 'My Tasks'),
                NavigationDestination(
                    icon: Icon(Icons.add_circle_outline), label: 'Post Task'),
                NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline), label: 'Inbox'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
            )
          : null,
    );
  }
}

