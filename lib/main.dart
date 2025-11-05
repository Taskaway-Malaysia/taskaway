import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
// Only import web plugins when needed
import 'core/constants/api_constants.dart';
import 'core/constants/style_constants.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/fcm_service.dart';
import 'features/auth/repositories/profile_repository.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'dart:developer' as dev;

// We'll conditionally initialize web-specific functionality

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure web URL strategy if running on web
  // This is handled separately to avoid import errors on mobile
  if (kIsWeb) {
    // Web-specific initialization will be handled by the Flutter framework
    // We don't need to manually set the URL strategy for this app on mobile
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ignore: avoid_print
    print('[MAIN] Firebase initialized successfully');

    // Stripe removed - using CHIPP Gateway for payments

    // Initialize Supabase
    // ignore: avoid_print
    print('[MAIN] Initializing Supabase with URL: ${ApiConstants.supabaseUrl}');
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
      debug: true, // Enable debug mode to see detailed logs
    );
    // ignore: avoid_print
    print('[MAIN] Supabase initialized successfully');

    // Initialize FCM Service (only on mobile platforms)
    if (!kIsWeb) {
      try {
        // FCM initialization will be handled by FCMService
        // The token will be obtained and stored when user logs in
        // ignore: avoid_print
        print('[MAIN] FCM will be initialized after authentication');
      } catch (e) {
        // ignore: avoid_print
        print('[MAIN ERROR] Error setting up FCM: $e');
      }
    }
  } catch (e, stack) {
    // ignore: avoid_print
    print('[MAIN ERROR] Error initializing services: $e');
    // ignore: avoid_print
    print('[MAIN ERROR] Stack trace: $stack');
    // Don't return here - let the app try to run even if initialization fails
    // This will help us see error screens instead of blank screens
  }

  runApp(
    const ProviderScope(
      child: TaskawayApp(),
    ),
  );
}

class TaskawayApp extends ConsumerStatefulWidget {
  const TaskawayApp({super.key});

  @override
  ConsumerState<TaskawayApp> createState() => _TaskawayAppState();
}

class _TaskawayAppState extends ConsumerState<TaskawayApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();
  FCMService? _fcmService;
  ProfileRepository? _profileRepository;

  @override
  void initState() {
    super.initState();

    // Initialize deep link handling after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        // Only initialize deep links on mobile platforms
        _deepLinkService.initialize(ref);

        // Initialize FCM service immediately
        _initializeFCM();
      }
    });
  }

  /// Initialize FCM service and set up notification handlers
  Future<void> _initializeFCM() async {
    try {
      _fcmService = ref.read(fcmServiceProvider);
      _profileRepository = ref.read(profileRepositoryProvider);

      // Initialize FCM with notification tap handler
      await _fcmService!.initialize(
        onTap: (RemoteMessage message) {
          // Handle notification tap - navigate to relevant screen
          print('[FCM] Notification tapped: ${message.data}');

          // Extract navigation data from notification
          final taskId = message.data['task_id'] as String?;
          if (taskId != null) {
            // Navigate to task details
            // router.go('/tasks/$taskId');
            print('[FCM] Should navigate to task: $taskId');
          }
        },
      );

      print('[MAIN] FCM initialized successfully');

      // Check if user is already logged in and handle FCM token
      final authState = ref.read(authStateProvider);
      final user = authState.value?.session?.user;
      if (user != null) {
        print('[MAIN] User already logged in, storing FCM token');
        await _handleUserLogin(user.id);
      }
    } catch (e) {
      print('[MAIN ERROR] Failed to initialize FCM: $e');
    }
  }


  /// Handle user login - get and store FCM token
  Future<void> _handleUserLogin(String userId) async {
    try {
      // Get FCM token
      final token = await _fcmService?.getToken();
      if (token != null) {
        // Store token in user profile
        final success = await _profileRepository?.updateFCMToken(userId, token);
        if (success == true) {
          print('[FCM] Token stored for user $userId');
        }

        // Update last seen
        await _profileRepository?.updateLastSeen(userId);
      }
    } catch (e) {
      print('[FCM ERROR] Failed to handle user login: $e');
    }
  }

  /// Handle user logout - remove FCM token
  Future<void> _handleUserLogout(String? userId) async {
    if (userId == null) return;

    try {
      // Remove token from user profile
      final success = await _profileRepository?.removeFCMToken(userId);
      if (success == true) {
        print('[FCM] Token removed for user $userId');
      }
    } catch (e) {
      print('[FCM ERROR] Failed to handle user logout: $e');
    }
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Listen to auth state changes to manage FCM token
    // This must be in build method for Riverpod
    if (!kIsWeb) {
      ref.listen(authStateProvider, (previous, next) async {
        final user = next.value?.session?.user;

        if (user != null) {
          // User logged in - get FCM token and store it
          await _handleUserLogin(user.id);
        } else {
          // User logged out - remove FCM token
          await _handleUserLogout(previous?.value?.session?.user?.id);
        }
      });
    }

    return MaterialApp.router(
      title: StyleConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme, // Using lightTheme for darkTheme as well
      themeMode: ThemeMode.light, // Force light mode regardless of system settings
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
