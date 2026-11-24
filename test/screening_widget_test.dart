import 'package:bse/screens/auth/signup/screening.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('answering Yes reveals the explanation field', (tester) async {
    final model = IndividualScreening();
    await tester.pumpWidget(_host(
      StatefulBuilder(
        builder: (context, setState) => IndividualScreeningForm(
          model: model,
          onChanged: () => setState(() {}),
        ),
      ),
    ));

    // No explanation prompt while nothing is flagged.
    expect(find.byType(TextField), findsNothing);

    // Tap "Yes" on the first question.
    await tester.tap(find.text('Yes').first);
    await tester.pumpAndSettle();

    expect(model.relationships['SelfPep'], isTrue);
    expect(model.flagged, isTrue);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.textContaining('please describe the position held'),
      findsOneWidget,
    );
  });

  testWidgets('selecting a position alone reveals the explanation field',
      (tester) async {
    final model = IndividualScreening();
    await tester.pumpWidget(_host(
      StatefulBuilder(
        builder: (context, setState) => IndividualScreeningForm(
          model: model,
          onChanged: () => setState(() {}),
        ),
      ),
    ));

    await tester.tap(find.text('Member of Parliament'));
    await tester.pumpAndSettle();

    expect(model.positions, contains('MP'));
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('every documented position is offered', (tester) async {
    await tester.pumpWidget(_host(IndividualScreeningForm(
      model: IndividualScreening(),
      onChanged: () {},
    )));

    for (final p in kPepPositions) {
      expect(find.text(p.label), findsOneWidget, reason: 'missing ${p.key}');
    }
  });

  testWidgets('entity sheet offers every question and industry',
      (tester) async {
    await tester.pumpWidget(_host(EntityScreeningForm(
      model: EntityScreening(),
      onChanged: () {},
    )));

    for (final q in kEntityQuestions) {
      expect(find.text(q.label), findsOneWidget, reason: 'missing ${q.key}');
    }
    for (final i in kEntityIndustries) {
      expect(find.text(i.label), findsOneWidget, reason: 'missing ${i.key}');
    }
  });

  testWidgets('signatory wording is used when questions are overridden',
      (tester) async {
    await tester.pumpWidget(_host(IndividualScreeningForm(
      model: IndividualScreening(),
      onChanged: () {},
      questions: kSignatoryPepRelationships,
      boxed: false,
    )));

    expect(find.text('Is this signatory a PEP/PIP?'), findsOneWidget);
  });
}
