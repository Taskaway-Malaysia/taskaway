import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskaway/core/constants/style_constants.dart';

enum KeyboardLayout { lowercase, uppercase, numbers, symbols }

class QwertyOverlay extends StatefulWidget {
  final TextEditingController previewController;
  final ValueSetter<String> onCharacterPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onConfirmPressed;
  final String confirmButtonText;
  final bool obscureText;

  const QwertyOverlay({
    super.key,
    required this.previewController,
    required this.onCharacterPressed,
    required this.onBackspacePressed,
    required this.onConfirmPressed,
    this.confirmButtonText = 'Done',
    this.obscureText = false,
  });

  @override
  State<QwertyOverlay> createState() => _QwertyOverlayState();
}

class _QwertyOverlayState extends State<QwertyOverlay> {
  final FocusNode _focusNode = FocusNode();
  KeyboardLayout _currentLayout = KeyboardLayout.lowercase;
  bool _capsLockEnabled = false;
  bool _showPassword = false;
  int _lastShiftPressTime = 0;

  @override
  void initState() {
    super.initState();
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

      if (key == LogicalKeyboardKey.backspace) {
        widget.onBackspacePressed();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
        widget.onConfirmPressed();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.space) {
        widget.onCharacterPressed(' ');
        return KeyEventResult.handled;
      } else if (event.character != null && event.character!.isNotEmpty) {
        widget.onCharacterPressed(event.character!); 
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // Layouts
  static const List<String> _row1Lower = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
  static const List<String> _row2Lower = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
  static const List<String> _row3Lower = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

  static const List<String> _row1Upper = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
  static const List<String> _row2Upper = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
  static const List<String> _row3Upper = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  static const List<String> _row1Num = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
  static const List<String> _row2Num = ['-', '/', ':', ';', '(', ')', '\$', '&', '@', '"'];
  static const List<String> _row3Num = ['.', ',', '?', '!', "'"];

  static const List<String> _row1Sym = ['[', ']', '{', '}', '#', '%', '^', '*', '+', '='];
  static const List<String> _row2Sym = ['_', '\\', '|', '~', '<', '>', '€', '£', '¥', '•'];
  static const List<String> _row3Sym = ['.', ',', '?', '!', "'"];

  void _toggleShift() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final doubleTapDetected = now - _lastShiftPressTime < 300;

    setState(() {
      if (_capsLockEnabled) {
        _capsLockEnabled = false;
        _currentLayout = KeyboardLayout.lowercase;
      } else if (doubleTapDetected) {
        _capsLockEnabled = true;
        _currentLayout = KeyboardLayout.uppercase;
      } else {
        _currentLayout = _currentLayout == KeyboardLayout.lowercase
            ? KeyboardLayout.uppercase
            : KeyboardLayout.lowercase;
      }
    });

    _lastShiftPressTime = now;
  }

  void _toggleNumeric() {
    setState(() {
      _currentLayout = _currentLayout == KeyboardLayout.numbers
          ? KeyboardLayout.lowercase
          : KeyboardLayout.numbers;
    });
  }

  void _toggleSymbols() {
    setState(() {
      _currentLayout = _currentLayout == KeyboardLayout.symbols
          ? KeyboardLayout.numbers
          : KeyboardLayout.symbols;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
            _buildPreview(context),
            const SizedBox(height: 12),
            _buildKeyboard(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 5,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.previewController,
      builder: (context, value, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.obscureText && !_showPassword ? '•' * value.text.length : value.text,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.obscureText)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    size: 22,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeyboard(BuildContext context) {
    bool isNumericLayout = _currentLayout == KeyboardLayout.numbers || _currentLayout == KeyboardLayout.symbols;

    List<String> row1, row2, row3;

    switch (_currentLayout) {
      case KeyboardLayout.uppercase:
        row1 = _row1Upper;
        row2 = _row2Upper;
        row3 = _row3Upper;
        break;
      case KeyboardLayout.numbers:
        row1 = _row1Num;
        row2 = _row2Num;
        row3 = _row3Num;
        break;
      case KeyboardLayout.symbols:
        row1 = _row1Sym;
        row2 = _row2Sym;
        row3 = _row3Sym;
        break;
      case KeyboardLayout.lowercase:
        row1 = _row1Lower;
        row2 = _row2Lower;
        row3 = _row3Lower;
        break;
    }

    return Column(
      children: [
        _buildKeyRow(row1),
        const SizedBox(height: 8),
        _buildKeyRow(row2),
        const SizedBox(height: 8),
        Row(
          children: [
            isNumericLayout
                ? _buildSpecialKey(
                    width: 60,
                    onPressed: _toggleSymbols,
                    child: Text(_currentLayout == KeyboardLayout.numbers ? '#+=' : '123'),
                  )
                : _buildSpecialKey(
                    onPressed: _toggleShift,
                    icon: _capsLockEnabled ? Icons.keyboard_capslock : (_currentLayout == KeyboardLayout.uppercase ? Icons.arrow_upward : Icons.arrow_upward_outlined),
                    color: (_capsLockEnabled || _currentLayout == KeyboardLayout.uppercase) ? StyleConstants.posterColorLight : null,
                  ),
            Expanded(child: _buildKeyRow(row3)),
            _buildSpecialKey(
              icon: Icons.backspace_outlined,
              onPressed: widget.onBackspacePressed,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSpecialKey(
              width: 60,
              child: Text((_currentLayout == KeyboardLayout.numbers || _currentLayout == KeyboardLayout.symbols) ? 'ABC' : '123'),
              onPressed: _toggleNumeric,
            ),
            Expanded(
              child: _buildSpecialKey(
                child: const Icon(Icons.space_bar),
                onPressed: () => widget.onCharacterPressed(' '),
              ),
            ),
            _buildSpecialKey(
              width: 80,
              child: Text(widget.confirmButtonText),
              onPressed: widget.onConfirmPressed,
              color: StyleConstants.taskerColorPrimary,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    return Expanded(
      child: InkWell(
        onTap: () {
          widget.onCharacterPressed(key);
          // After typing a character, if shift is on but not caps lock, turn it off
          if (_currentLayout == KeyboardLayout.uppercase && !_capsLockEnabled) {
            setState(() {
              _currentLayout = KeyboardLayout.lowercase;
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              key,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    Widget? child,
    IconData? icon,
    required VoidCallback onPressed,
    double width = 48,
    Color? color,
  }) {
    return SizedBox(
      width: width,
      height: 44,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color ?? Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(child: child ?? Icon(icon, size: 22)),
        ),
      ),
    );
  }
}