import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart'; // pubspec: file_picker: ^8.0.0
import '../../theme_provider.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// MODELS
/// ─────────────────────────────────────────────────────────────────────────

class Signatory {
  final surname = TextEditingController();
  final forenames = TextEditingController();
  final identification = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  String idType = 'National ID';
  String nationality = '';
  String role = 'Director';

  Map<String, dynamic> toJson() => {
    'Surname': surname.text.trim(),
    'Forenames': forenames.text.trim(),
    'Identification': identification.text.trim(),
    'IdType': idType,
    'Nationality': nationality,
    'Role': role,
    'Email': email.text.trim(),
    'Mobile': mobile.text.trim(),
  };

  void dispose() {
    surname.dispose();
    forenames.dispose();
    identification.dispose();
    email.dispose();
    mobile.dispose();
  }
}

class KycDocument {
  final String name; // e.g. "ID", "ProofOfAddress"
  final String fileName;
  final String contentType;
  final String base64Data;

  KycDocument({
    required this.name,
    required this.fileName,
    required this.contentType,
    required this.base64Data,
  });

  Map<String, dynamic> toJson() => {
    'Name': name,
    'ContentType': contentType,
    'FileName': fileName,
    'Data': base64Data,
  };
}

/// ─────────────────────────────────────────────────────────────────────────
/// SCREEN
/// ─────────────────────────────────────────────────────────────────────────

class KycUpdateScreen extends StatefulWidget {
  /// Optional: pass in whatever you already have from GetProfile so the
  /// form opens pre-filled. Keys are matched loosely — adjust the mapping
  /// in _prefillFromProfile() to your real GetProfile response shape.
  final Map<String, dynamic>? initialProfileData;

  /// Optional: lock the account type instead of letting the user pick it.
  final String? lockedAccountType;

  const KycUpdateScreen({
    super.key,
    this.initialProfileData,
    this.lockedAccountType,
  });

  @override
  State<KycUpdateScreen> createState() => _KycUpdateScreenState();
}

class _KycUpdateScreenState extends State<KycUpdateScreen> {
  static const gold = Color(0xFFD4A855);
  static const goldDark = Color(0xFFB8860B);

  int _currentStep = 0;
  bool _isSubmitting = false;

  // ── Account type / classification ──────────────────────────────────────
  String accountType = 'Individual'; // Individual | Corporate | Minor | Joint | Student
  String accountClass = 'Retail';
  String investorType = 'Retail';
  String signingMandateOption = 'Single Signatory';
  final brokerCode = TextEditingController();
  DateTime? agreementDate;

  // ── Personal details ────────────────────────────────────────────────────
  String title = 'Mr';
  final othernames = TextEditingController();
  final middleNames = TextEditingController();
  final surname = TextEditingController();
  String gender = 'Male';
  DateTime? dob;
  final birthPlace = TextEditingController();
  final nationalityController = TextEditingController(text: 'Motswana');
  final countryController = TextEditingController(text: 'Botswana');
  String maritalStatus = '';

  // ── Identification ──────────────────────────────────────────────────────
  final myIdentification = TextEditingController();
  String idType = 'National ID';
  DateTime? identityIssueDate;
  DateTime? idExpiryDate;

  // ── Contact & address ───────────────────────────────────────────────────
  final tel = TextEditingController();
  String mno = 'MASCOM';
  final mobileMoneyWallet = TextEditingController();
  final email = TextEditingController();
  final address1 = TextEditingController();
  final postalAddress = TextEditingController();
  final city = TextEditingController();
  final postCode = TextEditingController();
  final myRegion = TextEditingController();
  final myDistrict = TextEditingController();
  final village = TextEditingController();
  final town = TextEditingController();
  final residesIn = TextEditingController();
  final landmark = TextEditingController();

  // ── Employment & income ─────────────────────────────────────────────────
  final occupation = TextEditingController();
  final designation = TextEditingController();
  final employerName = TextEditingController();
  final employerAddress = TextEditingController();
  String employmentStatus = 'Employed';
  final natureOfBusiness = TextEditingController();
  String sourceOfIncome = 'Employment';
  final sourceOfIncomeOther = TextEditingController();
  final tin = TextEditingController();

  // ── Banking ──────────────────────────────────────────────────────────────
  final accountName = TextEditingController();
  final iban = TextEditingController();
  final bankDiv = TextEditingController();
  final bankBranch = TextEditingController();
  final branchCode = TextEditingController();
  final swiftCode = TextEditingController();
  final payee2 = TextEditingController();
  final preFunding = TextEditingController();

  // ── Corporate ────────────────────────────────────────────────────────────
  final companyName = TextEditingController();
  final principalOfficer = TextEditingController();
  final bRegNo = TextEditingController();
  DateTime? bRegDate;
  final placeOfIncorporation = TextEditingController();
  final bLicenseNo = TextEditingController();
  final bNature = TextEditingController();
  final botCds = TextEditingController();
  final bondsCdsNo = TextEditingController();

  // ── Signatories (Corporate / Joint) ────────────────────────────────────
  final List<Signatory> signatories = [];

  // ── Joint / Guardian (Minor) / Student ─────────────────────────────────
  final myJointName = TextEditingController();
  final guardianFullNames = TextEditingController();
  final guardianIdentification = TextEditingController();
  final guardianRelationship = TextEditingController();
  final studentProgramStudy = TextEditingController();
  final studentInstituteName = TextEditingController();
  final studentYearOfStudy = TextEditingController();
  final studentIdNumber = TextEditingController();

  // ── Documents ────────────────────────────────────────────────────────────
  final List<KycDocument> documents = [];

  final _formKeys = List.generate(10, (_) => GlobalKey<FormState>());

  @override
  void initState() {
    super.initState();
    // Prefill first, since it may set accountType from the profile's
    // "accountType" code (e.g. "I" -> Individual).
    if (widget.initialProfileData != null) {
      _prefillFromProfile(widget.initialProfileData!);
    }
    if (widget.lockedAccountType != null) {
      accountType = widget.lockedAccountType!;
    }
    if (_needsSignatories && signatories.isEmpty) {
      signatories.add(Signatory());
    }
  }

  /// Maps the real GetProfile response (Authentication/GetProfile) onto the
  /// KYC update form fields. Field names below match the JSON keys returned
  /// by that endpoint as of Aug 2026 — update here if the API shape changes.
  void _prefillFromProfile(Map<String, dynamic> p) {
    String s(String key) => (p[key] ?? '').toString().trim();

    // ── Account classification ─────────────────────────────────────────
    accountType = _mapAccountType(s('accountType'));
    if (s('accountClass').isNotEmpty) {
      accountClass =
          _matchOption(s('accountClass'), const ['Retail', 'Institutional'], fallback: accountClass);
    }
    brokerCode.text = s('brokerCode');

    // ── Personal details ─────────────────────────────────────────────────
    title = _matchOption(s('title'), const ['Mr', 'Mrs', 'Ms', 'Dr', 'Prof'], fallback: title);
    othernames.text = s('forenames');
    middleNames.text = s('middlename');
    surname.text = s('surname');
    if (s('gender').isNotEmpty) {
      gender = _matchOption(s('gender'), const ['Male', 'Female'], fallback: gender);
    }
    dob = _parseDate(s('dob'));
    birthPlace.text = s('placeOfBirth');
    if (s('nationality').isNotEmpty) nationalityController.text = s('nationality');
    if (s('country').isNotEmpty) countryController.text = s('country');
    if (s('maritalStatus').isNotEmpty) {
      maritalStatus = _matchOption(
          s('maritalStatus'), const ['Single', 'Married', 'Divorced', 'Widowed'],
          fallback: maritalStatus);
    }

    // ── Identification ──────────────────────────────────────────────────
    myIdentification.text = s('idNumber');
    if (s('idType').isNotEmpty) {
      idType = _matchOption(
          s('idType'), const ['National ID', 'Passport', "Driver's License"],
          fallback: idType);
    }
    identityIssueDate = _parseDate(s('idIssueDate'));
    idExpiryDate = _parseDate(s('idExpiryDate'));

    // ── Contact & address ────────────────────────────────────────────────
    tel.text = s('phoneNumber');
    if (s('mobileMoneyProvider').isNotEmpty) {
      mno = _matchOption(s('mobileMoneyProvider'), const ['MASCOM', 'ORANGE', 'BTC SMART'],
          fallback: mno);
    }
    mobileMoneyWallet.text = s('mobileMoneyNumber').isNotEmpty ? s('mobileMoneyNumber') : s('phoneNumber');
    email.text = s('email');
    // GetProfile returns four free-text address lines (address1..address4);
    // the KYC form has different buckets, so this mapping is best-effort —
    // adjust if your address1..4 mean something more specific.
    address1.text = s('address1');
    postalAddress.text = s('address2');
    town.text = s('address3');
    landmark.text = s('address4');
    city.text = s('city');
    postCode.text = s('postCode');
    residesIn.text = s('residentStatus').isNotEmpty ? s('residentStatus') : s('resident');

    // ── Employment & income ─────────────────────────────────────────────
    occupation.text = s('occupation');
    if (s('employmentStatus').isNotEmpty) {
      employmentStatus = _matchOption(
          s('employmentStatus'),
          const ['Employed', 'Self-Employed', 'Unemployed', 'Retired', 'Student'],
          fallback: employmentStatus);
    }
    employerName.text = s('employerName');
    employerAddress.text = s('employerAddress');
    natureOfBusiness.text = s('industry');
    if (s('sourceOfIncome').isNotEmpty) {
      sourceOfIncome = _matchOption(
          s('sourceOfIncome'),
          const ['Employment', 'Business', 'Investments', 'Inheritance', 'Other'],
          fallback: sourceOfIncome);
    }
    tin.text = s('tin');

    // ── Banking ──────────────────────────────────────────────────────────
    // GetProfile splits dividend vs cash banking details; UpdateAccount only
    // has one set of bank fields, so dividend banking wins here since that's
    // usually the account of record. Swap to cashBank/cashBranch if that's
    // the one you want prefilled instead.
    iban.text = s('iban');
    bankDiv.text = s('dividendBank');
    bankBranch.text = s('dividendBranch');

    // ── Reference only (not part of the UpdateAccount payload, but handy
    // context if you want to show it read-only somewhere) ────────────────
    botCds.text = s('csdAccountNumber').isNotEmpty ? s('csdAccountNumber') : s('cdsNumber');
  }

  String _mapAccountType(String raw) {
    switch (raw.toUpperCase()) {
      case 'I':
      case 'INDIVIDUAL':
        return 'Individual';
      case 'C':
      case 'CORPORATE':
        return 'Corporate';
      case 'M':
      case 'MINOR':
        return 'Minor';
      case 'J':
      case 'JOINT':
        return 'Joint';
      case 'S':
      case 'STUDENT':
        return 'Student';
      default:
        return 'Individual';
    }
  }

  /// Case/punctuation-insensitive match against a fixed option list, so
  /// values like "Mr." or "National Id" or "EMPLOYED" from the API line up
  /// with the form's exact dropdown strings ("Mr", "National ID", "Employed").
  String _matchOption(String raw, List<String> options, {required String fallback}) {
    if (raw.isEmpty) return fallback;
    for (final o in options) {
      if (o.toLowerCase() == raw.toLowerCase()) return o;
    }
    final stripped = raw.replaceAll(RegExp(r'[.]+$'), '').trim();
    for (final o in options) {
      if (o.toLowerCase() == stripped.toLowerCase()) return o;
    }
    return fallback;
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    // Fallback for "dd-MMM-yyyy" style dates (e.g. dateCreated/lastLoginDate).
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = raw.split('-');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = months[parts[1]];
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in [
      brokerCode, othernames, middleNames, surname, birthPlace,
      nationalityController, countryController, myIdentification,
      tel, mobileMoneyWallet, email, address1, postalAddress, city, postCode,
      myRegion, myDistrict, village, town, residesIn, landmark, occupation,
      designation, employerName, employerAddress, natureOfBusiness,
      sourceOfIncomeOther, tin, accountName, iban, bankDiv, bankBranch,
      branchCode, swiftCode, payee2, preFunding, companyName, principalOfficer,
      bRegNo, placeOfIncorporation, bLicenseNo, bNature, botCds, bondsCdsNo,
      myJointName, guardianFullNames, guardianIdentification, guardianRelationship,
      studentProgramStudy, studentInstituteName, studentYearOfStudy, studentIdNumber,
    ]) {
      c.dispose();
    }
    for (final s in signatories) {
      s.dispose();
    }
    super.dispose();
  }

  bool get _needsCorporateSection => accountType == 'Corporate';
  bool get _needsSignatories => accountType == 'Corporate' || accountType == 'Joint';
  bool get _needsGuardian => accountType == 'Minor';
  bool get _needsStudent => accountType == 'Student';
  bool get _needsJointName => accountType == 'Joint';

  // ── Steps ────────────────────────────────────────────────────────────────

  List<Step> _buildSteps(bool isDark) {
    final steps = <Step>[
      Step(
        title: const Text('Account Type'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: _accountTypeStep(isDark),
      ),
      Step(
        title: const Text('Personal Details'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: _personalDetailsStep(isDark),
      ),
      Step(
        title: const Text('Identification'),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        content: _identificationStep(isDark),
      ),
      Step(
        title: const Text('Contact & Address'),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
        content: _contactStep(isDark),
      ),
      Step(
        title: const Text('Employment & Income'),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
        content: _employmentStep(isDark),
      ),
      Step(
        title: const Text('Banking Details'),
        isActive: _currentStep >= 5,
        state: _currentStep > 5 ? StepState.complete : StepState.indexed,
        content: _bankingStep(isDark),
      ),
    ];

    int idx = 6;
    if (_needsCorporateSection) {
      steps.add(Step(
        title: const Text('Corporate Details'),
        isActive: _currentStep >= idx,
        state: _currentStep > idx ? StepState.complete : StepState.indexed,
        content: _corporateStep(isDark),
      ));
      idx++;
    }
    if (_needsSignatories) {
      steps.add(Step(
        title: const Text('Signatories'),
        isActive: _currentStep >= idx,
        state: _currentStep > idx ? StepState.complete : StepState.indexed,
        content: _signatoriesStep(isDark),
      ));
      idx++;
    }
    if (_needsGuardian || _needsStudent || _needsJointName) {
      steps.add(Step(
        title: const Text('Additional Details'),
        isActive: _currentStep >= idx,
        state: _currentStep > idx ? StepState.complete : StepState.indexed,
        content: _additionalStep(isDark),
      ));
      idx++;
    }
    steps.add(Step(
      title: const Text('Documents'),
      isActive: _currentStep >= idx,
      state: _currentStep > idx ? StepState.complete : StepState.indexed,
      content: _documentsStep(isDark),
    ));
    idx++;
    steps.add(Step(
      title: const Text('Review & Submit'),
      isActive: _currentStep >= idx,
      state: StepState.indexed,
      content: _reviewStep(isDark),
    ));

    return steps;
  }

  // Step 0
  Widget _accountTypeStep(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _dropdown('Account Type', accountType,
          ['Individual', 'Corporate', 'Minor', 'Joint', 'Student'], isDark,
          enabled: widget.lockedAccountType == null, onChanged: (v) {
            setState(() {
              accountType = v!;
              if (_needsSignatories && signatories.isEmpty) signatories.add(Signatory());
            });
          }),
      _gap(),
      _textField('Broker Code', brokerCode, isDark),
      _gap(),
      _dropdown('Account Class', accountClass, ['Retail', 'Institutional'], isDark,
          onChanged: (v) => setState(() => accountClass = v!)),
      _gap(),
      _dropdown('Investor Type', investorType, ['Retail', 'Professional'], isDark,
          onChanged: (v) => setState(() => investorType = v!)),
      _gap(),
      _dropdown(
          'Signing Mandate',
          signingMandateOption,
          ['Single Signatory', 'Joint Signatories', 'Either to Sign'],
          isDark,
          onChanged: (v) => setState(() => signingMandateOption = v!)),
      _gap(),
      _dateField('Agreement Date', agreementDate, isDark,
          onPicked: (d) => setState(() => agreementDate = d)),
    ]);
  }

  // Step 1
  Widget _personalDetailsStep(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _dropdown('Title', title, ['Mr', 'Mrs', 'Ms', 'Dr', 'Prof'], isDark,
          onChanged: (v) => setState(() => title = v!)),
      _gap(),
      _textField('Other Names', othernames, isDark),
      _gap(),
      _textField('Middle Names', middleNames, isDark, required: false),
      _gap(),
      _textField('Surname', surname, isDark),
      _gap(),
      _dropdown('Gender', gender, ['Male', 'Female'], isDark,
          onChanged: (v) => setState(() => gender = v!)),
      _gap(),
      _dateField('Date of Birth', dob, isDark, onPicked: (d) => setState(() => dob = d)),
      _gap(),
      _textField('Birth Place', birthPlace, isDark, required: false),
      _gap(),
      _textField('Nationality', nationalityController, isDark),
      _gap(),
      _textField('Country', countryController, isDark),
      _gap(),
      _dropdown('Marital Status', maritalStatus.isEmpty ? 'Single' : maritalStatus,
          ['Single', 'Married', 'Divorced', 'Widowed'], isDark,
          onChanged: (v) => setState(() => maritalStatus = v!)),
    ]);
  }

  // Step 2
  Widget _identificationStep(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _textField('ID / Passport Number', myIdentification, isDark),
      _gap(),
      _dropdown('ID Type', idType, ['National ID', 'Passport', 'Driver\'s License'], isDark,
          onChanged: (v) => setState(() => idType = v!)),
      _gap(),
      _dateField('Identity Issue Date', identityIssueDate, isDark,
          onPicked: (d) => setState(() => identityIssueDate = d)),
      _gap(),
      _dateField('ID Expiry Date', idExpiryDate, isDark,
          onPicked: (d) => setState(() => idExpiryDate = d)),
    ]);
  }

  // Step 3
  Widget _contactStep(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _textField('Mobile Number', tel, isDark, keyboardType: TextInputType.phone),
      _gap(),
      _dropdown('Mobile Network', mno, ['MASCOM', 'ORANGE', 'BTC SMART'], isDark,
          onChanged: (v) => setState(() => mno = v!)),
      _gap(),
      _textField('Mobile Money Wallet', mobileMoneyWallet, isDark, required: false),
      _gap(),
      _textField('Email', email, isDark, keyboardType: TextInputType.emailAddress),
      _gap(),
      _textField('Address', address1, isDark, required: false),
      _gap(),
      _textField('Postal Address', postalAddress, isDark, required: false),
      _gap(),
      _textField('City', city, isDark),
      _gap(),
      _textField('Post Code', postCode, isDark, required: false),
      _gap(),
      _textField('Region', myRegion, isDark, required: false),
      _gap(),
      _textField('District', myDistrict, isDark, required: false),
      _gap(),
      _textField('Village', village, isDark, required: false),
      _gap(),
      _textField('Town', town, isDark, required: false),
      _gap(),
      _textField('Resides In', residesIn, isDark, required: false),
      _gap(),
      _textField('Landmark', landmark, isDark, required: false),
    ]);
  }

  // Step 4
  Widget _employmentStep(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _textField('Occupation', occupation, isDark, required: false),
      _gap(),
      _textField('Designation', designation, isDark, required: false),
      _gap(),
      _textField('Employer Name', employerName, isDark, required: false),
      _gap(),
      _textField('Employer Address', employerAddress, isDark, required: false),
      _gap(),
      _dropdown(
          'Employment Status',
          employmentStatus,
          ['Employed', 'Self-Employed', 'Unemployed', 'Retired', 'Student'],
          isDark,
          onChanged: (v) => setState(() => employmentStatus = v!)),
      _gap(),
      _textField('Nature of Business', natureOfBusiness, isDark, required: false),
      _gap(),
      _dropdown(
          'Source of Income',
          sourceOfIncome,
          ['Employment', 'Business', 'Investments', 'Inheritance', 'Other'],
          isDark,
          onChanged: (v) => setState(() => sourceOfIncome = v!)),
      _gap(),
      _textField('Source of Income (Other)', sourceOfIncomeOther, isDark, required: false),
      _gap(),
      _textField('TIN', tin, isDark, required: false),
    ]);
  }

  // Step 5
  Widget _bankingStep(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _textField('Account Name', accountName, isDark, required: false),
      _gap(),
      _textField('IBAN', iban, isDark, required: false),
      _gap(),
      _textField('Bank / Division', bankDiv, isDark, required: false),
      _gap(),
      _textField('Bank Branch', bankBranch, isDark, required: false),
      _gap(),
      _textField('Branch Code', branchCode, isDark, required: false),
      _gap(),
      _textField('Swift Code', swiftCode, isDark, required: false),
      _gap(),
      _textField('Payee 2', payee2, isDark, required: false),
      _gap(),
      _textField('Pre-Funding', preFunding, isDark, required: false),
    ]);
  }

  // Corporate step
  Widget _corporateStep(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _textField('Company Name', companyName, isDark),
      _gap(),
      _textField('Principal Officer', principalOfficer, isDark, required: false),
      _gap(),
      _textField('Business Reg. No.', bRegNo, isDark),
      _gap(),
      _dateField('Business Reg. Date', bRegDate, isDark,
          onPicked: (d) => setState(() => bRegDate = d)),
      _gap(),
      _textField('Place of Incorporation', placeOfIncorporation, isDark, required: false),
      _gap(),
      _textField('Business License No.', bLicenseNo, isDark, required: false),
      _gap(),
      _textField('Nature of Business', bNature, isDark, required: false),
      _gap(),
      _textField('BOT CDS Number', botCds, isDark, required: false),
      _gap(),
      _textField('Bonds CDS No.', bondsCdsNo, isDark, required: false),
    ]);
  }

  // Signatories step
  Widget _signatoriesStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < signatories.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gold.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Signatory ${i + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87)),
                    if (signatories.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => setState(() {
                          signatories[i].dispose();
                          signatories.removeAt(i);
                        }),
                      ),
                  ],
                ),
                _textField('Surname', signatories[i].surname, isDark),
                _gap(),
                _textField('Forenames', signatories[i].forenames, isDark),
                _gap(),
                _textField('ID Number', signatories[i].identification, isDark),
                _gap(),
                _textField('Email', signatories[i].email, isDark,
                    keyboardType: TextInputType.emailAddress),
                _gap(),
                _textField('Mobile', signatories[i].mobile, isDark,
                    keyboardType: TextInputType.phone),
                _gap(),
                _dropdown('Role', signatories[i].role,
                    ['Director', 'Trustee', 'Partner', 'Authorized Signatory'], isDark,
                    onChanged: (v) => setState(() => signatories[i].role = v!)),
              ],
            ),
          ),
        ],
        OutlinedButton.icon(
          onPressed: () => setState(() => signatories.add(Signatory())),
          icon: const Icon(Icons.add, color: gold),
          label: const Text('Add Signatory', style: TextStyle(color: gold)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: gold)),
        ),
      ],
    );
  }

  // Additional (guardian / student / joint) step
  Widget _additionalStep(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_needsJointName) ...[
        _textField('Joint Account Name', myJointName, isDark),
      ],
      if (_needsGuardian) ...[
        _textField('Guardian Full Names', guardianFullNames, isDark),
        _gap(),
        _textField('Guardian ID Number', guardianIdentification, isDark),
        _gap(),
        _textField('Guardian Relationship', guardianRelationship, isDark),
      ],
      if (_needsStudent) ...[
        _textField('Program of Study', studentProgramStudy, isDark, required: false),
        _gap(),
        _textField('Institute Name', studentInstituteName, isDark, required: false),
        _gap(),
        _textField('Year of Study', studentYearOfStudy, isDark, required: false),
        _gap(),
        _textField('Student ID Number', studentIdNumber, isDark, required: false),
      ],
    ]);
  }

  // Documents step
  Widget _documentsStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final doc in documents)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file, color: gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87)),
                      Text(doc.fileName,
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => setState(() => documents.remove(doc)),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: _pickDocument,
          icon: const Icon(Icons.upload_file, color: gold),
          label: const Text('Add Document', style: TextStyle(color: gold)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: gold)),
        ),
      ],
    );
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;

    final docName = await _promptDocumentName();
    if (docName == null) return;

    final ext = (file.extension ?? '').toLowerCase();
    final contentType = ext == 'pdf'
        ? 'application/pdf'
        : ext == 'png'
        ? 'image/png'
        : 'image/jpeg';

    setState(() {
      documents.add(KycDocument(
        name: docName,
        fileName: file.name,
        contentType: contentType,
        base64Data: base64Encode(file.bytes!),
      ));
    });
  }

  Future<String?> _promptDocumentName() async {
    String selected = 'ID';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Type'),
        content: DropdownButtonFormField<String>(
          initialValue: selected,
          items: const [
            DropdownMenuItem(value: 'ID', child: Text('ID Document')),
            DropdownMenuItem(value: 'ProofOfAddress', child: Text('Proof of Address')),
            DropdownMenuItem(value: 'BankStatement', child: Text('Bank Statement')),
            DropdownMenuItem(value: 'BusinessRegistration', child: Text('Business Registration')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (v) => selected = v ?? 'ID',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Add')),
        ],
      ),
    );
  }

  // Review step
  Widget _reviewStep(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Please confirm the details below before submitting.',
            style: TextStyle(color: textColor)),
        const SizedBox(height: 16),
        _reviewRow('Account Type', accountType, textColor),
        _reviewRow('Name', '$title $othernames.text ${surname.text}'.trim(), textColor),
        _reviewRow('ID Number', myIdentification.text, textColor),
        _reviewRow('Email', email.text, textColor),
        _reviewRow('Mobile', tel.text, textColor),
        if (_needsCorporateSection) _reviewRow('Company', companyName.text, textColor),
        _reviewRow('Documents attached', '${documents.length}', textColor),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('SUBMIT KYC UPDATE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value, Color textColor) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textColor.withOpacity(0.6))),
        Flexible(
          child: Text(value.isEmpty ? '—' : value,
              textAlign: TextAlign.end,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  // ── Submit ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _buildPayload() {
    String fmtDate(DateTime? d) =>
        d == null ? '' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return {
      'Othernames': othernames.text.trim(),
      'MiddleNames': middleNames.text.trim(),
      'Surname': surname.text.trim(),
      'Title': title,
      'Gender': gender,
      'DOB': fmtDate(dob),
      'BirthPlace': birthPlace.text.trim(),
      'myIdentification': myIdentification.text.trim(),
      'idtype': idType,
      'IdentityIssueDate': fmtDate(identityIssueDate),
      'IDExpiryDate': fmtDate(idExpiryDate),
      'Nationality': nationalityController.text.trim(),
      'Country': countryController.text.trim(),
      'MaritalStatus': maritalStatus,
      'AccountType': accountType,
      'accountClass': accountClass,
      'InvestorType': investorType,
      'SigningMandateOption': signingMandateOption,
      'BrokerCode': brokerCode.text.trim(),
      'CreatedBy': 'WEB',
      'AgreementDate': fmtDate(agreementDate),
      'Tel': tel.text.trim(),
      'MNO': mno,
      'MobileMoneyWallet': mobileMoneyWallet.text.trim(),
      'Email': email.text.trim(),
      'Address1': address1.text.trim(),
      'PostalAddress': postalAddress.text.trim(),
      'City': city.text.trim(),
      'PostCode': postCode.text.trim(),
      'myRegion': myRegion.text.trim(),
      'myDistrict': myDistrict.text.trim(),
      'Village': village.text.trim(),
      'Town': town.text.trim(),
      'ResidesIn': residesIn.text.trim(),
      'Landmark': landmark.text.trim(),
      'Occupation': occupation.text.trim(),
      'Designation': designation.text.trim(),
      'EmployerName': employerName.text.trim(),
      'EmployerAddress': employerAddress.text.trim(),
      'EmploymentStatus': employmentStatus,
      'NatureOfBusiness': natureOfBusiness.text.trim(),
      'sourceofIncome': sourceOfIncome,
      'SourceOfIncomeOther': sourceOfIncomeOther.text.trim(),
      'TIN': tin.text.trim(),
      'AccountName': accountName.text.trim(),
      'IBAN': iban.text.trim(),
      'BankDiv': bankDiv.text.trim(),
      'BankBranch': bankBranch.text.trim(),
      'branchcode': branchCode.text.trim(),
      'SwiftCode': swiftCode.text.trim(),
      'Payee2': payee2.text.trim(),
      'PreFunding': preFunding.text.trim(),
      'CompanyName': companyName.text.trim(),
      'PrincipalOfficer': principalOfficer.text.trim(),
      'BRegNo': bRegNo.text.trim(),
      'BRegDate': fmtDate(bRegDate),
      'PlaceOfIncorporation': placeOfIncorporation.text.trim(),
      'BLicenseNo': bLicenseNo.text.trim(),
      'BNature': bNature.text.trim(),
      'BOTCDS': botCds.text.trim(),
      'BondsCDSNo': bondsCdsNo.text.trim(),
      'Signatories': _needsSignatories ? signatories.map((s) => s.toJson()).toList() : [],
      'myJointName': myJointName.text.trim(),
      'GuardianFullNames': guardianFullNames.text.trim(),
      'GuardianIdentification': guardianIdentification.text.trim(),
      'GuardianRelationship': guardianRelationship.text.trim(),
      'StudentProgramStudy': studentProgramStudy.text.trim(),
      'StudentInstituteName': studentInstituteName.text.trim(),
      'StudentYearofStudy': studentYearOfStudy.text.trim(),
      'StudentIDNumber': studentIdNumber.text.trim(),
      'Documents': documents.map((d) => d.toJson()).toList(),
    };
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        _showSnackBar('No authentication token found. Please login again.', Colors.red);
        setState(() => _isSubmitting = false);
        return;
      }

      final payload = _buildPayload();

      final response = await http
          .post(
        Uri.parse('https://zamagm.escrowagm.com/MainAPI/Home/UpdateAccount'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseCode'] == 200) {
          _showSnackBar(data['responseMessage'] ?? 'KYC updated successfully', Colors.green);
          if (mounted) Navigator.pop(context, true);
        } else {
          _showSnackBar(data['responseMessage'] ?? 'Failed to update KYC', Colors.red);
        }
      } else {
        _showSnackBar('Failed to update KYC (${response.statusCode}). Please try again.',
            Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  // ── Reusable field widgets ─────────────────────────────────────────────

  Widget _gap() => const SizedBox(height: 14);

  Widget _textField(
      String label,
      TextEditingController controller,
      bool isDark, {
        bool required = true,
        TextInputType keyboardType = TextInputType.text,
        TextEditingController? controllerOverride,
        void Function(String)? onChangedRaw,
      }) {
    final ctrl = controllerOverride ?? controller;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: onChangedRaw,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        filled: true,
        fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }

  Widget _dropdown(
      String label,
      String value,
      List<String> options,
      bool isDark, {
        required void Function(String?) onChanged,
        bool enabled = true,
      }) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : options.first,
      onChanged: enabled ? onChanged : null,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        filled: true,
        fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
    );
  }

  Widget _dateField(String label, DateTime? value, bool isDark,
      {required void Function(DateTime) onPicked}) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(1990, 1, 1),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          filled: true,
          fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          suffixIcon: const Icon(Icons.calendar_today, color: gold, size: 18),
        ),
        child: Text(
          value == null
              ? 'Select date'
              : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final steps = _buildSteps(isDark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          'Update KYC',
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: gold),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          steps: steps,
          onStepContinue: () {
            if (_currentStep < steps.length - 1) {
              setState(() => _currentStep += 1);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep -= 1);
          },
          onStepTapped: (i) => setState(() => _currentStep = i),
          controlsBuilder: (context, details) {
            final isLast = _currentStep == steps.length - 1;
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (!isLast)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('NEXT', style: TextStyle(color: Colors.white)),
                    ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text('BACK',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}