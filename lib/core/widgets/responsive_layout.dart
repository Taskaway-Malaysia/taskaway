import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taskaway/core/constants/style_constants.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // On web, wrap the child in a centered, constrained box to create the boxed layout.
    if (kIsWeb) {
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
    // On other platforms, return the child directly.
    return child;
  }
}
