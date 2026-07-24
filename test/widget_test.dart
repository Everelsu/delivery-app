import 'package:flutter_test/flutter_test.dart';

import 'package:sprint_courier/main.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SprintApp());
    expect(find.text('Вход для курьера'), findsOneWidget);
    expect(find.text('Получить код'), findsOneWidget);
  });
}
