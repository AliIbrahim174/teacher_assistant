import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

enum BoardTool { pen, highlighter, eraser, line, axis }

abstract class BoardItem {
  void draw(Canvas canvas);

  bool hitTest(Offset point);
}

class FreehandItem extends BoardItem {
  FreehandItem({
    required this.points,
    required this.color,
    required this.width,
  });

  final List<Offset> points;
  final Color color;
  final double width;

  @override
  void draw(Canvas canvas) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        width / 2,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );

      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      final midpoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );

      path.quadraticBezierTo(current.dx, current.dy, midpoint.dx, midpoint.dy);
    }

    path.lineTo(points.last.dx, points.last.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool hitTest(Offset point) {
    final tolerance = 18 + width / 2;

    if (points.length == 1) {
      return (points.first - point).distance <= tolerance;
    }

    for (int i = 1; i < points.length; i++) {
      if (distancePointToLine(point, points[i - 1], points[i]) <= tolerance) {
        return true;
      }
    }

    return false;
  }
}

class LineItem extends BoardItem {
  LineItem({
    required this.start,
    required this.end,
    required this.color,
    required this.width,
  });

  final Offset start;
  final Offset end;

  final Color color;
  final double width;

  @override
  void draw(Canvas canvas) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool hitTest(Offset point) {
    return distancePointToLine(point, start, end) < 20;
  }
}

class AxisItem extends BoardItem {
  AxisItem({
    required this.origin,
    required this.extent,
    required this.color,
    required this.width,
  });

  final Offset origin;

  final double extent;

  final Color color;

  final double width;

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final left = Offset(origin.dx - extent, origin.dy);

    final right = Offset(origin.dx + extent, origin.dy);

    final top = Offset(origin.dx, origin.dy - extent);

    final bottom = Offset(origin.dx, origin.dy + extent);

    canvas.drawLine(left, right, paint);

    canvas.drawLine(top, bottom, paint);

    _drawArrow(canvas, tip: right, directionAngle: math.pi, paint: paint);

    _drawArrow(canvas, tip: top, directionAngle: math.pi / 2, paint: paint);

    _drawLabel(canvas, 'س', Offset(right.dx - 20, right.dy + 8));

    _drawLabel(canvas, 'ص', Offset(top.dx + 8, top.dy + 5));
  }

  void _drawArrow(
    Canvas canvas, {
    required Offset tip,
    required double directionAngle,
    required Paint paint,
  }) {
    const arrowSize = 11.0;

    final first = Offset(
      tip.dx + arrowSize * math.cos(directionAngle + math.pi / 4),
      tip.dy + arrowSize * math.sin(directionAngle + math.pi / 4),
    );

    final second = Offset(
      tip.dx + arrowSize * math.cos(directionAngle - math.pi / 4),
      tip.dy + arrowSize * math.sin(directionAngle - math.pi / 4),
    );

    canvas.drawLine(tip, first, paint);

    canvas.drawLine(tip, second, paint);
  }

  void _drawLabel(Canvas canvas, String text, Offset position) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    painter.paint(canvas, position);
  }

  @override
  bool hitTest(Offset point) {
    final horizontalStart = Offset(origin.dx - extent, origin.dy);

    final horizontalEnd = Offset(origin.dx + extent, origin.dy);

    final verticalStart = Offset(origin.dx, origin.dy - extent);

    final verticalEnd = Offset(origin.dx, origin.dy + extent);

    return distancePointToLine(point, horizontalStart, horizontalEnd) < 20 ||
        distancePointToLine(point, verticalStart, verticalEnd) < 20;
  }
}

double distancePointToLine(Offset point, Offset start, Offset end) {
  final line = end - start;

  final lengthSquared = line.dx * line.dx + line.dy * line.dy;

  if (lengthSquared == 0) {
    return (point - start).distance;
  }

  double t =
      ((point.dx - start.dx) * line.dx + (point.dy - start.dy) * line.dy) /
      lengthSquared;

  t = t.clamp(0.0, 1.0);

  final projection = Offset(start.dx + t * line.dx, start.dy + t * line.dy);

  return (point - projection).distance;
}
