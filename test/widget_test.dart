import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaone_order/main.dart';

void main() {
  testWidgets('Pizza One app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PizzaOneOrderApp());
    expect(find.byType(PizzaOneOrderApp), findsOneWidget);
  });
}
