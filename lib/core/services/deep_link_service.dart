import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/deep_link_provider.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  WidgetRef? _ref;
  bool _initialized = false;

  void initialize(WidgetRef ref) {
    // Prevent double initialization
    if (_initialized) {
      print('[DeepLinkService] Already initialized, skipping');
      return;
    }
    
    print('[DeepLinkService] Initializing...');
    _ref = ref;
    _appLinks = AppLinks();
    
    // Cancel any existing subscription first
    _linkSubscription?.cancel();

    // Handle app links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('[DeepLinkService] Stream received URI: $uri');
      _handleDeepLink(uri);
    }, onError: (error) {
      print('[DeepLinkService] Error in stream: $error');
    });

    // Handle initial link if app was launched from a deep link
    _handleInitialLink();
    _initialized = true;
    print('[DeepLinkService] Initialization complete');
  }

  Future<void> _handleInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('[DeepLinkService] Initial deep link detected: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('Error handling initial deep link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    print('[DeepLinkService] Received deep link: $uri');

    // Payment return deep links (taskaway://payment-return) are handled directly
    // by WebView in chip_payment_screen.dart - no global handling needed

    // Add other deep link handlers here as needed
    // Example: if (uri.scheme == 'taskaway' && uri.host == 'other-feature') { ... }
  }

  void dispose() {
    print('[DeepLinkService] Disposing...');
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
    _ref = null;
  }
}