import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/core/constants/asset_constants.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/onboarding/controllers/onboarding_controller.dart';
import 'package:taskaway/core/utils/debug_logger.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minimumTimeElapsed = false;
  bool _authFlowCompleted = false;
  bool _showInitialWhiteScreen = true;
  String? _targetRoute;
  Timer? _timer;
  Timer? _whiteScreenTimer;

  @override
  void initState() {
    super.initState();
    DebugLogger.log('=== SPLASH SCREEN INIT STATE STARTED ===');
    DebugLogger.log('SplashScreen initState at ${DateTime.now()}');

    // First show white screen for 0.5 seconds
    _whiteScreenTimer = Timer(const Duration(milliseconds: 500), () {
      DebugLogger.log('White screen timer fired (500ms elapsed)');
      if (mounted) {
        setState(() {
          _showInitialWhiteScreen = false;
        });
        DebugLogger.log('White screen hidden, showing splash content');
        
        // After white screen, show splash content for 2.5 seconds
        _timer = Timer(const Duration(milliseconds: 2500), () {
          DebugLogger.log('Splash content timer fired (2500ms elapsed)');
          if (mounted) {
            setState(() {
              _minimumTimeElapsed = true;
            });
            DebugLogger.log('Minimum time elapsed set to true, calling _navigateIfReady');
            _navigateIfReady();
          } else {
            DebugLogger.log('WARNING: Widget not mounted when timer fired');
          }
        });
      } else {
        DebugLogger.log('WARNING: Widget not mounted for white screen timer');
      }
    });

    Future.microtask(() async {
      DebugLogger.log('Starting auth state check microtask');
      final initialAuthState = ref.read(authStateProvider);
      DebugLogger.log('Initial auth state type: ${initialAuthState.runtimeType}');
      DebugLogger.log('Initial auth state value: $initialAuthState');
      
      // Check if the widget is still mounted before processing the auth state.
      if (mounted && initialAuthState is AsyncData<AuthState?>) {
        DebugLogger.log('Processing initial auth state (AsyncData)');
        await _handleAuthState(initialAuthState.value);
      } else if (initialAuthState is AsyncLoading) {
        DebugLogger.log('Auth state is still loading');
      } else if (initialAuthState is AsyncError) {
        DebugLogger.log('Auth state has error: ${initialAuthState.error}');
      } else {
        DebugLogger.log('Auth state is in unexpected state: $initialAuthState');
      }
    });
  }

  Future<void> _handleAuthState(AuthState? authState) async {
    DebugLogger.log('=== _handleAuthState CALLED ===');
    final isPasswordRecoveryFlow = ref.read(passwordRecoveryFlowProvider);
    DebugLogger.log('AuthState event: ${authState?.event}');
    DebugLogger.log('AuthState session: ${authState?.session != null ? "exists" : "null"}');
    DebugLogger.log('isPasswordRecoveryFlow: $isPasswordRecoveryFlow');
    
    String? determinedRoute;

    if (authState?.event == AuthChangeEvent.passwordRecovery) {
      DebugLogger.log('Password recovery event detected. Starting flow.');
      ref.read(passwordRecoveryFlowProvider.notifier).state = true;
      determinedRoute = '/change-password';
    } else if (isPasswordRecoveryFlow) {
      // We are in the password recovery flow
      if (authState?.event == AuthChangeEvent.signedOut) {
        DebugLogger.log('Password recovery flow: signedOut. Navigating to success.');
        determinedRoute = '/change-password-success';
        ref.read(passwordRecoveryFlowProvider.notifier).state = false; // End of flow
      } else if (authState?.event == AuthChangeEvent.signedIn || authState?.event == AuthChangeEvent.userUpdated) {
        DebugLogger.log('Password recovery flow: ${authState?.event} received. Awaiting signOut.');
        return; // Critical: Do not proceed to set route or call _navigateIfReady
      } else {
        DebugLogger.log('Password recovery flow: Unexpected event ${authState?.event}. Resetting flow, to login.');
        determinedRoute = '/login';
        ref.read(passwordRecoveryFlowProvider.notifier).state = false;
      }
    } else {
      // Regular auth flow
      DebugLogger.log('Regular auth flow starting...');
      if (isPasswordRecoveryFlow) {
        DebugLogger.log('Resetting password recovery flow flag');
        ref.read(passwordRecoveryFlowProvider.notifier).state = false;
      }

      if (authState?.session != null) {
        final user = authState!.session!.user;
        DebugLogger.log('User authenticated with ID: ${user.id}');
        DebugLogger.log('User email: ${user.email}');
        
        try {
          DebugLogger.log('Checking for user profile...');
          final profileResponse = await Supabase.instance.client
              .from('taskaway_profiles')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          DebugLogger.log('Profile response: $profileResponse');
          
          if (profileResponse != null) {
            DebugLogger.log('Profile found! Setting target: /home');
            determinedRoute = '/home';
          } else {
            DebugLogger.log('No profile found. Setting target: /create-profile');
            determinedRoute = '/create-profile';
          }
        } catch (e, stack) {
          DebugLogger.log('ERROR checking profile: $e');
          DebugLogger.log('Stack trace: $stack');
          DebugLogger.log('Defaulting to /login due to error');
          determinedRoute = '/login';
        }
      } else {
        DebugLogger.log('No session found. User not authenticated. Target: /login');
        determinedRoute = '/login';
      }
    }

    DebugLogger.log('Determined route: $determinedRoute');
    
    if (mounted) {
      DebugLogger.log('Widget is mounted, updating state...');
      setState(() {
        _targetRoute = determinedRoute;
        _authFlowCompleted = true;
      });
      DebugLogger.log('State updated: _targetRoute=$_targetRoute, _authFlowCompleted=$_authFlowCompleted');
      DebugLogger.log('Calling _navigateIfReady from _handleAuthState');
      _navigateIfReady();
    } else {
      DebugLogger.log('WARNING: Widget not mounted, cannot update state');
    }
  }

  void _navigateIfReady() async {
    DebugLogger.log('=== _navigateIfReady CALLED ===');
    DebugLogger.log('Current state:');
    DebugLogger.log('  - _minimumTimeElapsed: $_minimumTimeElapsed');
    DebugLogger.log('  - _authFlowCompleted: $_authFlowCompleted');
    DebugLogger.log('  - mounted: $mounted');
    DebugLogger.log('  - _targetRoute: $_targetRoute');
    
    if (!_minimumTimeElapsed) {
      DebugLogger.log('Navigation blocked: Minimum time not elapsed');
      return;
    }
    if (!_authFlowCompleted) {
      DebugLogger.log('Navigation blocked: Auth flow not completed');
      return;
    }
    if (!mounted) {
      DebugLogger.log('Navigation blocked: Widget not mounted');
      return;
    }
    if (_targetRoute == null) {
      DebugLogger.log('Navigation blocked: Target route is null');
      return;
    }
    
    DebugLogger.log('All conditions met, proceeding with navigation logic');
    
    try {
      // Check if onboarding has been completed (async)
      DebugLogger.log('Checking onboarding status...');
      final onboardingProvider = ref.read(onboardingCompletedProvider);
      
      if (onboardingProvider is AsyncLoading) {
        DebugLogger.log('Onboarding provider is still loading, waiting...');
        final onboardingAsync = await ref.read(onboardingCompletedProvider.future);
        DebugLogger.log('Onboarding completed status: $onboardingAsync');
        final bool onboardingCompleted = onboardingAsync;
        
        // If onboarding not completed, navigate to onboarding first
        if (!onboardingCompleted && (_targetRoute == '/login' || _targetRoute == '/home')) {
          DebugLogger.log('Onboarding not completed, navigating to /onboarding');
          context.go('/onboarding');
        } else {
          _navigateToTarget();
        }
      } else if (onboardingProvider is AsyncData) {
        final bool onboardingCompleted = onboardingProvider.value ?? false;
        DebugLogger.log('Onboarding completed status (from AsyncData): $onboardingCompleted');
        
        if (!onboardingCompleted && (_targetRoute == '/login' || _targetRoute == '/home')) {
          DebugLogger.log('Onboarding not completed, navigating to /onboarding');
          context.go('/onboarding');
        } else {
          _navigateToTarget();
        }
      } else if (onboardingProvider is AsyncError) {
        DebugLogger.log('ERROR: Onboarding provider has error: ${onboardingProvider.error}');
        DebugLogger.log('Defaulting to target route: $_targetRoute');
        _navigateToTarget();
      }
    } catch (e, stack) {
      DebugLogger.log('ERROR in _navigateIfReady: $e');
      DebugLogger.log('Stack trace: $stack');
      // Navigate to target route as fallback
      _navigateToTarget();
    }
  }
  
  void _navigateToTarget() {
    // Ensure we don't get stuck in a loop if already on the target route or splash
    final currentLocation = GoRouterState.of(context).matchedLocation;
    DebugLogger.log('Current location: $currentLocation, Target: $_targetRoute');
    
    if (currentLocation != _targetRoute) {
      DebugLogger.log('NAVIGATING TO: $_targetRoute');
      context.go(_targetRoute!); 
    } else {
      DebugLogger.log('Already on target route $_targetRoute. No navigation needed.');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _whiteScreenTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DebugLogger.log('=== SPLASH SCREEN BUILD ===');
    DebugLogger.log('Build called at ${DateTime.now()}');
    DebugLogger.log('showWhiteScreen: $_showInitialWhiteScreen');
    DebugLogger.log('minimumTimeElapsed: $_minimumTimeElapsed');
    DebugLogger.log('authFlowCompleted: $_authFlowCompleted');
    DebugLogger.log('targetRoute: $_targetRoute');

    // Listen to authStateProvider changes within the build method.
    // This is the correct place for ref.listen according to Riverpod guidelines.
    ref.listen<AsyncValue<AuthState?>>(authStateProvider, (previous, next) async {
      DebugLogger.log('=== AUTH STATE LISTENER TRIGGERED ===');
      DebugLogger.log('Previous auth state: $previous');
      DebugLogger.log('Next auth state: $next');
      
      // Check if the widget is still mounted before processing the auth state.
      if (mounted) {
        if (next is AsyncData) {
          DebugLogger.log('Auth state is AsyncData, processing...');
          await _handleAuthState(next.value);
        } else if (next is AsyncLoading) {
          DebugLogger.log('Auth state is AsyncLoading, waiting...');
        } else if (next is AsyncError) {
          DebugLogger.log('Auth state is AsyncError: ${next.error}');
        }
      } else {
        DebugLogger.log('WARNING: Widget not mounted in auth listener');
      }
    });

    // Show white screen for first 0.5 seconds
    if (_showInitialWhiteScreen) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(),
      );
    }
    
    // Then show the actual splash screen content for 2.5 seconds
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