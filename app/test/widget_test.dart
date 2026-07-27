import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legisense/main.dart';

void main() {
  testWidgets('App builds and shows intro or login shell', (tester) async {
    await tester.pumpWidget(const LegisenseApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
