// Boot smoke test. Real tests added later per feature.

import 'package:flutter_test/flutter_test.dart';

import 'package:employee_app/main.dart';

void main() {
  testWidgets('App boots without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const CofflowEmployeeApp());
    await tester.pump();
    // Splash route renders a CircularProgressIndicator initially.
    expect(find.byType(CofflowEmployeeApp), findsOneWidget);
  });
}
