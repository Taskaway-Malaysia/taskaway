import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';
// Only import web plugins when needed
import 'core/constants/api_constants.dart';
import 'core/constants/style_constants.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'core/services/deep_link_service.dart';
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
    
    // Initialize Stripe (only if not in mock mode and not on unsupported platforms)
    if (!ApiConstants.mockPayments) {
      try {
        // Set publishable key for both web and mobile
        Stripe.publishableKey = ApiConstants.stripePublishableKey;
        
        if (kIsWeb) {
          // For web, we need to apply settings after setting the key
          await Stripe.instance.applySettings();
          // ignore: avoid_print
          print('[MAIN] Stripe web configuration applied successfully');
        }
        
        // ignore: avoid_print
        print('[MAIN] Stripe configuration prepared successfully');
      } catch (e) {
        // ignore: avoid_print
        print('[MAIN] Stripe initialization error (non-fatal): $e');
      }
    } else {
      // ignore: avoid_print
      print('[MAIN] Stripe initialization skipped (mock mode enabled)');
    }
    
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

  @override
  void initState() {
    super.initState();
    // Initialize deep link handling after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        // Only initialize deep links on mobile platforms
        _deepLinkService.initialize(ref);
      }
    });
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    
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
