import 'package:flutter_test/flutter_test.dart';
import 'package:healthexpress/main.dart';

void main() {
  testWidgets('App initializes splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthExpressApp());
    expect(find.byType(HealthExpressApp), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
