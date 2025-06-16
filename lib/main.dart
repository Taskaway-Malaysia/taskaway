import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'core/constants/api_constants.dart';
import 'core/constants/style_constants.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

void main() async {
  // Use path URL strategy for web
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
      debug: true, // Enable debug mode to see detailed logs
    );
    _logger.i('Supabase initialized successfully');
  } catch (e) {
    _logger.e('Error initializing Supabase: $e');
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
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
