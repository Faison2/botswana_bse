// The position/industry labels are long, so these guard against overflow on
// the narrowest phones we support.
import 'package:bse/screens/auth/signup/screening.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  // 320 = iPhone SE (1st gen) portrait, the narrowest layout in play.
  for (final width in <double>[320, 360, 393]) {
    testWidgets('individual sheet lays out at ${width}pt wide',
        (tester) async {
      final model = IndividualScreening();
      await _pumpAt(
        tester,
        Size(width, 2400),
        StatefulBuilder(
          builder: (c, setState) => IndividualScreeningForm(
            model: model,
            onChanged: () => setState(() {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      // Flagged state adds the notice and the explanation box.
      await tester.tap(find.text('Yes').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cabinet Minister'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
      expect(model.positions, contains('CABINET_MINISTER'));
    });

    testWidgets('entity sheet lays out at ${width}pt wide', (tester) async {
      final model = EntityScreening();
      await _pumpAt(
        tester,
        Size(width, 3600),
        StatefulBuilder(
          builder: (c, setState) => EntityScreeningForm(
            model: model,
            onChanged: () => setState(() {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Arms dealing'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(model.industries, contains('ARMS_DEALING'));
    });
  }
}
