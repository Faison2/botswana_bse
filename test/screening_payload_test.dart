// Pins the serialised shape to the ACCOUNT_SCREENING_API guide.
import 'dart:convert';

import 'package:bse/screens/auth/signup/screening.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IndividualScreening matches the documented JSON shape', () {
    final s = IndividualScreening();
    for (final q in kPepRelationships) {
      s.relationships[q.key] = false;
    }

    final encoded = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
    expect(encoded.keys.toSet(), {
      'SelfPep',
      'FamilyPep',
      'AssociatePep',
      'Positions',
      'Explanation',
    });

    final positions = encoded['Positions'] as Map<String, dynamic>;
    expect(positions.keys.toSet(), {
      'PRESIDENT',
      'VICE_PRESIDENT',
      'CABINET_MINISTER',
      'SPEAKER',
      'MP',
      'SENIOR_GOVT_OFFICIAL',
      'JUDICIAL_OFFICER',
      'KGOSI',
      'SENIOR_EXEC_PRIVATE',
      'SENIOR_EXEC_PUBLIC',
      'SENIOR_EXEC_PARTY',
      'SENIOR_EXEC_INTL_ORG',
    });
  });

  test('EntityScreening matches the documented JSON shape', () {
    final e = EntityScreening();
    for (final q in kEntityQuestions) {
      e.answers[q.key] = false;
    }

    final encoded = jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>;
    expect(encoded.keys.toSet(), {
      'CorrespondentBank',
      'Trust',
      'NpoNgo',
      'WealthManagement',
      'Industries',
      'HighRiskJurisdictionFormed',
      'HighRiskCountryOperating',
      'ContractingPartnerController',
      'HighRiskNationalResident',
      'FiveOrMoreOwnershipLayers',
      'DirectorOrCeoOwns10Plus',
      'Shareholder10PlusIsPep',
    });

    final industries = encoded['Industries'] as Map<String, dynamic>;
    expect(industries.keys.toSet(), {
      'CASINO_GAMING',
      'PRECIOUS_METALS_STONES',
      'MONEY_SERVICES',
      'REAL_ESTATE',
      'ARMS_DEALING',
      'VIRTUAL_ASSETS',
      'NPO_CHARITY',
    });
  });

  test('the flagged example from the guide round-trips', () {
    final s = IndividualScreening();
    s.relationships['SelfPep'] = true;
    s.relationships['FamilyPep'] = false;
    s.relationships['AssociatePep'] = false;
    s.positions.addAll({'CABINET_MINISTER', 'MP'});
    s.explanation.text = 'Holder is a sitting Cabinet Minister';

    final json = s.toJson();
    expect(json['SelfPep'], isTrue);
    expect(json['FamilyPep'], isFalse);
    expect(json['AssociatePep'], isFalse);
    expect((json['Positions'] as Map)['CABINET_MINISTER'], isTrue);
    expect((json['Positions'] as Map)['MP'], isTrue);
    expect((json['Positions'] as Map)['PRESIDENT'], isFalse);
    expect(json['Explanation'], 'Holder is a sitting Cabinet Minister');
  });
}
