import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskaway/features/home/widgets/map_widget.dart';

class ViewListToggle extends ConsumerWidget {
  final VoidCallback? onToggle;

  const ViewListToggle({super.key, this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(viewModeProvider);

    return GestureDetector(
      onTap: () {
        final newMode = currentMode == ViewMode.map ? ViewMode.list : ViewMode.map;
        ref.read(viewModeProvider.notifier).state = newMode;
        onToggle?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 11,
              height: 11,
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size(11, 11),
                painter: _ListIconPainter(),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'VIEW LIST',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
                color: const Color(0xFF575656),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines to represent list view
    final lineSpacing = size.height / 4;
    
    // Top line
    canvas.drawLine(
      Offset(3.67, 2.29),
      Offset(9.63, 2.29),
      paint,
    );
    
    // Middle line
    canvas.drawLine(
      Offset(3.67, 5.5),
      Offset(9.63, 5.5),
      paint,
    );
    
    // Bottom line
    canvas.drawLine(
      Offset(3.67, 8.71),
      Offset(9.63, 8.71),
      paint,
    );
    
    // Left side dots
    canvas.drawLine(
      Offset(1.37, 2.29),
      Offset(1.38, 2.29),
      paint,
    );
    
    canvas.drawLine(
      Offset(1.37, 5.5),
      Offset(1.38, 5.5),
      paint,
    );
    
    canvas.drawLine(
      Offset(1.37, 8.71),
      Offset(1.38, 8.71),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}