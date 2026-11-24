import 'package:flutter/material.dart';

/// CSDB onboarding screening — PEP/PIP for people, high-risk for entities.
///
/// The server derives `IsPep`, `EddRequired` and `RiskLevel` from these
/// answers, so nothing here rates the applicant; it only collects and
/// serialises exactly what the screening API documents.
///
/// Screening is optional at the API, but every question is presented as
/// required here, which is what the API guide asks the frontend to do.

// ── Palette (matches the rest of the signup form) ────────────────────────────
const Color _kGold = Color(0xFFD4A855);
const Color _kBorder = Color(0xFFE8D7B8);
const Color _kLabel = Color(0xFF6B5D4F);
const Color _kHeading = Color(0xFF2C1810);

/// One labelled yes/no question backed by a JSON field name.
class ScreeningQuestion {
  final String key;
  final String label;
  const ScreeningQuestion(this.key, this.label);
}

/// The twelve positions the CSDB sheet lists for a PEP/PIP.
const List<ScreeningQuestion> kPepPositions = [
  ScreeningQuestion('PRESIDENT', 'President'),
  ScreeningQuestion('VICE_PRESIDENT', 'Vice President'),
  ScreeningQuestion('CABINET_MINISTER', 'Cabinet Minister'),
  ScreeningQuestion('SPEAKER', 'Speaker / Deputy Speaker'),
  ScreeningQuestion('MP', 'Member of Parliament'),
  ScreeningQuestion('SENIOR_GOVT_OFFICIAL', 'Senior government official'),
  ScreeningQuestion('JUDICIAL_OFFICER', 'Judicial officer'),
  ScreeningQuestion('KGOSI', 'Kgosi (traditional leader)'),
  ScreeningQuestion('SENIOR_EXEC_PRIVATE', 'Senior executive — private entity'),
  ScreeningQuestion('SENIOR_EXEC_PUBLIC', 'Senior executive — public body'),
  ScreeningQuestion('SENIOR_EXEC_PARTY', 'Senior executive — political party'),
  ScreeningQuestion(
      'SENIOR_EXEC_INTL_ORG', 'Senior executive — international organisation'),
];

/// The three relationship questions, in the order the sheet asks them.
const List<ScreeningQuestion> kPepRelationships = [
  ScreeningQuestion('SelfPep', 'Are you a Politically Exposed Person (PEP) '
      'or a Politically Influential Person (PIP)?'),
  ScreeningQuestion('FamilyPep',
      'Is an immediate family member a PEP/PIP?'),
  ScreeningQuestion('AssociatePep', 'Is a close associate a PEP/PIP?'),
];

/// Same three questions, worded for a corporate signatory.
const List<ScreeningQuestion> kSignatoryPepRelationships = [
  ScreeningQuestion('SelfPep', 'Is this signatory a PEP/PIP?'),
  ScreeningQuestion(
      'FamilyPep', "Is an immediate family member of this signatory a PEP/PIP?"),
  ScreeningQuestion(
      'AssociatePep', 'Is a close associate of this signatory a PEP/PIP?'),
];

/// The corporate high-risk rows.
const List<ScreeningQuestion> kEntityQuestions = [
  ScreeningQuestion('CorrespondentBank', 'Is the entity a correspondent bank?'),
  ScreeningQuestion('Trust', 'Is the entity a trust?'),
  ScreeningQuestion('NpoNgo', 'Is the entity an NPO or NGO?'),
  ScreeningQuestion(
      'WealthManagement', 'Does the entity provide wealth management?'),
  ScreeningQuestion('HighRiskJurisdictionFormed',
      'Was the entity formed or registered in a high-risk jurisdiction?'),
  ScreeningQuestion('HighRiskCountryOperating',
      'Does the entity operate in a high-risk country?'),
  ScreeningQuestion('ContractingPartnerController',
      'Is a contracting partner or controller high-risk?'),
  ScreeningQuestion('HighRiskNationalResident',
      'Is a high-risk national or resident involved?'),
  ScreeningQuestion('FiveOrMoreOwnershipLayers',
      'Does the ownership structure have five or more layers?'),
  ScreeningQuestion('DirectorOrCeoOwns10Plus',
      'Does a director, MD or CEO own 10% or more?'),
  ScreeningQuestion(
      'Shareholder10PlusIsPep', 'Is any shareholder of 10% or more a PEP?'),
];

/// High-risk industries. The API guide marks this key set as "TBD — confirm
/// with compliance"; these are the keys its worked example sends.
const List<ScreeningQuestion> kEntityIndustries = [
  ScreeningQuestion('CASINO_GAMING', 'Casino / gaming'),
  ScreeningQuestion('PRECIOUS_METALS_STONES', 'Precious metals & stones'),
  ScreeningQuestion('MONEY_SERVICES', 'Money services'),
  ScreeningQuestion('REAL_ESTATE', 'Real estate'),
  ScreeningQuestion('ARMS_DEALING', 'Arms dealing'),
  ScreeningQuestion('VIRTUAL_ASSETS', 'Virtual assets'),
  ScreeningQuestion('NPO_CHARITY', 'NPO / charity'),
];

// ── Models ───────────────────────────────────────────────────────────────────

/// Answers for `IndividualScreening` (applicant) or a signatory's `Screening`.
class IndividualScreening {
  /// Keyed by `SelfPep` / `FamilyPep` / `AssociatePep`; null = unanswered.
  final Map<String, bool?> relationships = {
    for (final q in kPepRelationships) q.key: null
  };

  /// Keys from [kPepPositions] the person holds.
  final Set<String> positions = {};

  final TextEditingController explanation = TextEditingController();

  bool get _anyRelationshipYes => relationships.values.any((v) => v == true);

  /// Any yes at all ⇒ the server will mark this applicant as a PEP.
  bool get flagged => _anyRelationshipYes || positions.isNotEmpty;

  bool get allAnswered => relationships.values.every((v) => v != null);

  /// null when the form is complete, otherwise the message to show.
  String? validate({String subject = 'the PEP declaration'}) {
    if (!allAnswered) return 'Please answer every question in $subject';
    if (flagged && explanation.text.trim().isEmpty) {
      return 'Please describe the position or relationship for $subject';
    }
    return null;
  }

  /// Every key is sent explicitly: the form requires an answer, so a false
  /// here means "answered No" — omitting it would read as unanswered.
  Map<String, dynamic> toJson() => {
        for (final q in kPepRelationships) q.key: relationships[q.key] ?? false,
        'Positions': {
          for (final p in kPepPositions) p.key: positions.contains(p.key)
        },
        'Explanation': explanation.text.trim(),
      };

  void dispose() => explanation.dispose();
}

/// Answers for `EntityScreening` (corporate applicants).
class EntityScreening {
  /// Keyed by the API field name; null = unanswered.
  final Map<String, bool?> answers = {
    for (final q in kEntityQuestions) q.key: null
  };

  /// Keys from [kEntityIndustries] that apply.
  final Set<String> industries = {};

  bool get allAnswered => answers.values.every((v) => v != null);

  /// Any yes ⇒ the server sets HIGH risk and requires enhanced due diligence.
  bool get flagged => answers.values.any((v) => v == true) ||
      industries.isNotEmpty;

  String? validate() {
    if (!allAnswered) {
      return 'Please answer every question in the entity risk declaration';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        for (final q in kEntityQuestions) q.key: answers[q.key] ?? false,
        'Industries': {
          for (final i in kEntityIndustries) i.key: industries.contains(i.key)
        },
      };
}

// ── Shared widgets ───────────────────────────────────────────────────────────

/// A Yes / No pair. Neither is selected until the user answers.
class ScreeningYesNo extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool> onChanged;

  const ScreeningYesNo({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _option('Yes', true),
        const SizedBox(width: 8),
        _option('No', false),
      ],
    );
  }

  Widget _option(String label, bool optionValue) {
    final selected = value == optionValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(optionValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _kGold : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _kGold : _kBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _kLabel,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// A question with its Yes / No answer underneath.
class ScreeningQuestionRow extends StatelessWidget {
  final String label;
  final bool? value;
  final ValueChanged<bool> onChanged;

  const ScreeningQuestionRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final unanswered = value == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Color(0xFF3D3028), fontSize: 12.5, height: 1.4),
                ),
              ),
              if (unanswered)
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 2),
                  child: Text('*',
                      style: TextStyle(color: _kGold, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ScreeningYesNo(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Multi-select chips for the position / industry lists.
class ScreeningChips extends StatelessWidget {
  final List<ScreeningQuestion> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const ScreeningChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // The longest labels ("Senior executive — international organisation")
    // are wider than a narrow phone, so each chip is capped to the available
    // width and its text wraps instead of overflowing the row.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxChipWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final isOn = selected.contains(o.key);
            return GestureDetector(
              onTap: () => onToggle(o.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                constraints: BoxConstraints(maxWidth: maxChipWidth),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isOn ? _kGold : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOn ? _kGold : _kBorder,
                    width: isOn ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOn ? Icons.check_circle : Icons.circle_outlined,
                      size: 14,
                      color: isOn ? Colors.white : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        o.label,
                        style: TextStyle(
                          color: isOn ? Colors.white : _kLabel,
                          fontSize: 11.5,
                          fontWeight:
                              isOn ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// White card wrapper matching the other signup sections.
class ScreeningCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const ScreeningCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: _kHeading,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 11, height: 1.45)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// Shown once anything is answered Yes, so the applicant knows why the extra
/// detail is being asked for.
class ScreeningFlagNotice extends StatelessWidget {
  final String message;
  const ScreeningFlagNotice({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kGold.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGold.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 15, color: _kGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFF6B5D4F), fontSize: 11, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

// ── Composed forms ───────────────────────────────────────────────────────────

/// The PEP/PIP sheet for a person — the applicant or a corporate signatory.
///
/// [onChanged] lets the hosting form rebuild; the model is mutated in place.
class IndividualScreeningForm extends StatelessWidget {
  final IndividualScreening model;
  final VoidCallback onChanged;
  final String title;
  final String subtitle;

  /// Question wording differs for the applicant vs a signatory.
  final List<ScreeningQuestion> questions;

  /// Signatory cards already sit inside a card, so they skip the wrapper.
  final bool boxed;

  const IndividualScreeningForm({
    super.key,
    required this.model,
    required this.onChanged,
    this.title = 'Politically Exposed Person (PEP) Declaration *',
    this.subtitle =
        'Required by the Financial Intelligence Act. Answer every question — '
        'answering Yes does not prevent your account from being opened, it '
        'only means compliance will review it.',
    this.questions = kPepRelationships,
    this.boxed = true,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ...questions.map((q) => ScreeningQuestionRow(
            label: q.label,
            value: model.relationships[q.key],
            onChanged: (v) {
              model.relationships[q.key] = v;
              onChanged();
            },
          )),
      const Text(
        'Which of these positions apply? Select all that apply, or leave '
        'blank if none.',
        style: TextStyle(color: Color(0xFF3D3028), fontSize: 12.5, height: 1.4),
      ),
      const SizedBox(height: 10),
      ScreeningChips(
        options: kPepPositions,
        selected: model.positions,
        onToggle: (key) {
          if (!model.positions.remove(key)) model.positions.add(key);
          onChanged();
        },
      ),
      if (model.flagged) ...[
        const SizedBox(height: 16),
        const ScreeningFlagNotice(
          message:
              'Because you answered Yes, please describe the position held or '
              'the relationship to the politically exposed person.',
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: TextField(
            controller: model.explanation,
            maxLines: 3,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'e.g. Spouse of a sitting Member of Parliament since 2024',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    ];

    if (!boxed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }
    return ScreeningCard(
      title: title,
      subtitle: subtitle,
      children: children,
    );
  }
}

/// The corporate high-risk sheet.
class EntityScreeningForm extends StatelessWidget {
  final EntityScreening model;
  final VoidCallback onChanged;

  const EntityScreeningForm({
    super.key,
    required this.model,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ScreeningCard(
      title: 'Entity Risk Declaration *',
      subtitle:
          'Required by the Financial Intelligence Act. Answer every question '
          'about the entity. A Yes does not prevent the account from being '
          'opened, it routes the application for enhanced due diligence.',
      children: [
        ...kEntityQuestions.map((q) => ScreeningQuestionRow(
              label: q.label,
              value: model.answers[q.key],
              onChanged: (v) {
                model.answers[q.key] = v;
                onChanged();
              },
            )),
        const Text(
          'Does the entity operate in any of these industries? Select all '
          'that apply, or leave blank if none.',
          style:
              TextStyle(color: Color(0xFF3D3028), fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 10),
        ScreeningChips(
          options: kEntityIndustries,
          selected: model.industries,
          onToggle: (key) {
            if (!model.industries.remove(key)) model.industries.add(key);
            onChanged();
          },
        ),
        if (model.flagged) ...[
          const SizedBox(height: 16),
          const ScreeningFlagNotice(
            message:
                'One or more answers flag this entity as higher risk. The '
                'application will be routed for enhanced due diligence '
                'approval before the account is activated.',
          ),
        ],
      ],
    );
  }
}
