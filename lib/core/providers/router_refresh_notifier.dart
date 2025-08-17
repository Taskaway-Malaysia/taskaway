import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'deep_link_provider.dart';

/// Composite notifier that listens to multiple providers
/// and notifies GoRouter to refresh when any of them change
class RouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;
  
  RouterRefreshNotifier(this._ref) {
    // Listen to auth state changes
    _ref.listen(authNotifierProvider, (_, __) {
      notifyListeners();
    });
    
    // Listen to deep link changes
    _ref.listen(deepLinkProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});