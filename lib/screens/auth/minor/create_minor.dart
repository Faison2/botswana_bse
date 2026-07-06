import 'dart:convert';
import 'package:bse/contants/constants.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme_provider.dart';

/// Screen for creating a Minor trading account.
/// Posts to `$baseUrl/Home/AccountOpening` with AccountType = "M".
/// Required documents: Birth Certificate, Guardian ID, Proof of Address.
class CreateMinorAccountScreen extends StatefulWidget {
  const CreateMinorAccountScreen({super.key});

  @override
  State<CreateMinorAccountScreen> createState() =>
      _CreateMinorAccountScreenState();
}

class _CreateMinorAccountScreenState extends State<CreateMinorAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // ---- Text controllers ----
  final _otherNamesCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _mnoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _residesInCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postCodeCtrl = TextEditingController();
  final _birthPlaceCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _townCtrl = TextEditingController();
  final _brokerCodeCtrl = TextEditingController();

  // Guardian details (kept separate from the minor's own details)
  final _guardianNameCtrl = TextEditingController();
  final _guardianIdNumberCtrl = TextEditingController();
  final _guardianRelationshipCtrl = TextEditingController();
  final _guardianTelCtrl = TextEditingController();

  // ---- Dropdown / picker values ----
  String? _title;
  String? _gender;
  String? _idType;
  String? _maritalStatus = 'Single';
  String? _investorType = 'Retail';
  String? _signingMandateOption = 'Single Signatory';
  String? _accountClass = 'Retail';

  DateTime? _dob;
  DateTime? _identityIssueDate;
  DateTime? _idExpiryDate;
  final DateTime _agreementDate = DateTime.now();

  final _nationalityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  // ---- Document uploads ----
  PlatformFile? _birthCertificateFile;
  PlatformFile? _guardianIdFile;
  PlatformFile? _proofOfAddressFile;

  final List<String> _titles = ['Master', 'Miss', 'Mr', 'Mrs', 'Ms', 'Dr'];
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _idTypes = ['National ID', 'Birth Certificate', 'Passport'];
  final List<String> _investorTypes = ['Retail', 'Institutional'];
  final List<String> _signingOptions = ['Single Signatory', 'Joint Signatories'];
  final List<String> _accountClasses = ['Retail', 'Institutional'];

  static const Color _gold = Color(0xFFD4A855);
  static const Color _goldDark = Color(0xFFB8860B);
  static const Color _ink = Color(0xFF2C1810);
  static const Color _muted = Color(0xFF6B5D4F);

  @override
  void dispose() {
    _otherNamesCtrl.dispose();
    _surnameCtrl.dispose();
    _idNumberCtrl.dispose();
    _telCtrl.dispose();
    _mnoCtrl.dispose();
    _emailCtrl.dispose();
    _residesInCtrl.dispose();
    _cityCtrl.dispose();
    _postCodeCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _villageCtrl.dispose();
    _townCtrl.dispose();
    _brokerCodeCtrl.dispose();
    _guardianNameCtrl.dispose();
    _guardianIdNumberCtrl.dispose();
    _guardianRelationshipCtrl.dispose();
    _guardianTelCtrl.dispose();
    _nationalityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime? initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(2015, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _gold,
              onPrimary: Colors.white,
              onSurface: _ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDocument({
    required String label,
    required ValueChanged<PlatformFile?> onPicked,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      onPicked(result.files.first);
      setState(() {});
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dob == null) {
      _showMessage('Please select the minor\'s date of birth');
      return;
    }
    if (_birthCertificateFile == null ||
        _guardianIdFile == null ||
        _proofOfAddressFile == null) {
      _showMessage('Please upload Birth Certificate, Guardian ID and Proof of Address');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final documents = [
        {
          'Name': 'Birth Certificate',
          'ContentType': _contentTypeFor(_birthCertificateFile!.name),
          'FileName': _birthCertificateFile!.name,
          'Data': base64Encode(_birthCertificateFile!.bytes!),
        },
        {
          'Name': 'Guardian ID',
          'ContentType': _contentTypeFor(_guardianIdFile!.name),
          'FileName': _guardianIdFile!.name,
          'Data': base64Encode(_guardianIdFile!.bytes!),
        },
        {
          'Name': 'Proof of Address',
          'ContentType': _contentTypeFor(_proofOfAddressFile!.name),
          'FileName': _proofOfAddressFile!.name,
          'Data': base64Encode(_proofOfAddressFile!.bytes!),
        },
      ];

      final payload = {
        'Othernames': _otherNamesCtrl.text.trim(),
        'Surname': _surnameCtrl.text.trim(),
        'AccountType': 'M',
        'accountClass': _accountClass,
        'idtype': _idType,
        'myIdentification': _idNumberCtrl.text.trim(),
        'Title': _title,
        'DOB': _formatDate(_dob),
        'Gender': _gender,
        'Nationality': _nationalityCtrl.text.trim(),
        'Country': _countryCtrl.text.trim(),
        'sourceofIncome': 'N/A',
        'ResidesIn': _residesInCtrl.text.trim(),
        'Tel': _telCtrl.text.trim(),
        'MNO': _mnoCtrl.text.trim(),
        'Email': _emailCtrl.text.trim(),
        'City': _cityCtrl.text.trim(),
        'PostCode': _postCodeCtrl.text.trim(),
        'BirthPlace': _birthPlaceCtrl.text.trim(),
        'Village': _villageCtrl.text.trim(),
        'Town': _townCtrl.text.trim(),
        'NatureOfBusiness': 'N/A',
        'EmploymentStatus': 'N/A',
        'MaritalStatus': _maritalStatus,
        'InvestorType': _investorType,
        'Designation': 'N/A',
        'EmployerName': 'N/A',
        'EmployerAddress': 'N/A',
        'Occupation': 'N/A',
        'TIN': 'N/A',
        'IdentityIssueDate': _formatDate(_identityIssueDate),
        'IDExpiryDate': _formatDate(_idExpiryDate),
        'AgreementDate': _formatDate(_agreementDate),
        'SigningMandateOption': _signingMandateOption,
        'BrokerCode': _brokerCodeCtrl.text.trim(),
        'CreatedBy': 'WEB',
        // Guardian-specific details required to open a minor account.
        'GuardianName': _guardianNameCtrl.text.trim(),
        'GuardianIdNumber': _guardianIdNumberCtrl.text.trim(),
        'GuardianRelationship': _guardianRelationshipCtrl.text.trim(),
        'GuardianTel': _guardianTelCtrl.text.trim(),
        'Documents': documents,
      };

      final response = await http
          .post(
        Uri.parse('$baseUrl/Home/AccountOpening'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showResultDialog(
          success: true,
          message: 'Minor account application submitted successfully.',
        );
      } else {
        String errorMessage = 'Something went wrong. Please try again.';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['Message'] != null) {
            errorMessage = decoded['Message'].toString();
          }
        } catch (_) {}
        _showResultDialog(success: false, message: errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        success: false,
        message: 'Failed to submit application: $e',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _contentTypeFor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _gold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showResultDialog({required bool success, required String message}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final dialogBgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (success ? Colors.green : Colors.red).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_rounded : Icons.priority_high_rounded,
                color: success ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              success ? 'Success' : 'Submission Failed',
              style: TextStyle(color: textColor, fontSize: 17),
            ),
          ],
        ),
        content: Text(message, style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              if (success) Navigator.pop(context); // close screen
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: isDark ? Colors.amber : _gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF121212), Color(0xFF161616), Color(0xFF1A1A1A)],
    )
        : const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF8DC), Color(0xFFFFF4D6), Color(0xFFFFF9F0)],
    );

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white70 : _muted;
    final accentColor = isDark ? Colors.amber : _gold;
    final hintColor = isDark ? Colors.white54 : Colors.black38;
    final fieldFill = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFAF6EE);
    final fieldBorder = isDark ? Colors.white24 : const Color(0xFFE8D7B8);

    final inputDecorationTheme = InputDecoration(
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      labelStyle: TextStyle(color: mutedColor, fontSize: 13),
    );

    InputDecoration deco(String label) =>
        inputDecorationTheme.copyWith(labelText: label);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF8DC),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark: isDark, textColor: textColor),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _buildInfoBanner(isDark: isDark),
                      const SizedBox(height: 16),
                      _sectionCard(
                        cardColor: cardColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        accentColor: accentColor,
                        icon: Icons.child_care_rounded,
                        title: "Minor's Details",
                        subtitle: 'Personal and identification information',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _title,
                                  decoration: deco('Title'),
                                  dropdownColor: cardColor,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  items: _titles
                                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _title = v),
                                  validator: (v) => v == null ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _otherNamesCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('Other Names'),
                                  validator: _requiredValidator,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _surnameCtrl,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: deco('Surname'),
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _idType,
                                  decoration: deco('ID Type'),
                                  dropdownColor: cardColor,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  items: _idTypes
                                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _idType = v),
                                  validator: (v) => v == null ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _idNumberCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('ID / Birth Cert No.'),
                                  validator: _requiredValidator,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _gender,
                                  decoration: deco('Gender'),
                                  dropdownColor: cardColor,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  items: _genders
                                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _gender = v),
                                  validator: (v) => v == null ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dateField(
                                  label: 'Date of Birth',
                                  value: _dob,
                                  deco: deco('Date of Birth'),
                                  textColor: textColor,
                                  accentColor: accentColor,
                                  onTap: () => _pickDate(
                                    context: context,
                                    initial: _dob,
                                    onPicked: (d) => setState(() => _dob = d),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nationalityCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('Nationality'),
                                  validator: _requiredValidator,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _countryCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('Country'),
                                  validator: _requiredValidator,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _birthPlaceCtrl,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: deco('Birth Place'),
                            validator: _requiredValidator,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        cardColor: cardColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        accentColor: accentColor,
                        icon: Icons.home_rounded,
                        title: 'Contact & Address',
                        subtitle: 'Where and how to reach the minor',
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: deco('Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _telCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('Telephone'),
                                  keyboardType: TextInputType.phone,
                                  validator: _requiredValidator,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _mnoCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('Mobile Number'),
                                  keyboardType: TextInputType.phone,
                                  validator: _requiredValidator,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _residesInCtrl,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: deco('Resides In'),
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('City'),
                                  validator: _requiredValidator,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _postCodeCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('Post Code'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _villageCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('Village'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _townCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('Town'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        cardColor: cardColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        accentColor: accentColor,
                        icon: Icons.family_restroom_rounded,
                        title: 'Guardian Details',
                        subtitle: 'The adult responsible for this account',
                        children: [
                          TextFormField(
                            controller: _guardianNameCtrl,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: deco('Guardian Full Name'),
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _guardianIdNumberCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('Guardian ID Number'),
                                  validator: _requiredValidator,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _guardianRelationshipCtrl,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: deco('Relationship to Minor'),
                                  validator: _requiredValidator,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _guardianTelCtrl,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: deco('Guardian Telephone'),
                            keyboardType: TextInputType.phone,
                            validator: _requiredValidator,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        cardColor: cardColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        accentColor: accentColor,
                        icon: Icons.badge_rounded,
                        title: 'Account Details',
                        subtitle: 'Broker and mandate configuration',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _accountClass,
                                  decoration: deco('Account Class'),
                                  dropdownColor: cardColor,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  items: _accountClasses
                                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _accountClass = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _investorType,
                                  decoration: deco('Investor Type'),
                                  dropdownColor: cardColor,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  items: _investorTypes
                                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _investorType = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _signingMandateOption,
                            decoration: deco('Signing Mandate Option'),
                            dropdownColor: cardColor,
                            style: TextStyle(color: textColor, fontSize: 14),
                            items: _signingOptions
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) => setState(() => _signingMandateOption = v),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _brokerCodeCtrl,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: deco('Broker Code'),
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _dateField(
                                  label: 'ID Issue Date',
                                  value: _identityIssueDate,
                                  deco: deco('ID Issue Date'),
                                  textColor: textColor,
                                  accentColor: accentColor,
                                  onTap: () => _pickDate(
                                    context: context,
                                    initial: _identityIssueDate,
                                    onPicked: (d) =>
                                        setState(() => _identityIssueDate = d),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dateField(
                                  label: 'ID Expiry Date',
                                  value: _idExpiryDate,
                                  deco: deco('ID Expiry Date'),
                                  textColor: textColor,
                                  accentColor: accentColor,
                                  onTap: () => _pickDate(
                                    context: context,
                                    initial: _idExpiryDate,
                                    onPicked: (d) => setState(() => _idExpiryDate = d),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        cardColor: cardColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        accentColor: accentColor,
                        icon: Icons.description_rounded,
                        title: 'Documents',
                        subtitle: 'Upload clear photos or PDFs',
                        children: [
                          _documentUploadTile(
                            label: 'Birth Certificate',
                            file: _birthCertificateFile,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            hintColor: hintColor,
                            accentColor: accentColor,
                            fieldBorder: fieldBorder,
                            onTap: () => _pickDocument(
                              label: 'Birth Certificate',
                              onPicked: (f) => _birthCertificateFile = f,
                            ),
                            onClear: () => setState(() => _birthCertificateFile = null),
                          ),
                          const SizedBox(height: 12),
                          _documentUploadTile(
                            label: 'Guardian ID',
                            file: _guardianIdFile,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            hintColor: hintColor,
                            accentColor: accentColor,
                            fieldBorder: fieldBorder,
                            onTap: () => _pickDocument(
                              label: 'Guardian ID',
                              onPicked: (f) => _guardianIdFile = f,
                            ),
                            onClear: () => setState(() => _guardianIdFile = null),
                          ),
                          const SizedBox(height: 12),
                          _documentUploadTile(
                            label: 'Proof of Address',
                            file: _proofOfAddressFile,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            hintColor: hintColor,
                            accentColor: accentColor,
                            fieldBorder: fieldBorder,
                            onTap: () => _pickDocument(
                              label: 'Proof of Address',
                              onPicked: (f) => _proofOfAddressFile = f,
                            ),
                            onClear: () => setState(() => _proofOfAddressFile = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _buildSubmitButton(isDark: isDark),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader({required bool isDark, required Color textColor}) {
    final headerGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B6914), Color(0xFF6B5010)],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_gold, _goldDark],
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: headerGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : _goldDark).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create Minor Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Guardian-assisted account opening',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A20) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF4A3F20) : const Color(0xFFFFE082),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: isDark ? Colors.amber : _gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A parent or legal guardian must complete this form and provide their own identification alongside the minor\'s details.',
              style: TextStyle(
                color: isDark ? Colors.white70 : _muted,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton({required bool isDark}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _isSubmitting
              ? null
              : LinearGradient(
            colors: isDark
                ? const [Color(0xFF8B6914), Color(0xFF6B5010)]
                : const [_gold, _goldDark],
          ),
          color: _isSubmitting ? Colors.grey[400] : null,
          boxShadow: _isSubmitting
              ? []
              : [
            BoxShadow(
              color: _goldDark.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _isSubmitting ? null : _submit,
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Submit Application',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required Color accentColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: mutedColor, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required InputDecoration deco,
    required Color textColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: deco.copyWith(
            suffixIcon: Icon(Icons.calendar_today_rounded, size: 17, color: accentColor),
          ),
          controller: TextEditingController(text: _formatDate(value)),
          validator: (_) => value == null ? 'Required' : null,
        ),
      ),
    );
  }

  Widget _documentUploadTile({
    required String label,
    required PlatformFile? file,
    required Color textColor,
    required Color mutedColor,
    required Color hintColor,
    required Color accentColor,
    required Color fieldBorder,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final bool hasFile = file != null;
    final bool isPdf = hasFile && file.name.toLowerCase().endsWith('.pdf');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: hasFile ? accentColor.withOpacity(0.06) : Colors.transparent,
          border: Border.all(
            color: hasFile ? accentColor : fieldBorder,
            width: hasFile ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasFile
                    ? accentColor.withOpacity(0.16)
                    : (mutedColor).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile
                    ? (isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded)
                    : Icons.upload_file_rounded,
                color: hasFile ? accentColor : hintColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? file.name : 'Tap to upload (PDF, JPG, PNG)',
                    style: TextStyle(color: hintColor, fontSize: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasFile)
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, color: hintColor, size: 18),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded, color: hintColor, size: 20),
          ],
        ),
      ),
    );
  }
}