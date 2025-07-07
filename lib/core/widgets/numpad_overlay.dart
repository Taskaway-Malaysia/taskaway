import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskaway/core/constants/style_constants.dart'; // For theme colors

class NumpadOverlay extends StatefulWidget {
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
  State<NumpadOverlay> createState() => _NumpadOverlayState();
}

class _NumpadOverlayState extends State<NumpadOverlay> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      if (key.keyId >= LogicalKeyboardKey.digit0.keyId &&
          key.keyId <= LogicalKeyboardKey.digit9.keyId) {
        widget.onDigitPressed(key.keyLabel);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.numpad0 ||
          key == LogicalKeyboardKey.numpad1 ||
          key == LogicalKeyboardKey.numpad2 ||
          key == LogicalKeyboardKey.numpad3 ||
          key == LogicalKeyboardKey.numpad4 ||
          key == LogicalKeyboardKey.numpad5 ||
          key == LogicalKeyboardKey.numpad6 ||
          key == LogicalKeyboardKey.numpad7 ||
          key == LogicalKeyboardKey.numpad8 ||
          key == LogicalKeyboardKey.numpad9) {
        widget.onDigitPressed(key.keyLabel);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.backspace) {
        widget.onBackspacePressed();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        widget.onConfirmPressed();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
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
            if (widget.previewController != null) _buildPreview(context),
            const SizedBox(height: 20),
            _buildNumpadGrid(context),
            const SizedBox(height: 24),
            _buildActionButton(context),
            const SizedBox(height: 8), // For bottom padding if used in modal
          ],
        ),
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
      '', '0', '<', // Using '<' for backspace
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
              widget.onBackspacePressed();
            } else {
              widget.onDigitPressed(key);
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
        onPressed: widget.onConfirmPressed,
        child: Text(widget.confirmButtonText),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.previewController!,
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
