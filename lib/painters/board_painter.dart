import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/board_item.dart';

class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.items,
    required this.tool,
    required this.dragStart,
    required this.dragCurrent,
    required this.previewColor,
    required this.previewWidth,
    required this.gridSize,
  });

  final List<BoardItem> items;

  final BoardTool tool;

  final Offset? dragStart;

  final Offset? dragCurrent;

  final Color previewColor;

  final double previewWidth;

  final double gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      item.draw(canvas);
    }

    final start = dragStart;
    final current = dragCurrent;

    if (start == null || current == null) {
      return;
    }

    if (tool == BoardTool.line) {
      LineItem(
        start: start,
        end: current,
        color: previewColor.withValues(alpha: 0.65),
        width: previewWidth,
      ).draw(canvas);
    }

    if (tool == BoardTool.axis) {
      final dx = (current.dx - start.dx).abs();

      final dy = (current.dy - start.dy).abs();

      double extent = math.max(dx, dy);

      if (extent < 60) {
        extent = 100;
      }

      extent = (extent / gridSize).round() * gridSize;

      final axisWidth = previewWidth < 2 ? 2.0 : previewWidth;

      AxisItem(
        origin: start,
        extent: extent,
        color: previewColor.withValues(alpha: 0.65),
        width: axisWidth,
      ).draw(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return true;
  }
}
