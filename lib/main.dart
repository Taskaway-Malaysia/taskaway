import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// Only import web plugins when needed
import 'core/constants/api_constants.dart';
import 'core/constants/style_constants.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
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
    dev.log('Firebase initialized successfully');
    
    // Initialize Supabase
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
      debug: true, // Enable debug mode to see detailed logs
    );
    dev.log('Supabase initialized successfully');
  } catch (e) {
    dev.log('Error initializing services: $e');
    return;
  }

  runApp(
    const ProviderScope(
      child: TaskawayApp(),
    ),
  );
}

class TaskawayApp extends ConsumerWidget {
  const TaskawayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
