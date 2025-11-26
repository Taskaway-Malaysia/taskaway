import 'dart:math' show sqrt;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taskaway/core/constants/style_constants.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.child,
    super.key,
  });

  final Widget child;

  /// TASK-186: Detect if device is a tablet (iPad, Android tablet, etc.)
  /// Uses screen diagonal to determine if device is tablet-sized
  static bool isTablet(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    final double diagonal = sqrt(data.size.width * data.size.width +
                                 data.size.height * data.size.height);
    // Tablets typically have diagonal > 600 logical pixels
    // iPad Air 5th gen has ~820dp diagonal in portrait
    return diagonal > 600;
  }

  @override
  Widget build(BuildContext context) {
    // TASK-186: Support for iPad Air 5th gen and other tablets
    // On web or tablets, wrap the child in a centered, constrained box
    if (kIsWeb || isTablet(context)) {
      return Material(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: StyleConstants.webMaxWidth,
            ),
            child: child, // This child will be the Navigator for the nested routes.
          ),
        ),
      );
    }
    // On mobile phones, return the child directly.
    return child;
  }
}
