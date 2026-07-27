import 'package:flutter_test/flutter_test.dart';

import 'package:legisense/main.dart';

void main() {
  testWidgets('shows Legisense home', (tester) async {
    await tester.pumpWidget(const LegisenseApp());
    expect(find.text('Legisense'), findsOneWidget);
  });
}
