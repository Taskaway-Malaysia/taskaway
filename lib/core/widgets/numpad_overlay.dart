import 'package:flutter/material.dart';
import 'package:taskaway/core/constants/style_constants.dart'; // For theme colors

class NumpadOverlay extends StatelessWidget {
  final ValueSetter<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onConfirmPressed;
  final String confirmButtonText;
  final TextEditingController? previewController;

  const NumpadOverlay({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onConfirmPressed,
    this.confirmButtonText = 'Confirm',
    this.previewController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Use cardColor for background
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(context),
          if (previewController != null) _buildPreview(context),
          const SizedBox(height: 20),
          _buildNumpadGrid(context),
          const SizedBox(height: 24),
          _buildActionButton(context),
          const SizedBox(height: 8), // For bottom padding if used in modal
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildNumpadGrid(BuildContext context) {
    final List<String> keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '',  '0', '<', // Using '<' for backspace
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8, // Adjusted for better button proportions
      children: keys.map((key) {
        if (key.isEmpty) {
          return Container(); // Empty space for layout
        }
        return NumpadButton(
          text: key,
          onPressed: () {
            if (key == '<') {
              onBackspacePressed();
            } else {
              onDigitPressed(key);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: StyleConstants.taskerColorPrimary,
          foregroundColor: Colors.white,
        ),
        onPressed: onConfirmPressed,
        child: Text(confirmButtonText),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: previewController!,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value.text.isEmpty ? ' ' : value.text, // Use space to maintain height
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

class NumpadButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const NumpadButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.all(12.0), // Adjusted padding
      ),
      child: text == '<'
          ? Icon(
              Icons.backspace_outlined,
              size: 26,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            )
          : Text(
              text,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600, // Slightly less bold
                  ),
            ),
    );
  }
}
