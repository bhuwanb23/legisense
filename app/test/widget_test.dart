import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legisense/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Splash shows brand and tagline', (tester) async {
    await tester.pumpWidget(const LegisenseApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Legisense'), findsOneWidget);
    expect(find.text('Your AI Legal Advisor'), findsOneWidget);

    // Flush splash redirect timer + transition so the binding stays clean.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
