import 'package:flutter/material.dart';

class FaceLivenessPainter extends CustomPainter {
  final bool waitingForNeutral;
  final bool isFaceInFrame;

  const FaceLivenessPainter({
    required this.waitingForNeutral,
    required this.isFaceInFrame,
  });

  Color getFrameColor() {
    if (waitingForNeutral) {
      return Colors.green;
    } else if (isFaceInFrame) {
      return Colors.white;
    } else {
      return Colors.red;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    final ellipseWidth = size.width * 0.6;
    final ellipseHeight = size.height * 0.4;

    final ovalRect = Rect.fromCenter(
      center: center,
      width: ellipseWidth,
      height: ellipseHeight,
    );

    // Draw Circle
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw Stoke
    final strokePaint = Paint()
      ..color = getFrameColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawOval(ovalRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant FaceLivenessPainter oldDelegate) {
    return oldDelegate.waitingForNeutral != waitingForNeutral ||
        oldDelegate.isFaceInFrame != isFaceInFrame;
  }
}
