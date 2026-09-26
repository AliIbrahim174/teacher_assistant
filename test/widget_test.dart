import 'package:flutter_test/flutter_test.dart';

import 'package:mom_teacher_assistant/main.dart';

void main() {
  testWidgets('Teacher Assistant home screen loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MomTeacherAssistant());

    await tester.pumpAndSettle();

    expect(find.text('مساعد المعلمة'), findsOneWidget);

    expect(find.text('الكتب'), findsOneWidget);

    expect(find.text('إضافة كتاب'), findsOneWidget);
  });
}
