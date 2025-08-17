import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to store pending deep link URL
/// This is used when the app is launched from a deep link
/// and needs to navigate after the router is initialized
class DeepLinkNotifier extends StateNotifier<String?> {
  DeepLinkNotifier() : super(null);

  void setPendingDeepLink(String? url) {
    print('[DeepLinkProvider] Setting pending deep link: $url');
    state = url;
  }

  void clearPendingDeepLink() {
    print('[DeepLinkProvider] Clearing pending deep link');
    state = null;
  }
}

final deepLinkProvider = StateNotifierProvider<DeepLinkNotifier, String?>((ref) {
  return DeepLinkNotifier();
});