import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    // Hide bottom navigation bar when in chat screen (but not chat list)
    final bool showBottomNav = !currentLocation.contains('/home/chat/');

    return Scaffold(
      body: child,
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
}
