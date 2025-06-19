import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart'; // For isGuestModeProvider

class GuestPromptOverlay extends ConsumerWidget {
  const GuestPromptOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black.withValues(alpha: 0.5), // Semi-transparent background
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(StyleConstants.defaultPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(StyleConstants.defaultPadding * 1.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Oops...',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: StyleConstants.defaultPadding),
                Text(
                  'You have to login or create an account in order to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: StyleConstants.defaultPadding * 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                      onPressed: () {
                        ref.read(isGuestModeProvider.notifier).state = false; // Exit guest mode
                        context.go('/create-account');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: StyleConstants.taskerColorPrimary),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Sign Up'),
                    ),
                    ),
                    const SizedBox(width: StyleConstants.defaultPadding),
                    Expanded(
                      child: ElevatedButton(
                      onPressed: () {
                        ref.read(isGuestModeProvider.notifier).state = false; // Exit guest mode
                        context.go('/login');
                      },
                       style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Login'),
                    ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
