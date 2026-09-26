import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mom_teacher_assistant/models/book_record.dart';
import 'package:mom_teacher_assistant/screens/home_page.dart';

void main() {
  testWidgets('Teacher Assistant empty library loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(loadBooksOverride: () async => <BookRecord>[]),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('مساعد المعلمة'), findsOneWidget);

    expect(find.text('مكتبتي'), findsOneWidget);

    expect(find.text('لا توجد كتب مضافة حتى الآن'), findsOneWidget);

    expect(find.text('إضافة أول كتاب'), findsOneWidget);
  });
}
