import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legisense/data/analysis_mock.dart';
import 'package:legisense/main.dart';
import 'package:legisense/models/pending_upload.dart';
import 'package:legisense/pages/analysis/analysis_results_page.dart';
import 'package:legisense/pages/analysis/plain_language_page.dart';
import 'package:legisense/pages/auth/login_page.dart';
import 'package:legisense/pages/auth/otp_page.dart';
import 'package:legisense/pages/documents/documents_page.dart';
import 'package:legisense/pages/processing/processing_page.dart';
import 'package:legisense/pages/shell/main_shell.dart';
import 'package:legisense/pages/upload/upload_page.dart';

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

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('OTP page shows masked contact', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OtpPage(contact: 'demo@legisense.com', isNewUser: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('sent to'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('Main shell shows home dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({
      'user_display_name': 'Bhuwan',
      'user_email': 'bhuwan@test.com',
    });

    await tester.pumpWidget(
      const MaterialApp(home: MainShell()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome to Legisense'), findsOneWidget);
    expect(find.text('Quick stats'), findsOneWidget);
    expect(find.text('Select your next review'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsWidgets);
  });

  testWidgets('Upload page shows drop hero, methods, and Proceed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: UploadPage())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.text('Browse files'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Paste'), findsOneWidget);
    expect(find.text('URL'), findsOneWidget);
    expect(find.text('Proceed'), findsOneWidget);
    expect(
      find.textContaining('encrypted and auto-deleted'),
      findsOneWidget,
    );
  });

  testWidgets('Processing page shows analyzing UI', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProcessingPage(
          upload: PendingUpload(
            source: UploadSource.paste,
            title: 'Demo paste',
            detail: '120 chars',
            documentId: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Analyzing your document'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    // Dispose the widget tree to cancel pending timers
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
  });

  testWidgets('Analysis results shows risk score and actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisResultsPage(result: AnalysisMock.sample()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('RentAgreement_2024'), findsOneWidget);
    expect(find.text('Risk score'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Clauses'), findsWidgets);
  });

  testWidgets('Plain language page shows toggle and glossary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlainLanguagePage(result: AnalysisMock.sample()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Plain English'), findsOneWidget);
    expect(find.text('Grade 8'), findsOneWidget);
    expect(find.text('Clauses'), findsOneWidget);
  });

  testWidgets('Documents page shows header and search', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DocumentsPage())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Search your documents...'), findsOneWidget);
  });
}
