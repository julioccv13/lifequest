import 'package:flutter_test/flutter_test.dart';
import 'package:lifequest/app/lifequest_app.dart';

void main() {
  testWidgets('renders main navigation labels', (WidgetTester tester) async {
    await tester.pumpWidget(const LifeQuestApp());
    await tester.pumpAndSettle();

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Quest Log'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
  });
}
