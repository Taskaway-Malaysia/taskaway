import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
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

  // Initialize deep linking
  final appLinks = AppLinks();

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
      debug: true, // Enable debug mode to see detailed logs
    );
    dev.log('Supabase initialized successfully');
  } catch (e) {
    dev.log('Error initializing Supabase: $e');
    return;
  }

  // Handle app start from link
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    dev.log('App started from link: $initialUri');
  }

  // Handle links while app is running
  appLinks.uriLinkStream.listen((uri) {
    dev.log('Received link while app running: $uri');
    // Handle the link - we'll do this in the app
  });

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
  late final AppLinks _appLinks;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  Future<void> _initAppLinks() async {
    if (_isInitialized) return;

    _appLinks = AppLinks();

    // Check initial link if app was launched from dead state
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        dev.log('Initial link: $uri');
        _handleIncomingLink(uri);
      }
    } catch (e) {
      dev.log('Error getting initial link: $e');
    }

    // Handle incoming links when app is in memory
    _appLinks.uriLinkStream.listen((uri) {
      dev.log('Received link: $uri');
      _handleIncomingLink(uri);
    }, onError: (err) {
      dev.log('Error processing link: $err');
    });

    _isInitialized = true;
  }

  void _handleIncomingLink(Uri uri) {
    final router = ref.read(appRouterProvider);
    final path = uri.path;
    if (path.isNotEmpty) {
      router.go(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: StyleConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme, // Using lightTheme for darkTheme as well
      themeMode: ThemeMode.light, // Force light mode regardless of system settings
      routerConfig: router,
    );
  }
}
