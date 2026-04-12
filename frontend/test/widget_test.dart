import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app/app.dart';

void main() {
  testWidgets('login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LinguaVerseApp());
    await tester.pumpAndSettle();

    expect(find.text('LinguaVerse'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
