import 'package:bse/screens/auth/signup/screening.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IndividualScreening', () {
    test('starts unanswered and blocks submission', () {
      final s = IndividualScreening();
      expect(s.allAnswered, isFalse);
      expect(s.flagged, isFalse);
      expect(s.validate(), isNotNull);
    });

    test('a clean sheet serialises every key as false', () {
      final s = IndividualScreening();
      for (final q in kPepRelationships) {
        s.relationships[q.key] = false;
      }
      expect(s.validate(), isNull);

      final json = s.toJson();
      expect(json['SelfPep'], isFalse);
      expect(json['FamilyPep'], isFalse);
      expect(json['AssociatePep'], isFalse);
      expect(json['Explanation'], '');

      final positions = json['Positions'] as Map<String, dynamic>;
      expect(positions.length, 12);
      expect(positions.values.every((v) => v == false), isTrue);
      // Keys must match the API guide exactly.
      expect(positions.containsKey('SENIOR_EXEC_INTL_ORG'), isTrue);
      expect(positions.containsKey('KGOSI'), isTrue);
    });

    test('a Yes answer demands an explanation', () {
      final s = IndividualScreening();
      for (final q in kPepRelationships) {
        s.relationships[q.key] = false;
      }
      s.relationships['SelfPep'] = true;

      expect(s.flagged, isTrue);
      expect(s.validate(), isNotNull);

      s.explanation.text = 'Holder is a sitting Cabinet Minister';
      expect(s.validate(), isNull);
      expect(s.toJson()['SelfPep'], isTrue);
      expect(s.toJson()['Explanation'], 'Holder is a sitting Cabinet Minister');
    });

    test('a selected position alone flags the sheet', () {
      final s = IndividualScreening();
      for (final q in kPepRelationships) {
        s.relationships[q.key] = false;
      }
      s.positions.add('MP');

      expect(s.flagged, isTrue);
      expect(s.validate(), isNotNull, reason: 'explanation still required');

      s.explanation.text = 'Member of Parliament since 2024';
      expect(s.validate(), isNull);

      final positions = s.toJson()['Positions'] as Map<String, dynamic>;
      expect(positions['MP'], isTrue);
      expect(positions['PRESIDENT'], isFalse);
    });

    test('the validation message names the subject', () {
      final s = IndividualScreening();
      expect(s.validate(subject: "signatory 2's PEP declaration"),
          contains("signatory 2's PEP declaration"));
    });
  });

  group('EntityScreening', () {
    test('starts unanswered and blocks submission', () {
      final e = EntityScreening();
      expect(e.allAnswered, isFalse);
      expect(e.validate(), isNotNull);
    });

    test('a clean sheet serialises all documented keys as false', () {
      final e = EntityScreening();
      for (final q in kEntityQuestions) {
        e.answers[q.key] = false;
      }
      expect(e.validate(), isNull);
      expect(e.flagged, isFalse);

      final json = e.toJson();
      for (final key in const [
        'CorrespondentBank',
        'Trust',
        'NpoNgo',
        'WealthManagement',
        'HighRiskJurisdictionFormed',
        'HighRiskCountryOperating',
        'ContractingPartnerController',
        'HighRiskNationalResident',
        'FiveOrMoreOwnershipLayers',
        'DirectorOrCeoOwns10Plus',
        'Shareholder10PlusIsPep',
      ]) {
        expect(json[key], isFalse, reason: '$key must be present');
      }
      expect((json['Industries'] as Map).length, 7);
    });

    test('an industry or a Yes flags the entity but never blocks submission',
        () {
      final e = EntityScreening();
      for (final q in kEntityQuestions) {
        e.answers[q.key] = false;
      }
      e.industries.add('ARMS_DEALING');
      expect(e.flagged, isTrue);
      expect(e.validate(), isNull);

      final industries = e.toJson()['Industries'] as Map<String, dynamic>;
      expect(industries['ARMS_DEALING'], isTrue);
      expect(industries['REAL_ESTATE'], isFalse);
    });
  });
}
