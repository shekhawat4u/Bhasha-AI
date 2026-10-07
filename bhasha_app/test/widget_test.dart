import 'package:flutter_test/flutter_test.dart';
import 'package:bhasha_app/main.dart';

void main() {
  testWidgets('Bhasha AI App Render and Navigation Test', (WidgetTester tester) async {
    await tester.pumpWidget(const BhashaApp());
    expect(find.text('Bhasha AI'), findsWidgets);

    // Advance through splash screen timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Verify Home screen is reached
    expect(find.text('Bhasha AI'), findsWidgets);
    expect(find.text('Type text in any language...'), findsOneWidget);
    expect(find.text('Translate text or speech'), findsOneWidget);
  });
}
