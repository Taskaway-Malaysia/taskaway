import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskaway/core/constants/asset_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'dart:developer' as dev;
import 'dart:async';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minimumTimeElapsed = false;
  bool _authFlowCompleted = false;
  String? _targetRoute;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    dev.log('SplashScreen initState');

    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _minimumTimeElapsed = true;
        });
        _navigateIfReady();
      }
    });

    Future.microtask(() async {
      final initialAuthState = ref.read(authStateProvider);
      // Check if the widget is still mounted before processing the auth state.
      if (mounted && initialAuthState is AsyncData<AuthState?>) {
        await _handleAuthState(initialAuthState.value);
      }
    });
  }

  Future<void> _handleAuthState(AuthState? authState) async {
    final isPasswordRecoveryFlow = ref.read(passwordRecoveryFlowProvider);
    dev.log('SplashScreen: AuthState changed: ${authState?.event}, isPasswordRecoveryFlow: $isPasswordRecoveryFlow');
    String? determinedRoute;

    if (authState?.event == AuthChangeEvent.passwordRecovery) {
      dev.log('SplashScreen: Password recovery event. Starting flow.');
      ref.read(passwordRecoveryFlowProvider.notifier).state = true;
      determinedRoute = '/change-password';
    } else if (isPasswordRecoveryFlow) {
      // We are in the password recovery flow
      if (authState?.event == AuthChangeEvent.signedOut) {
        dev.log('SplashScreen: Password recovery flow: signedOut. Navigating to success.');
        determinedRoute = '/change-password-success';
        ref.read(passwordRecoveryFlowProvider.notifier).state = false; // End of flow
      } else if (authState?.event == AuthChangeEvent.signedIn || authState?.event == AuthChangeEvent.userUpdated) {
        dev.log('SplashScreen: Password recovery flow: ${authState?.event} received. Awaiting signOut.');
        return; // Critical: Do not proceed to set route or call _navigateIfReady
      } else {
        dev.log('SplashScreen: Password recovery flow: Unexpected event ${authState?.event}. Resetting flow, to login.');
        determinedRoute = '/login';
        ref.read(passwordRecoveryFlowProvider.notifier).state = false;
      }
    } else {
      // Regular auth flow
      if (isPasswordRecoveryFlow) ref.read(passwordRecoveryFlowProvider.notifier).state = false;

      if (authState?.session != null) {
        final user = authState!.session!.user;
        dev.log('SplashScreen: User authenticated: ${user.id}');
        try {
          final profileResponse = await Supabase.instance.client
              .from('taskaway_profiles')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          if (profileResponse != null) {
            dev.log('SplashScreen: Profile found for ${user.id}. Target: /home.');
            determinedRoute = '/home';
          } else {
            dev.log('SplashScreen: No profile for ${user.id}. Target: /create-profile.');
            determinedRoute = '/create-profile';
          }
        } catch (e) {
          dev.log('SplashScreen: Error checking profile: $e. Target: /login.');
          determinedRoute = '/login';
        }
      } else {
        dev.log('SplashScreen: User not authenticated. Target: /login.');
        determinedRoute = '/login';
      }
    }

    if (mounted) {
      setState(() {
        _targetRoute = determinedRoute;
        _authFlowCompleted = true;
      });
      _navigateIfReady();
    }
  }

  void _navigateIfReady() {
    dev.log('Attempting navigation: MinTime: $_minimumTimeElapsed, AuthFlow: $_authFlowCompleted, Route: $_targetRoute');
    if (_minimumTimeElapsed && _authFlowCompleted && _targetRoute != null && mounted) {
      // Ensure we don't get stuck in a loop if already on the target route or splash
      final currentLocation = GoRouterState.of(context).matchedLocation;
      if (_targetRoute == '/login' && (currentLocation == '/login' || currentLocation == '/')) {
        if (currentLocation == '/') {
            dev.log('SplashScreen: Conditions met, already on / and target is /login. Navigating to $_targetRoute');
            context.go(_targetRoute!); 
        } else {
            dev.log('SplashScreen: Conditions met, but already on /login. No navigation needed.');
        }
      } else if (currentLocation != _targetRoute) {
        dev.log('SplashScreen: Conditions met. Navigating to $_targetRoute');
        context.go(_targetRoute!); 
      } else {
        dev.log('SplashScreen: Conditions met, but already on target route $_targetRoute. No navigation needed.');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    dev.log('SplashScreen build');

    // Listen to authStateProvider changes within the build method.
    // This is the correct place for ref.listen according to Riverpod guidelines.
    ref.listen<AsyncValue<AuthState?>>(authStateProvider, (_, next) async {
      // Check if the widget is still mounted before processing the auth state.
      if (mounted) {
        await _handleAuthState(next.asData?.value);
      }
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage(AssetConstants.logoPath), width: 150, height: 250),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
} 