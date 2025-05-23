import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Get the current auth state immediately
    final session = Supabase.instance.client.auth.currentSession;
    
    // Add a small delay to show splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // Navigate based on current session
    if (session != null) {
      context.go('/home');
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes for subsequent changes
    ref.listen<AsyncValue<AuthState>>(
      authStateProvider,
      (previous, next) {
        next.whenData((authState) {
          if (authState.event == AuthChangeEvent.signedIn) {
            context.go('/home');
          } else if (authState.event == AuthChangeEvent.signedOut) {
            context.go('/auth');
          }
        });
      },
    );

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your logo or app name here
            Text(
              'Taskaway Malaysia',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
} 