import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mom_teacher_assistant/models/board_item.dart';

void main() {
  test('Freehand item survives JSON conversion', () {
    final original = FreehandItem(
      points: const [Offset(10, 20), Offset(30.5, 40.25)],
      color: Colors.red,
      width: 4.5,
    );

    final restored = boardItemFromJson(original.toJson());

    expect(restored, isA<FreehandItem>());

    final item = restored as FreehandItem;

    expect(item.points.length, 2);

    expect(item.points[0], const Offset(10, 20));

    expect(item.points[1], const Offset(30.5, 40.25));

    expect(item.color.toARGB32(), Colors.red.toARGB32());

    expect(item.width, 4.5);
  });

  test('Line and axis survive JSON conversion', () {
    final line = LineItem(
      start: const Offset(1, 2),
      end: const Offset(50, 70),
      color: Colors.blue,
      width: 3,
    );

    final axis = AxisItem(
      origin: const Offset(100, 120),
      extent: 80,
      color: Colors.green,
      width: 2,
    );

    expect(boardItemFromJson(line.toJson()), isA<LineItem>());

    expect(boardItemFromJson(axis.toJson()), isA<AxisItem>());
  });
}
