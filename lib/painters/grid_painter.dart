import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  const GridPainter({this.gridSize = 20});

  final double gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    const majorEvery = 5;

    final minorPaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.18)
      ..strokeWidth = 0.65;

    final majorPaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.32)
      ..strokeWidth = 1.0;

    int index = 0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        index % majorEvery == 0 ? majorPaint : minorPaint,
      );

      index++;
    }

    index = 0;

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index % majorEvery == 0 ? majorPaint : minorPaint,
      );

      index++;
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return false;
  }
}
