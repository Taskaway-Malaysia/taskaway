import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    if (currentLocation == '/home/browse' || currentLocation == '/home/tasks') {
      actualIndex = 0; // Home tab
    } else if (currentLocation == '/home/activity') {
      actualIndex = 1; // Activity tab
    } else if (currentLocation == '/home/post-task') {
      actualIndex = 2; // Taskaway tab
    } else if (currentLocation.startsWith('/home/chat')) {
      actualIndex = 3; // Message tab
    } else if (currentLocation == '/home/profile') {
      actualIndex = 4; // Profile tab
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
                  height: 64,
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        index: 0,
                        iconPath: 'assets/icons/nav_home.svg',
                        label: 'Home',
                        isSelected: actualIndex == 0,
                        onTap: () {
                          if (actualIndex == 0) return;
                          ref.read(currentIndexProvider.notifier).state = 0;
                          context.go('/home/browse');
                        },
                      ),
                      _buildNavItem(
                        index: 1,
                        iconPath: 'assets/icons/nav_activity.svg',
                        label: 'Activity',
                        isSelected: actualIndex == 1,
                        onTap: () {
                          if (actualIndex == 1) return;
                          ref.read(currentIndexProvider.notifier).state = 1;
                          context.go('/home/activity');
                        },
                      ),
                      _buildCenterTaskawayButton(
                        isSelected: actualIndex == 2,
                        onTap: () {
                          if (actualIndex == 2) return;
                          ref.read(currentIndexProvider.notifier).state = 2;
                          context.go('/create-task');
                        },
                      ),
                      _buildNavItem(
                        index: 3,
                        iconPath: 'assets/icons/nav_message.svg',
                        label: 'Message',
                        isSelected: actualIndex == 3,
                        onTap: () {
                          if (actualIndex == 3) return;
                          ref.read(currentIndexProvider.notifier).state = 3;
                          context.go('/home/chat');
                        },
                      ),
                      _buildNavItem(
                        index: 4,
                        iconPath: 'assets/icons/nav_profile.svg',
                        label: 'Profile',
                        isSelected: actualIndex == 4,
                        onTap: () {
                          if (actualIndex == 4) return;
                          ref.read(currentIndexProvider.notifier).state = 4;
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
    required String iconPath,
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
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              isSelected ? const Color(0xFF202020) : const Color(0xFF575656),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: isSelected ? const Color(0xFF202020) : const Color(0xFF575656),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterTaskawayButton({
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDB5B),
              border: Border.all(
                color: const Color(0xFFC333),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: SvgPicture.asset(
              'assets/icons/nav_taskaway.svg',
              width: 15,
              height: 15,
              colorFilter: const ColorFilter.mode(
                Color(0xFF000000),
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Taskaway',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF575656),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

