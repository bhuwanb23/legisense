import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legisense/main.dart';
import 'package:legisense/pages/auth/login_page.dart';
import 'package:legisense/pages/auth/otp_page.dart';

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

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('Login page builds with primary CTA', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('OTP page shows masked contact', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OtpPage(contact: 'demo@legisense.com', isNewUser: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('OTP sent to'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });
}
