import 'package:bse/contants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _currentStep = 0;
  bool _agreeToTerms = false;
  bool _isNewClient = true;

  // Step 0 – Account Type ('I' = Individual, 'C' = Corporate, 'M' = Minor)
  String _selectedAccountType = 'I';

  // Step 1 (Individual / Minor) – Basic Info (KYC)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _dobController = TextEditingController();
  final _cdsNumberController = TextEditingController();
  final _birthPlaceController = TextEditingController(); // Minor only

  // Step 1 (Corporate/Institutional) – Company Info
  final _companyNameController = TextEditingController();
  final _bRegNoController = TextEditingController();
  final _placeOfIncorporationController = TextEditingController();
  final _dateOfIncorporationController = TextEditingController();

  // Step 2 – Address (shared)
  final _addressController = TextEditingController();
  final _physicalAddressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _tinController = TextEditingController();

  // Contact & Work (Individual / Minor)
  final _phoneController = TextEditingController(); // general contact number (all types); also doubles as the wallet number for Individual
  final _walletMobileNumberController = TextEditingController(); // Mobile Money Wallet number (Corporate & Minor banking step)
  final _faxController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();
  final _natureOfBusinessController = TextEditingController();
  final _otherEmploymentController = TextEditingController(); // #6 - "specify" when Employment Status = Other

  // Banking (shared)
  final _ibanController = TextEditingController();
  final _accountNameController = TextEditingController(); // #9 - Account Name

  // Employee declaration (#10)
  bool _isBseEmployeeOrRelative = false;
  final _employeeDeclarationDetailsController = TextEditingController();

  // Guardian details (Minor only)
  final _guardianForenamesController = TextEditingController();
  final _guardianSurnameController = TextEditingController();
  final _guardianIdNumberController = TextEditingController();
  final _guardianRelationshipController = TextEditingController();

  // Signatories (Corporate/Institutional only) – each row holds:
  // Forenames, Surname, Identification, Role, Email, Mobile controllers.
  // IdType, Nationality and Mobile country code are dropdown-driven and kept
  // in parallel lists below (synced with _signatories by index).
  List<Map<String, TextEditingController>> _signatories = [
    {
      'forenames': TextEditingController(),
      'surname': TextEditingController(),
      'id': TextEditingController(),
      'role': TextEditingController(),
      'email': TextEditingController(),
      'mobile': TextEditingController(),
    },
  ];
  List<String> _signatoryIdTypes = ['National ID'];
  List<String> _signatoryNationalities = ['Motswana'];
  List<String> _signatoryMobileCodes = ['+267'];

  static const List<String> _signatoryIdTypeOptions = [
    'National ID',
    'Passport',
    'Foreign ID',
  ];

  // Demonym-style nationality options for signatories.
  static const List<String> _signatoryNationalityOptions = [
    'Motswana',
    'South African',
    'Zimbabwean',
    'Zambian',
    'Namibian',
    'Tanzanian',
    'Other',
  ];

  // Dropdown values
  String _selectedTitle = 'Mr.';
  String _selectedGender = 'Male';
  String _selectedIdType = 'National Id';
  String _selectedNationality = 'Botswana';
  String _selectedCountry = 'Botswana';
  String _selectedEmploymentStatus = 'Employed';
  String _selectedSourceOfIncome = 'Employment';
  String _selectedMNO = 'Mascom- MyZaka';

  // #8 - Mobile number country codes
  // _selectedMobileCountryCode -> Mobile Money Wallet number (Banking step)
  // _selectedContactCountryCode -> general Contact number (Minor & Institutional)
  String _selectedMobileCountryCode = '+267';
  String _selectedContactCountryCode = '+267';
  final List<Map<String, String>> _countryCodes = const [
    {'code': '+267', 'label': 'Botswana (+267)'},
    {'code': '+27', 'label': 'South Africa (+27)'},
    {'code': '+263', 'label': 'Zimbabwe (+263)'},
    {'code': '+260', 'label': 'Zambia (+260)'},
    {'code': '+264', 'label': 'Namibia (+264)'},
    {'code': '+255', 'label': 'Tanzania (+255)'},
  ];

  // Full country list – Botswana first, then alphabetical.
  // Used for Nationality and Country of Residence dropdowns.
  static const List<String> _countries = [
    'Botswana',
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola',
    'Antigua and Barbuda', 'Argentina', 'Armenia', 'Australia', 'Austria',
    'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus',
    'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia',
    'Bosnia and Herzegovina', 'Brazil', 'Brunei', 'Bulgaria', 'Burkina Faso',
    'Burundi', 'Cabo Verde', 'Cambodia', 'Cameroon', 'Canada',
    'Central African Republic', 'Chad', 'Chile', 'China', 'Colombia',
    'Comoros', 'Congo (DRC)', 'Congo (Republic)', 'Costa Rica', 'Croatia',
    'Cuba', 'Cyprus', 'Czech Republic', 'Denmark', 'Djibouti', 'Dominica',
    'Dominican Republic', 'Ecuador', 'Egypt', 'El Salvador',
    'Equatorial Guinea', 'Eritrea', 'Estonia', 'Eswatini', 'Ethiopia',
    'Fiji', 'Finland', 'France', 'Gabon', 'Gambia', 'Georgia', 'Germany',
    'Ghana', 'Greece', 'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau',
    'Guyana', 'Haiti', 'Honduras', 'Hungary', 'Iceland', 'India',
    'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy',
    'Ivory Coast', 'Jamaica', 'Japan', 'Jordan', 'Kazakhstan', 'Kenya',
    'Kiribati', 'Kuwait', 'Kyrgyzstan', 'Laos', 'Latvia', 'Lebanon',
    'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania',
    'Luxembourg', 'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali',
    'Malta', 'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico',
    'Micronesia', 'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 'Morocco',
    'Mozambique', 'Myanmar', 'Namibia', 'Nauru', 'Nepal', 'Netherlands',
    'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'North Korea',
    'North Macedonia', 'Norway', 'Oman', 'Pakistan', 'Palau', 'Panama',
    'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Poland',
    'Portugal', 'Qatar', 'Romania', 'Russia', 'Rwanda',
    'Saint Kitts and Nevis', 'Saint Lucia',
    'Saint Vincent and the Grenadines', 'Samoa', 'San Marino',
    'Sao Tome and Principe', 'Saudi Arabia', 'Senegal', 'Serbia',
    'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia',
    'Solomon Islands', 'Somalia', 'South Africa', 'South Korea',
    'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden',
    'Switzerland', 'Syria', 'Taiwan', 'Tajikistan', 'Tanzania', 'Thailand',
    'Timor-Leste', 'Togo', 'Tonga', 'Trinidad and Tobago', 'Tunisia',
    'Turkey', 'Turkmenistan', 'Tuvalu', 'Uganda', 'Ukraine',
    'United Arab Emirates', 'United Kingdom', 'United States', 'Uruguay',
    'Uzbekistan', 'Vanuatu', 'Vatican City', 'Venezuela', 'Vietnam',
    'Yemen', 'Zambia', 'Zimbabwe',
  ];

  // Broker
  String? _selectedBrokerCode;
  String? _selectedBrokerName;
  List<Map<String, dynamic>> _brokersList = [];
  bool _isLoadingBrokers = false;

  // Banks
  List<Map<String, dynamic>> _banksList = [];
  bool _isLoadingBanks = false;
  String? _selectedBankCode;
  String? _selectedBankName;
  String? _selectedBankSwiftCode;

  // Branches
  List<Map<String, dynamic>> _branchesList = [];
  bool _isLoadingBranches = false;
  String? _selectedBranchCode;
  String? _selectedBranchName;

  // Documents – Individual
  File? _idDocument;
  File? _proofOfAddressDocument;
  File? _proofOfEmploymentDocument;

  // Documents – Corporate
  File? _certificateOfIncorporationDocument;
  File? _boardResolutionDocument;
  File? _taxCertificateDocument;

  // Documents – Minor: reuses _idDocument ("National ID/Passport") and
  // _proofOfAddressDocument ("Proof of Residence") declared above.

  // Hardcoded
  final String _branchCode = "HRE001";
  final String _preFunding = "1";

  List<String> get _stepNames {
    if (_selectedAccountType == 'I') {
      return ['Type', 'Basic Info', 'Address', 'Contact', 'Banking', 'Final'];
    } else if (_selectedAccountType == 'C') {
      return ['Type', 'Institution', 'Address', 'Banking', 'Signatories', 'Final'];
    }
    return ['Type', 'Minor Info', 'Address', 'Guardian', 'Banking', 'Final'];
  }

  @override
  void initState() {
    super.initState();
    _fetchBrokers();
    _fetchBanks();
    _requestStoragePermission();
  }

  Future<void> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          _showSnackBar(
              'Storage permission permanently denied. Please enable it from settings.');
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        final status = await Permission.photos.request();
        if (status.isPermanentlyDenied) {
          _showSnackBar(
              'Photos permission permanently denied. Please enable it from settings.');
        }
      }
    } catch (e) {
      print('Permission request error: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idNumberController.dispose();
    _dobController.dispose();
    _cdsNumberController.dispose();
    _birthPlaceController.dispose();
    _companyNameController.dispose();
    _bRegNoController.dispose();
    _placeOfIncorporationController.dispose();
    _dateOfIncorporationController.dispose();
    _addressController.dispose();
    _physicalAddressController.dispose();
    _postalCodeController.dispose();
    _tinController.dispose();
    _phoneController.dispose();
    _walletMobileNumberController.dispose();
    _faxController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    _natureOfBusinessController.dispose();
    _otherEmploymentController.dispose();
    _ibanController.dispose();
    _accountNameController.dispose();
    _employeeDeclarationDetailsController.dispose();
    _guardianForenamesController.dispose();
    _guardianSurnameController.dispose();
    _guardianIdNumberController.dispose();
    _guardianRelationshipController.dispose();
    for (final row in _signatories) {
      row['forenames']?.dispose();
      row['surname']?.dispose();
      row['id']?.dispose();
      row['role']?.dispose();
      row['email']?.dispose();
      row['mobile']?.dispose();
    }
    super.dispose();
  }

  // ── Fetch Brokers ──────────────────────────────────────────────────────────
  Future<void> _fetchBrokers() async {
    setState(() => _isLoadingBrokers = true);
    try {
      final response = await http.get(
        Uri.parse('https://zamagm.escrowagm.com/MainAPI/Home/getAllBrokers'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<Map<String, dynamic>> list = [];
        if (responseData is List) {
          list = List<Map<String, dynamic>>.from(responseData);
        } else if (responseData is Map && responseData.containsKey('brokers')) {
          list = List<Map<String, dynamic>>.from(responseData['brokers']);
        }
        setState(() {
          _brokersList = list;
          if (_brokersList.isNotEmpty) {
            _selectedBrokerCode = _brokersList[0]['broker_code']?.toString();
            _selectedBrokerName = _brokersList[0]['fnam']?.toString();
          }
        });
      } else {
        _showSnackBar('Failed to load brokers');
      }
    } catch (e) {
      _showSnackBar('Error loading brokers: $e');
    } finally {
      setState(() => _isLoadingBrokers = false);
    }
  }

  // ── Fetch Banks ────────────────────────────────────────────────────────────
  Future<void> _fetchBanks() async {
    setState(() => _isLoadingBanks = true);
    try {
      final response = await http.get(
        Uri.parse('https://zamagm.escrowagm.com/MainAPI/Home/GetBanks'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<Map<String, dynamic>> list = [];
        if (responseData is Map && responseData.containsKey('banks')) {
          list = List<Map<String, dynamic>>.from(responseData['banks']);
        } else if (responseData is List) {
          list = List<Map<String, dynamic>>.from(responseData);
        }
        setState(() => _banksList = list);
      } else {
        _showSnackBar('Failed to load banks');
      }
    } catch (e) {
      _showSnackBar('Error loading banks: $e');
    } finally {
      setState(() => _isLoadingBanks = false);
    }
  }

  // ── Fetch Branches ─────────────────────────────────────────────────────────
  Future<void> _fetchBranches(String bankCode) async {
    setState(() {
      _isLoadingBranches = true;
      _branchesList = [];
      _selectedBranchCode = null;
      _selectedBranchName = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
            'https://zamagm.escrowagm.com/MainAPI/Home/GetBranches?bank=$bankCode'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<Map<String, dynamic>> list = [];
        if (responseData is Map && responseData.containsKey('branches')) {
          list = List<Map<String, dynamic>>.from(responseData['branches']);
        }
        setState(() => _branchesList = list);
      } else {
        _showSnackBar('Failed to load branches');
      }
    } catch (e) {
      _showSnackBar('Error loading branches: $e');
    } finally {
      setState(() => _isLoadingBranches = false);
    }
  }

  // ── Document Picker ────────────────────────────────────────────────────────
  Future<void> _pickDocument(String documentType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          _showSnackBar('File size must be less than 5MB');
          return;
        }
        setState(() {
          switch (documentType) {
            case 'ID':
              _idDocument = file;
              break;
            case 'ProofOfAddress':
              _proofOfAddressDocument = file;
              break;
            case 'ProofOfEmployment':
              _proofOfEmploymentDocument = file;
              break;
            case 'CertificateOfIncorporation':
              _certificateOfIncorporationDocument = file;
              break;
            case 'BoardResolution':
              _boardResolutionDocument = file;
              break;
            case 'TaxCertificate':
              _taxCertificateDocument = file;
              break;
          }
        });
        _showSnackBar('$documentType document selected successfully');
      }
    } catch (e) {
      _showSnackBar('Error picking document: $e');
    }
  }

  String _contentTypeForFile(File file) {
    final name = file.path.toLowerCase();
    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  String _getMNOCode(String mno) {
    switch (mno) {
      case 'Mascom- MyZaka':
        return 'MASCOM';
      case 'Orange Money':
        return 'ORANGE';
      case 'BTC Mobile Money/ Smega':
        return 'BTC';
      default:
        return mno.toUpperCase();
    }
  }

  Widget _buildDocumentUploadField(
      String label, File? file, String documentType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF6B5D4F),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _pickDocument(documentType),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: file != null
                      ? const Color(0xFFD4A855)
                      : const Color(0xFFE8D7B8),
                  width: file != null ? 2 : 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    file != null
                        ? (file.path.toLowerCase().endsWith('.pdf')
                        ? Icons.picture_as_pdf
                        : Icons.image)
                        : Icons.upload_file,
                    color: file != null
                        ? (file.path.toLowerCase().endsWith('.pdf')
                        ? Colors.red[700]
                        : const Color(0xFFD4A855))
                        : Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file != null
                              ? file.path.split('/').last
                              : 'Tap to upload document',
                          style: TextStyle(
                              color: file != null
                                  ? const Color(0xFFD4A855)
                                  : Colors.grey[400],
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (file == null)
                          Text('PDF or image (PNG/JPG), max 5MB',
                              style:
                              TextStyle(color: Colors.grey[400], fontSize: 10)),
                      ],
                    ),
                  ),
                  if (file != null)
                    const Icon(Icons.check_circle,
                        color: Color(0xFFD4A855), size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _convertFileToBase64(File? file) async {
    if (file == null || !file.existsSync()) return null;
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting file to base64: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _prepareDocuments() async {
    List<Map<String, dynamic>> documents = [];

    if (_selectedAccountType == 'C') {
      final certBase64 =
      await _convertFileToBase64(_certificateOfIncorporationDocument);
      if (certBase64 != null) {
        documents.add({
          "Name": "Certificate of Incorporation",
          "ContentType": _contentTypeForFile(_certificateOfIncorporationDocument!),
          "Data": certBase64
        });
      }
      final resolutionBase64 =
      await _convertFileToBase64(_boardResolutionDocument);
      if (resolutionBase64 != null) {
        documents.add({
          "Name": "Board Resolution",
          "ContentType": _contentTypeForFile(_boardResolutionDocument!),
          "Data": resolutionBase64
        });
      }
      final addressBase64 = await _convertFileToBase64(_proofOfAddressDocument);
      if (addressBase64 != null) {
        documents.add({
          "Name": "Proof of Address",
          "ContentType": _contentTypeForFile(_proofOfAddressDocument!),
          "Data": addressBase64
        });
      }
      final taxCertBase64 = await _convertFileToBase64(_taxCertificateDocument);
      if (taxCertBase64 != null) {
        documents.add({
          "Name": "Tax Certificate",
          "ContentType": _contentTypeForFile(_taxCertificateDocument!),
          "Data": taxCertBase64
        });
      }
      return documents;
    }

    if (_selectedAccountType == 'M') {
      final idBase64 = await _convertFileToBase64(_idDocument);
      if (idBase64 != null) {
        documents.add({
          "Name": "National ID/Passport",
          "ContentType": _contentTypeForFile(_idDocument!),
          "Data": idBase64
        });
      }
      final addressBase64 = await _convertFileToBase64(_proofOfAddressDocument);
      if (addressBase64 != null) {
        documents.add({
          "Name": "Proof of Residence",
          "ContentType": _contentTypeForFile(_proofOfAddressDocument!),
          "Data": addressBase64
        });
      }
      return documents;
    }

    final idBase64 = await _convertFileToBase64(_idDocument);
    if (idBase64 != null) {
      documents.add({
        "Name": "ID",
        "ContentType": _contentTypeForFile(_idDocument!),
        "Data": idBase64
      });
    }
    final addressBase64 = await _convertFileToBase64(_proofOfAddressDocument);
    if (addressBase64 != null) {
      documents.add({
        "Name": "Proof of Address",
        "ContentType": _contentTypeForFile(_proofOfAddressDocument!),
        "Data": addressBase64
      });
    }
    final employmentBase64 =
    await _convertFileToBase64(_proofOfEmploymentDocument);
    if (employmentBase64 != null) {
      documents.add({
        "Name": "Proof of Employment",
        "ContentType": _contentTypeForFile(_proofOfEmploymentDocument!),
        "Data": employmentBase64
      });
    }
    return documents;
  }

  void _handleNext() {
    if (_currentStep == 1) {
      if (_selectedAccountType == 'I') {
        if (!_validateStep1()) return;
      } else if (_selectedAccountType == 'C') {
        if (!_validateCompanyInfo()) return;
      } else {
        if (!_validateMinorInfo()) return;
      }
    } else if (_currentStep == 2) {
      if (!_validateStep2()) return;
    } else if (_currentStep == 3) {
      if (_selectedAccountType == 'I' && !_validateStep3()) return;
      if (_selectedAccountType == 'M' && !_validateGuardianInfo()) return;
      // Institutional flow has Banking at step 3.
      if (_selectedAccountType == 'C' && !_validateBanking()) return;
    } else if (_currentStep == 4) {
      if (_selectedAccountType == 'C' && !_validateSignatories()) return;
      // Individual & Minor flows have Banking at step 4.
      if (_selectedAccountType != 'C' && !_validateBanking()) return;
    } else if (_currentStep == 5) {
      if (!_validateStep5()) return;
    }

    if (_currentStep < 5) {
      setState(() => _currentStep++);
    } else {
      _submitForm();
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateStep1() {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _idNumberController.text.isEmpty ||
        _dobController.text.isEmpty) {
      _showSnackBar('Please fill all required fields');
      return false;
    }
    // Botswana National ID (Omang) = exactly 9 digits. Passport is free text.
    if (_selectedIdType == 'National Id') {
      if (!RegExp(r'^[0-9]{9}$').hasMatch(_idNumberController.text)) {
        _showSnackBar('National ID number must be exactly 9 digits');
        return false;
      }
    }
    if (!_isNewClient && _cdsNumberController.text.isEmpty) {
      _showSnackBar('Please enter CSD number for existing client');
      return false;
    }
    if (_selectedBrokerCode == null || _selectedBrokerCode!.isEmpty) {
      _showSnackBar('Please select a broker');
      return false;
    }
    return true;
  }

  bool _validateCompanyInfo() {
    if (!_isNewClient && _cdsNumberController.text.trim().isEmpty) {
      _showSnackBar('Please enter the CSD number for the existing account');
      return false;
    }
    if (_selectedBrokerCode == null || _selectedBrokerCode!.isEmpty) {
      _showSnackBar('Please select a broker');
      return false;
    }
    if (_companyNameController.text.isEmpty) {
      _showSnackBar('Please enter the company name');
      return false;
    }
    if (_bRegNoController.text.isEmpty) {
      _showSnackBar('Please enter the registration/certificate number');
      return false;
    }
    if (_dateOfIncorporationController.text.trim().isEmpty) {
      _showSnackBar('Please enter the date of incorporation/registration');
      return false;
    }
    if (_placeOfIncorporationController.text.trim().isEmpty) {
      _showSnackBar('Please enter the place of incorporation/registration');
      return false;
    }
    if (_natureOfBusinessController.text.trim().isEmpty) {
      _showSnackBar('Please describe the nature of business');
      return false;
    }
    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter the corporate email');
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar('Please enter the contact number');
      return false;
    }
    return true;
  }

  bool _validateMinorInfo() {
    if (!_isNewClient && _cdsNumberController.text.trim().isEmpty) {
      _showSnackBar('Please enter the CSD number for the existing account');
      return false;
    }
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _idNumberController.text.isEmpty ||
        _dobController.text.isEmpty) {
      _showSnackBar('Please fill all required fields');
      return false;
    }
    // Botswana National ID (Omang) = exactly 9 digits.
    // Birth Certificate / Passport / Foreign ID have no format validation.
    if (_selectedIdType == 'National Id') {
      if (!RegExp(r'^[0-9]{9}$').hasMatch(_idNumberController.text.trim())) {
        _showSnackBar('National ID number must be exactly 9 digits');
        return false;
      }
    }
    if (_birthPlaceController.text.trim().isEmpty) {
      _showSnackBar("Please enter the minor's birth place");
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar("Please enter the minor's email");
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar("Please enter a contact number");
      return false;
    }
    if (_selectedBrokerCode == null || _selectedBrokerCode!.isEmpty) {
      _showSnackBar('Please select a broker');
      return false;
    }
    return true;
  }

  bool _validateGuardianInfo() {
    if (_guardianForenamesController.text.trim().isEmpty) {
      _showSnackBar("Please enter the guardian's forenames");
      return false;
    }
    if (_guardianSurnameController.text.trim().isEmpty) {
      _showSnackBar("Please enter the guardian's surname");
      return false;
    }
    if (_guardianIdNumberController.text.trim().isEmpty) {
      _showSnackBar("Please enter the guardian's ID number");
      return false;
    }
    if (_guardianRelationshipController.text.trim().isEmpty) {
      _showSnackBar("Please enter the guardian's relationship to the minor");
      return false;
    }
    return true;
  }

  // Mobile Money Wallet validation (all account types).
  // Botswana (+267) numbers are exactly 8 digits, e.g. 71245676.
  bool _validateBanking() {
    final controller = _selectedAccountType == 'I'
        ? _phoneController
        : _walletMobileNumberController;
    final number = controller.text.trim();
    if (number.isEmpty) {
      _showSnackBar('Please enter the Mobile Money Wallet number');
      return false;
    }
    if (_selectedMobileCountryCode == '+267') {
      if (!RegExp(r'^[0-9]{8}$').hasMatch(number)) {
        _showSnackBar(
            'Botswana mobile wallet number must be exactly 8 digits, e.g. 71245676');
        return false;
      }
    } else {
      if (!RegExp(r'^[0-9]{6,15}$').hasMatch(number)) {
        _showSnackBar('Please enter a valid mobile wallet number (digits only)');
        return false;
      }
    }
    return true;
  }

  bool _validateStep2() {
    if (_addressController.text.isEmpty) {
      _showSnackBar('Please enter postal address');
      return false;
    }
    // #5 - TIN/Tax code is mandatory when ID Type is Passport (Individual/Minor),
    // and always mandatory for Institutional/Corporate accounts.
    if (_selectedAccountType == 'C' && _tinController.text.trim().isEmpty) {
      _showSnackBar('Tax Code / TIN is required for institutional accounts');
      return false;
    }
    if (_selectedAccountType != 'C' &&
        _selectedIdType == 'Passport' &&
        _tinController.text.trim().isEmpty) {
      _showSnackBar('Tax code / TIN is mandatory when ID Type is Passport');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Please fill in email');
      return false;
    }
    // #6 - specify field required when Employment Status is "Other"
    if (_selectedEmploymentStatus == 'Other' &&
        _otherEmploymentController.text.trim().isEmpty) {
      _showSnackBar('Please specify your employment status');
      return false;
    }
    return true;
  }

  bool _validateSignatories() {
    if (_signatories.isEmpty) {
      _showSnackBar('Please add at least one signatory');
      return false;
    }
    for (int i = 0; i < _signatories.length; i++) {
      final row = _signatories[i];
      if (row['forenames']!.text.trim().isEmpty) {
        _showSnackBar('Please enter the forenames for all signatories');
        return false;
      }
      if (row['surname']!.text.trim().isEmpty) {
        _showSnackBar('Please enter the surname for all signatories');
        return false;
      }
      if (row['id']!.text.trim().isEmpty) {
        _showSnackBar('Please enter an identification number for all signatories');
        return false;
      }
      // National ID must be exactly 9 digits; Passport/Foreign ID are free text.
      if (_signatoryIdTypes[i] == 'National ID' &&
          !RegExp(r'^[0-9]{9}$').hasMatch(row['id']!.text.trim())) {
        _showSnackBar(
            'Signatory ${i + 1}: National ID must be exactly 9 digits');
        return false;
      }
      if (row['role']!.text.trim().isEmpty) {
        _showSnackBar('Please enter the role for all signatories');
        return false;
      }
      if (row['email']!.text.trim().isEmpty) {
        _showSnackBar('Please enter the email for all signatories');
        return false;
      }
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
          .hasMatch(row['email']!.text.trim())) {
        _showSnackBar('Signatory ${i + 1}: please enter a valid email');
        return false;
      }
      final mobile = row['mobile']!.text.trim();
      if (mobile.isEmpty) {
        _showSnackBar('Please enter the mobile number for all signatories');
        return false;
      }
      if (_signatoryMobileCodes[i] == '+267' &&
          !RegExp(r'^[0-9]{8}$').hasMatch(mobile)) {
        _showSnackBar(
            'Signatory ${i + 1}: Botswana mobile number must be exactly 8 digits, e.g. 71234567');
        return false;
      }
    }
    return true;
  }

  bool _validateStep5() {
    if (!_agreeToTerms) {
      _showSnackBar('Please agree to the Terms & Conditions');
      return false;
    }
    // #10 - Employee / market exposure declaration (Individual accounts only)
    if (_selectedAccountType == 'I' &&
        _isBseEmployeeOrRelative &&
        _employeeDeclarationDetailsController.text.trim().isEmpty) {
      _showSnackBar(
          'Please provide details of the BSE employee / market exposure');
      return false;
    }
    if (_selectedAccountType == 'I') {
      // Attachments are always required for Individual accounts.
      if (_idDocument == null) {
        _showSnackBar('Please upload ID document');
        return false;
      }
      if (_proofOfAddressDocument == null) {
        _showSnackBar('Please upload Proof of Address document');
        return false;
      }
      if (_proofOfEmploymentDocument == null) {
        _showSnackBar(
            'Please upload Proof of Source of Income / Employment document');
        return false;
      }
    } else if (_selectedAccountType == 'M') {
      if (_idDocument == null) {
        _showSnackBar('Please upload the National ID / Passport');
        return false;
      }
      if (_proofOfAddressDocument == null) {
        _showSnackBar('Please upload Proof of Residence document');
        return false;
      }
    } else {
      if (_certificateOfIncorporationDocument == null) {
        _showSnackBar('Please upload the Certificate of Incorporation');
        return false;
      }
      if (_boardResolutionDocument == null) {
        _showSnackBar('Please upload the Board Resolution');
        return false;
      }
      if (_proofOfAddressDocument == null) {
        _showSnackBar('Please upload Proof of Address document');
        return false;
      }
      if (_taxCertificateDocument == null) {
        _showSnackBar('Please upload the Tax Certificate');
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> _buildPayload() {
    final now = DateTime.now();
    final agreementDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final common = {
      "Address1": _addressController.text,
      "PostalAddress": _postalCodeController.text,
      "City": _physicalAddressController.text,
      "Village": "",
      "Town": "",
      "ResidesIn": "",
      "myRegion": "",
      "myDistrict": "",
      "Landmark": "",
      "Tel": _phoneController.text,
      // Individual: the phone field IS the wallet number, so the wallet code
      // applies. Minor/Institutional: the contact number has its own code.
      "TelCountryCode": _selectedAccountType == 'I'
          ? _selectedMobileCountryCode
          : _selectedContactCountryCode,
      "MNO": _getMNOCode(_selectedMNO),
      "Fax": _faxController.text,
      "Email": _emailController.text,
      "Country": _selectedCountry,
      "TIN": _tinController.text,
      "IBAN": _ibanController.text,
      "AccountName": _accountNameController.text,
      "BankDiv": _selectedBankCode ?? '',
      "BankBranch": _selectedBranchCode ?? '',
      "SwiftCode": _selectedBankSwiftCode ?? '',
      "InvestorType": "",
      "AccountType": _selectedAccountType,
      "accountClass": "",
      "branchcode": _branchCode,
      "brokerlink": "0",
      "BrokerCode": _selectedBrokerCode,
      "PreFunding": _preFunding,
      "PrincipalOfficer": "",
      "myJointName": "",
      "Payee2": "",
      "AgreementDate": agreementDate,
      "CreatedBy": "MOBILE",
      "IsBseEmployeeOrRelative": _isBseEmployeeOrRelative,
      "EmployeeDeclarationDetails":
      _isBseEmployeeOrRelative ? _employeeDeclarationDetailsController.text : "",
    };

    if (_selectedAccountType == 'C') {
      return {
        ...common,
        "CompanyName": _companyNameController.text,
        "BRegNo": _bRegNoController.text,
        "Nationality": _selectedNationality,
        "NatureOfBusiness": _natureOfBusinessController.text,
        "DateOfIncorporation": _dateOfIncorporationController.text,
        "PlaceOfIncorporation": _placeOfIncorporationController.text,
        "MobileWalletNumber": _walletMobileNumberController.text,
        "cdsnumber": _isNewClient ? "" : _cdsNumberController.text,
        "clientType": _isNewClient ? "new" : "existing",
        "Signatories": List.generate(_signatories.length, (i) {
          final row = _signatories[i];
          final mobileCode = _signatoryMobileCodes[i];
          final mobileNumber = row['mobile']!.text.trim();
          // Mobile sent without the leading '+' and without a leading
          // trunk zero, e.g. +267 71234567 -> "26771234567".
          final normalizedMobile =
              '${mobileCode.replaceAll('+', '')}$mobileNumber';
          return {
            "Surname": row['surname']!.text.trim(),
            "Forenames": row['forenames']!.text.trim(),
            "Identification": row['id']!.text.trim(),
            "IdType": _signatoryIdTypes[i],
            "Nationality": _signatoryNationalities[i],
            "Role": row['role']!.text.trim(),
            "Email": row['email']!.text.trim(),
            "Mobile": normalizedMobile,
          };
        }),
      };
    }

    if (_selectedAccountType == 'M') {
      // The API expects a single combined "GuardianFullNames" field and
      // "GuardianIdentification".
      final guardianFullNames = [
        _guardianForenamesController.text.trim(),
        _guardianSurnameController.text.trim(),
      ].where((s) => s.isNotEmpty).join(' ');

      return {
        ...common,
        "Othernames": _firstNameController.text,
        "Surname": _lastNameController.text,
        "MiddleNames": "",
        "title": _selectedTitle,
        "Gender": _selectedGender,
        "idtype": _selectedIdType,
        "myIdentification": _idNumberController.text,
        "IDExpiryDate": "",
        "DOB": _dobController.text,
        "BirthPlace": _birthPlaceController.text,
        "Nationality": _selectedNationality,
        "Occupation": "N/A",
        "EmploymentStatus": "N/A",
        "EmploymentStatusOther": "",
        "EmployerName": "N/A",
        "EmployerAddress": "N/A",
        "Designation": "N/A",
        "NatureOfBusiness": "N/A",
        "sourceofIncome": "N/A",
        "MaritalStatus": "",
        "cdsnumber": _isNewClient ? "" : _cdsNumberController.text,
        "clientType": _isNewClient ? "new" : "existing",
        "MobileWalletNumber": _walletMobileNumberController.text,
        "GuardianFullNames": guardianFullNames,
        "GuardianIdentification": _guardianIdNumberController.text,
        "GuardianRelationship": _guardianRelationshipController.text,
      };
    }

    return {
      ...common,
      "Othernames": _firstNameController.text,
      "Surname": _lastNameController.text,
      "MiddleNames": "",
      "title": _selectedTitle,
      "Gender": _selectedGender,
      "idtype": _selectedIdType,
      "myIdentification": _idNumberController.text,
      "IDExpiryDate": "",
      "DOB": _dobController.text,
      "BirthPlace": "",
      "Nationality": _selectedNationality,
      "Occupation": _occupationController.text,
      "EmploymentStatus": _selectedEmploymentStatus,
      "EmploymentStatusOther": _otherEmploymentController.text,
      "EmployerName": "",
      "EmployerAddress": "",
      "Designation": "",
      "NatureOfBusiness": _natureOfBusinessController.text,
      "sourceofIncome": _selectedSourceOfIncome,
      "MaritalStatus": "",
      "cdsnumber": _isNewClient ? "" : _cdsNumberController.text,
      "clientType": _isNewClient ? "new" : "existing",
    };
  }

  Future<void> _submitForm() async {
    try {
      final documents = await _prepareDocuments();
      final payload = {
        ..._buildPayload(),
        "Documents": documents,
      };

      print("Submitting payload: ${json.encode(payload)}");

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFFD4A855)),
              SizedBox(width: 20),
              Text('Submitting...'),
            ],
          ),
        ),
      );

      final response = await http.post(
        Uri.parse('$baseUrl/Home/AccountOpening'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      Navigator.of(context).pop();

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is List) {
          if (responseData.isNotEmpty &&
              responseData[0]['responseCode'] == 0) {
            _showSuccessDialog(
                responseData[0]['responseMessage'] ?? 'Account Submitted Successfully');
          } else if (responseData.isNotEmpty) {
            _showErrorDialog(
                responseData[0]['responseMessage'] ?? 'Unknown error occurred');
          } else {
            _showErrorDialog('Empty response from server');
          }
        } else if (responseData is Map) {
          if (responseData.containsKey('responseMessage')) {
            _showSuccessDialog(responseData['responseMessage']);
          } else if (responseData.containsKey('message')) {
            _showErrorDialog(responseData['message']);
          } else {
            _showErrorDialog('Unexpected response format');
          }
        }
      } else if (response.statusCode == 401) {
        _showErrorDialog('Unauthorized access (401).');
      } else if (response.statusCode == 500) {
        _showErrorDialog('Server error (500). Please try again later.');
      } else {
        _showErrorDialog('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      _showErrorDialog('Network error: $e');
    } on Exception catch (e) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      _showErrorDialog('Error: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Success', style: TextStyle(color: Colors.green)),
        ]),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFFD4A855))),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Text('Error', style: TextStyle(color: Colors.red)),
        ]),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFFD4A855))),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFFD4A855),
    ));
  }

  Widget _buildStepIndicator() {
    final stepNames = _stepNames;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(stepNames.length, (index) {
            return Row(
              children: [
                _buildStepCircle(index, stepNames[index]),
                if (index < stepNames.length - 1) _buildStepLine(),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepCircle(int stepNumber, String label) {
    bool isActive = _currentStep == stepNumber;
    bool isCompleted = _currentStep > stepNumber;
    return GestureDetector(
      onTap: () => setState(() => _currentStep = stepNumber),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isActive || isCompleted
                  ? const Color(0xFFD4A855)
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                (stepNumber + 1).toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 50,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? const Color(0xFFD4A855) : Colors.grey[600],
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.grey[300],
    );
  }

  Widget _buildClientTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Client Type',
            style: TextStyle(
                color: Color(0xFF6B5D4F),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE8D7B8)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 3,
                  offset: const Offset(0, 1))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isNewClient = true),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isNewClient
                          ? const Color(0xFFD4A855)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text('New Client',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isNewClient
                                  ? Colors.white
                                  : const Color(0xFF6B5D4F))),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isNewClient = false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_isNewClient
                          ? const Color(0xFFD4A855)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text('Existing',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: !_isNewClient
                                  ? Colors.white
                                  : const Color(0xFF6B5D4F))),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isNewClient ? 'Creating new account' : 'Updating existing account',
          style: const TextStyle(color: Color(0xFFD4A855), fontSize: 10),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8DC), Color(0xFFFFF4D6), Color(0xFFFFEFCC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 10),
              const Text(
                'Account Creation',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C1810)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _buildStepIndicator(),
              const SizedBox(height: 15),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: 2)
                    ],
                  ),
                  child: _buildCurrentStep(),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleBack,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side:
                          const BorderSide(color: Color(0xFFD4A855), width: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _currentStep == 0 ? 'Cancel' : 'Previous',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD4A855)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A855),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentStep == 5 ? 'Submit' : 'Next',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildAccountTypeStep();
      case 1:
        if (_selectedAccountType == 'I') return _buildStep1();
        if (_selectedAccountType == 'C') return _buildCompanyInfoStep();
        return _buildMinorInfoStep();
      case 2:
        return _buildStep2();
      case 3:
        if (_selectedAccountType == 'I') return _buildStep3();
        if (_selectedAccountType == 'C') return _buildStep4();
        return _buildGuardianStep();
      case 4:
        if (_selectedAccountType == 'I') return _buildStep4();
        if (_selectedAccountType == 'C') return _buildSignatoriesStep();
        return _buildStep4();
      case 5:
        return _buildStep5();
      default:
        return _buildAccountTypeStep();
    }
  }

  // ── Step 0: Account Type ───────────────────────────────────────────────────
  Widget _buildAccountTypeStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What type of account would you like to open?',
            style: TextStyle(
                color: Color(0xFF2C1810),
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildAccountTypeCard(
            type: 'I',
            title: 'Individual',
            subtitle: 'For personal trading accounts',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildAccountTypeCard(
            type: 'C',
            title: 'Institutional',
            subtitle: 'For companies, trusts and organisations',
            icon: Icons.apartment_outlined,
          ),
          const SizedBox(height: 12),
          _buildAccountTypeCard(
            type: 'M',
            title: 'Minor',
            subtitle: 'Opened by a parent or guardian on behalf of a minor',
            icon: Icons.child_care_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool selected = _selectedAccountType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedAccountType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD4A855).withOpacity(0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? const Color(0xFFD4A855)
                  : const Color(0xFFE8D7B8),
              width: selected ? 2 : 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFD4A855)
                    : const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : Colors.grey[500]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: selected
                            ? const Color(0xFF2C1810)
                            : Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFFD4A855)),
          ],
        ),
      ),
    );
  }

  // ── Step 1 (Individual): Basic Info (KYC) ──────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClientTypeToggle(),
          const SizedBox(height: 15),
          if (!_isNewClient) ...[
            _buildLabelWithField('CSD Number *',
                _buildTextField('Enter CSD number', _cdsNumberController)),
            const SizedBox(height: 15),
          ],
          _buildLabelWithField('Broker *', _buildBrokerDropdown()),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(
                child: _buildLabelWithField(
                    'Title',
                    _buildDropdownField(
                        'Title',
                        _selectedTitle,
                        ['Mr.', 'Mrs.', 'Ms.', 'Dr.'],
                            (val) => setState(() => _selectedTitle = val!)))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildLabelWithField(
                    'Gender',
                    _buildDropdownField(
                        'Gender',
                        _selectedGender,
                        ['Male', 'Female'],
                            (val) => setState(() => _selectedGender = val!)))),
          ]),
          const SizedBox(height: 15),
          _buildLabelWithField('Forenames *',
              _buildTextField('Enter forenames', _firstNameController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Surname *',
              _buildTextField('Enter surname', _lastNameController)),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Date of Birth *',
              _buildTextField('YYYY-MM-DD', _dobController, onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                  DateTime.now().subtract(const Duration(days: 365 * 18)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _dobController.text =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                }
              })),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(
                child: _buildLabelWithField(
                    'ID Type',
                    _buildDropdownField(
                        'ID Type',
                        _selectedIdType,
                        ['National Id', 'Passport'],
                            (val) => setState(() => _selectedIdType = val!)))),
            const SizedBox(width: 10),
            Expanded(
              child: _buildLabelWithField(
                'ID Number *',
                _selectedIdType == 'National Id'
                    ? _buildNationalIdField()
                    : _buildTextField(
                    'Enter passport number', _idNumberController),
              ),
            ),
          ]),
          if (_selectedIdType == 'Passport') ...[
            const SizedBox(height: 6),
            const Text(
              'Tax code / TIN will be required in the Address step.',
              style: TextStyle(color: Color(0xFFD4A855), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  // 9-digit numeric National ID (Omang) input – shared by Individual, Minor
  // and Signatories. Defaults to _idNumberController when none is passed.
  Widget _buildNationalIdField({TextEditingController? controller}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller ?? _idNumberController,
        keyboardType: TextInputType.number,
        maxLength: 9,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9)
        ],
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          hintText: '9-digit ID',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          counterText: '',
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  // ── Step 1 (Institutional/Corporate): Company Info ─────────────────────────
  Widget _buildCompanyInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClientTypeToggle(),
          const SizedBox(height: 15),
          if (!_isNewClient) ...[
            _buildLabelWithField('CSD Number *',
                _buildTextField('Enter CSD number', _cdsNumberController)),
            const SizedBox(height: 15),
          ],
          _buildLabelWithField('Broker *', _buildBrokerDropdown()),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Name of Institution *',
              _buildTextField(
                  'Enter registered institution name', _companyNameController)),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Registration / Certificate No. *',
              _buildTextField(
                  'Enter registration number', _bRegNoController)),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(
              child: _buildLabelWithField(
                  'Date of Incorporation *',
                  _buildTextField('YYYY-MM-DD', _dateOfIncorporationController,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          _dateOfIncorporationController.text =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        }
                      })),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildLabelWithField(
                  'Place of Incorporation *',
                  _buildTextField(
                      'Enter place of incorporation', _placeOfIncorporationController)),
            ),
          ]),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Nature of Business *',
              _buildTextField(
                  'Describe nature of business', _natureOfBusinessController)),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Corporate Email *',
              _buildTextField('Enter corporate email', _emailController,
                  keyboardType: TextInputType.emailAddress)),
          const SizedBox(height: 15),
          _buildLabelWithField(
            'Contact Number *',
            _buildPhoneFieldWithCountryCode(
              _phoneController,
              code: _selectedContactCountryCode,
              onCodeChanged: (val) =>
                  setState(() => _selectedContactCountryCode = val),
              hint: 'Enter contact number',
            ),
          ),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Nationality',
              _buildDropdownField(
                  'Nationality',
                  _selectedNationality,
                  _countries,
                      (val) => setState(() => _selectedNationality = val!))),
        ],
      ),
    );
  }

  // ── Step 1 (Minor): Minor's Info ───────────────────────────────────────────
  Widget _buildMinorInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClientTypeToggle(),
          const SizedBox(height: 15),
          if (!_isNewClient) ...[
            _buildLabelWithField('CSD Number *',
                _buildTextField('Enter CSD number', _cdsNumberController)),
            const SizedBox(height: 15),
          ],
          _buildLabelWithField('Broker *', _buildBrokerDropdown()),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(
                child: _buildLabelWithField(
                    'Title',
                    _buildDropdownField(
                        'Title',
                        _selectedTitle,
                        ['Master', 'Miss', 'Mr.', 'Mrs.', 'Ms.', 'Dr.'],
                            (val) => setState(() => _selectedTitle = val!)))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildLabelWithField(
                    'Gender',
                    _buildDropdownField(
                        'Gender',
                        _selectedGender,
                        ['Male', 'Female'],
                            (val) => setState(() => _selectedGender = val!)))),
          ]),
          const SizedBox(height: 15),
          _buildLabelWithField('Forenames *',
              _buildTextField("Enter minor's forenames", _firstNameController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Surname *',
              _buildTextField("Enter minor's surname", _lastNameController)),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Date of Birth *',
              _buildTextField('YYYY-MM-DD', _dobController, onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                  DateTime.now().subtract(const Duration(days: 365 * 8)),
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _dobController.text =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                }
              })),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(
                child: _buildLabelWithField(
                    'ID Type',
                    _buildDropdownField(
                        'ID Type',
                        _selectedIdType,
                        // 'Foreign ID' has no format validation so it can
                        // accommodate identification from any country.
                        [
                          'Birth Certificate',
                          'National Id',
                          'Passport',
                          'Foreign ID'
                        ],
                            (val) => setState(() => _selectedIdType = val!)))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildLabelWithField(
                    'ID / Birth Cert No. *',
                    _selectedIdType == 'National Id'
                        ? _buildNationalIdField()
                        : _buildTextField(
                        'Enter ID number', _idNumberController))),
          ]),
          if (_selectedIdType == 'National Id') ...[
            const SizedBox(height: 6),
            const Text(
              'Botswana National ID must be exactly 9 digits.',
              style: TextStyle(color: Color(0xFFD4A855), fontSize: 11),
            ),
          ],
          const SizedBox(height: 15),
          _buildLabelWithField('Birth Place *',
              _buildTextField('Enter place of birth', _birthPlaceController)),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Email *',
              _buildTextField('Enter email address', _emailController,
                  keyboardType: TextInputType.emailAddress)),
          const SizedBox(height: 15),
          _buildLabelWithField(
            'Contact Number *',
            _buildPhoneFieldWithCountryCode(
              _phoneController,
              code: _selectedContactCountryCode,
              onCodeChanged: (val) =>
                  setState(() => _selectedContactCountryCode = val),
              hint: 'Enter contact number',
            ),
          ),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Nationality',
              _buildDropdownField(
                  'Nationality',
                  _selectedNationality,
                  _countries,
                      (val) => setState(() => _selectedNationality = val!))),
        ],
      ),
    );
  }

  // ── Step 3 (Minor): Guardian Details ───────────────────────────────────────
  // Alignment fix: fields grouped inside a card with consistent labels/spacing.
  Widget _buildGuardianStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guardian Details',
            style: TextStyle(
                color: Color(0xFF2C1810),
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'The parent or legal guardian responsible for this account.',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8D7B8)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabelWithField(
                    'Forenames *',
                    _buildTextField("Enter guardian's forenames",
                        _guardianForenamesController)),
                const SizedBox(height: 15),
                _buildLabelWithField(
                    'Surname *',
                    _buildTextField(
                        "Enter guardian's surname", _guardianSurnameController)),
                const SizedBox(height: 15),
                _buildLabelWithField(
                    'Identification No *',
                    _buildTextField("Enter guardian's ID number",
                        _guardianIdNumberController)),
                const SizedBox(height: 15),
                _buildLabelWithField(
                    'Relationship with Minor *',
                    _buildTextField('e.g. Mother, Father, Legal Guardian',
                        _guardianRelationshipController)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Address (shared) ───────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelWithField('Postal Address *',
              _buildTextField('Enter postal address', _addressController)),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Physical Address',
              _buildTextField(
                  'Enter physical address', _physicalAddressController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Postal Code',
              _buildTextField('Enter postal code', _postalCodeController)),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Country of Residence *',
              _buildDropdownField(
                  'Country of Residence',
                  _selectedCountry,
                  _countries,
                      (val) => setState(() => _selectedCountry = val!))),
          const SizedBox(height: 15),
          _buildLabelWithField(
              (_selectedAccountType == 'C' || _selectedIdType == 'Passport')
                  ? 'TIN / Tax Code *'
                  : 'TIN / Tax Code',
              _buildTextField('Enter TIN number', _tinController)),
        ],
      ),
    );
  }

  // ── Step 3 (Individual): Contact & Work ────────────────────────────────────
  Widget _buildStep3() {
    final bool showOccupation = _selectedEmploymentStatus != 'Student' &&
        _selectedEmploymentStatus != 'Unemployed';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelWithField(
              'Email *',
              _buildTextField('Enter email address', _emailController,
                  keyboardType: TextInputType.emailAddress)),
          const SizedBox(height: 15),
          if (showOccupation) ...[
            Row(children: [
              Expanded(
                  child: _buildLabelWithField(
                      'Employment Status *',
                      _buildDropdownField(
                          'Employment Status',
                          _selectedEmploymentStatus,
                          ['Student', 'Employed', 'Unemployed', 'Other'],
                              (val) => setState(
                                  () => _selectedEmploymentStatus = val!)))),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildLabelWithField(
                      'Occupation',
                      _buildTextField(
                          'Enter occupation', _occupationController))),
            ]),
          ] else ...[
            _buildLabelWithField(
                'Employment Status *',
                _buildDropdownField(
                    'Employment Status',
                    _selectedEmploymentStatus,
                    ['Student', 'Employed', 'Unemployed', 'Other'],
                        (val) =>
                        setState(() => _selectedEmploymentStatus = val!))),
          ],
          if (_selectedEmploymentStatus == 'Other') ...[
            const SizedBox(height: 15),
            _buildLabelWithField(
                'Please specify *',
                _buildTextField(
                    'Specify employment status', _otherEmploymentController)),
          ],
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Source of Income / Funds *',
              _buildDropdownField(
                  'Source of Income',
                  _selectedSourceOfIncome,
                  ['Employment', 'Business', 'Investments', 'Other'],
                      (val) =>
                      setState(() => _selectedSourceOfIncome = val!))),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Nature & Location of Business Activities',
              _buildTextField('Describe nature of business',
                  _natureOfBusinessController)),
        ],
      ),
    );
  }

  // ── Banking (shared) ───────────────────────────────────────────────────────
  Widget _buildStep4() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelWithField(
            'Mobile Network Operator *',
            _buildDropdownField(
              'Select MNO',
              _selectedMNO,
              ['Mascom- MyZaka', 'Orange Money', 'BTC Mobile Money/ Smega'],
                  (val) => setState(() => _selectedMNO = val!),
            ),
          ),
          const SizedBox(height: 15),
          _buildLabelWithField(
            'Mobile Money Wallet *',
            _buildPhoneFieldWithCountryCode(
              _selectedAccountType == 'I'
                  ? _phoneController
                  : _walletMobileNumberController,
              code: _selectedMobileCountryCode,
              onCodeChanged: (val) =>
                  setState(() => _selectedMobileCountryCode = val),
              hint: _selectedMobileCountryCode == '+267'
                  ? '8 digits, e.g. 71245676'
                  : 'Enter mobile money number',
              digitsOnly: true,
              maxLength: _selectedMobileCountryCode == '+267' ? 8 : 15,
            ),
          ),
          if (_selectedMobileCountryCode == '+267') ...[
            const SizedBox(height: 6),
            const Text(
              'Botswana mobile numbers are 8 digits (e.g. 71245676).',
              style: TextStyle(color: Color(0xFFD4A855), fontSize: 11),
            ),
          ],
          const SizedBox(height: 15),

          // Bank Name Dropdown
          _buildLabelWithField('Bank Name', _buildBankDropdown()),
          const SizedBox(height: 15),

          // Swift Code – auto-filled, read-only
          _buildLabelWithField(
            'Swift Code',
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8D7B8)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 5,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      (_selectedBankSwiftCode != null &&
                          _selectedBankSwiftCode!.isNotEmpty)
                          ? _selectedBankSwiftCode!
                          : 'Auto-filled on bank selection',
                      style: TextStyle(
                        color: (_selectedBankSwiftCode != null &&
                            _selectedBankSwiftCode!.isNotEmpty)
                            ? Colors.black87
                            : Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Bank Branch Dropdown
          _buildLabelWithField('Bank Branch', _buildBranchDropdown()),
          const SizedBox(height: 15),

          // Account Name (#9)
          _buildLabelWithField(
              'Account Name',
              _buildTextField(
                  'Enter account holder name', _accountNameController)),
          const SizedBox(height: 15),

          // Account Number
          _buildLabelWithField(
              'Account Number',
              _buildTextField('Enter account number', _ibanController,
                  keyboardType: TextInputType.number)),
        ],
      ),
    );
  }

  // #8 - Mobile/contact number field with country code selector.
  // Parameterised so the wallet number and contact number can each keep
  // their own country code.
  Widget _buildPhoneFieldWithCountryCode(
      TextEditingController controller, {
        required String code,
        required ValueChanged<String> onCodeChanged,
        String hint = 'Enter mobile number',
        bool digitsOnly = false,
        int? maxLength,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          width: 110,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8D7B8)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 2))
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: code,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              icon: Icon(Icons.arrow_drop_down,
                  color: Colors.grey[600], size: 18),
              items: _countryCodes
                  .map((c) => DropdownMenuItem<String>(
                value: c['code'],
                child: Text(c['code']!,
                    overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                onCodeChanged(val);
              },
              selectedItemBuilder: (context) => _countryCodes
                  .map((c) => Align(
                alignment: Alignment.centerLeft,
                child: Text(c['code']!,
                    style: const TextStyle(fontSize: 13)),
              ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8D7B8)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ],
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              maxLength: maxLength,
              inputFormatters: [
                if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
                if (maxLength != null)
                  LengthLimitingTextInputFormatter(maxLength),
              ],
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 4 (Institutional/Corporate): Signatories ──────────────────────────
  // Alignment fix: labelled fields with consistent spacing inside each card.
  Widget _buildSignatoriesStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signatories *',
            style: TextStyle(
                color: Color(0xFF2C1810),
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Add at least one authorised signatory with their identification number.',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 12),
          ..._signatories.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8D7B8)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Signatory ${index + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B5D4F),
                                fontSize: 13)),
                        if (_signatories.length > 1)
                          GestureDetector(
                            onTap: () => setState(() {
                              final removed = _signatories.removeAt(index);
                              removed['forenames']?.dispose();
                              removed['surname']?.dispose();
                              removed['id']?.dispose();
                              removed['role']?.dispose();
                              removed['email']?.dispose();
                              removed['mobile']?.dispose();
                              _signatoryIdTypes.removeAt(index);
                              _signatoryNationalities.removeAt(index);
                              _signatoryMobileCodes.removeAt(index);
                            }),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: _buildLabelWithField(
                              'Forenames *',
                              _buildTextField(
                                  'Enter forenames', row['forenames']!))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _buildLabelWithField(
                              'Surname *',
                              _buildTextField(
                                  'Enter surname', row['surname']!))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _buildLabelWithField(
                          'ID Type *',
                          _buildDropdownField(
                            'ID Type',
                            _signatoryIdTypes[index],
                            _signatoryIdTypeOptions,
                                (val) => setState(
                                    () => _signatoryIdTypes[index] = val!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildLabelWithField(
                          'Identification No *',
                          _signatoryIdTypes[index] == 'National ID'
                              ? _buildNationalIdField(controller: row['id']!)
                              : _buildTextField(
                              'Enter identification number', row['id']!),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _buildLabelWithField(
                      'Nationality *',
                      _buildDropdownField(
                        'Nationality',
                        _signatoryNationalities[index],
                        _signatoryNationalityOptions,
                            (val) => setState(
                                () => _signatoryNationalities[index] = val!),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLabelWithField('Role *',
                        _buildTextField('e.g. Director, Trustee', row['role']!)),
                    const SizedBox(height: 12),
                    _buildLabelWithField(
                        'Email *',
                        _buildTextField('Enter email address', row['email']!,
                            keyboardType: TextInputType.emailAddress)),
                    const SizedBox(height: 12),
                    _buildLabelWithField(
                      'Mobile *',
                      _buildPhoneFieldWithCountryCode(
                        row['mobile']!,
                        code: _signatoryMobileCodes[index],
                        onCodeChanged: (val) => setState(
                                () => _signatoryMobileCodes[index] = val),
                        hint: _signatoryMobileCodes[index] == '+267'
                            ? '8 digits, e.g. 71234567'
                            : 'Enter mobile number',
                        digitsOnly: true,
                        maxLength:
                        _signatoryMobileCodes[index] == '+267' ? 8 : 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _signatories.add({
                  'forenames': TextEditingController(),
                  'surname': TextEditingController(),
                  'id': TextEditingController(),
                  'role': TextEditingController(),
                  'email': TextEditingController(),
                  'mobile': TextEditingController(),
                });
                _signatoryIdTypes.add('National ID');
                _signatoryNationalities.add('Motswana');
                _signatoryMobileCodes.add('+267');
              }),
              icon: const Icon(Icons.add, color: Color(0xFFD4A855), size: 18),
              label: const Text('Add signatory',
                  style: TextStyle(color: Color(0xFFD4A855))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFD4A855)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Documents & Final ──────────────────────────────────────────────
  Widget _buildStep5() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attachments *',
            style: TextStyle(
                color: Color(0xFF6B5D4F),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (_selectedAccountType == 'I') ...[
            // Attachments always shown for Individual accounts.
            _buildDocumentUploadField(
                '1. Certified Copy of National Identity Card',
                _idDocument,
                'ID'),
            const SizedBox(height: 15),
            _buildDocumentUploadField('2. Proof of Address',
                _proofOfAddressDocument, 'ProofOfAddress'),
            const SizedBox(height: 15),
            _buildDocumentUploadField(
                '3. Proof of Source of Income / Employment',
                _proofOfEmploymentDocument,
                'ProofOfEmployment'),
            const SizedBox(height: 25),
          ] else if (_selectedAccountType == 'M') ...[
            _buildDocumentUploadField(
                '1. National ID / Passport', _idDocument, 'ID'),
            const SizedBox(height: 15),
            _buildDocumentUploadField('2. Proof of Residence',
                _proofOfAddressDocument, 'ProofOfAddress'),
            const SizedBox(height: 25),
          ] else ...[
            _buildDocumentUploadField('1. Certificate of Incorporation',
                _certificateOfIncorporationDocument,
                'CertificateOfIncorporation'),
            const SizedBox(height: 15),
            _buildDocumentUploadField('2. Board Resolution',
                _boardResolutionDocument, 'BoardResolution'),
            const SizedBox(height: 15),
            _buildDocumentUploadField('3. Proof of Address',
                _proofOfAddressDocument, 'ProofOfAddress'),
            const SizedBox(height: 15),
            _buildDocumentUploadField(
                '4. Tax Certificate', _taxCertificateDocument, 'TaxCertificate'),
            const SizedBox(height: 25),
          ],

          // #10 - Employee / market exposure declaration (Individual only)
          if (_selectedAccountType == 'I') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8D7B8)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 5,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Employee / Market Exposure Declaration *',
                    style: TextStyle(
                        color: Color(0xFF6B5D4F),
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Are you a BSE employee, a relative of a BSE employee, or otherwise exposed to the markets?',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Yes', style: TextStyle(fontSize: 13)),
                          value: true,
                          groupValue: _isBseEmployeeOrRelative,
                          activeColor: const Color(0xFFD4A855),
                          onChanged: (val) =>
                              setState(() => _isBseEmployeeOrRelative = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('No', style: TextStyle(fontSize: 13)),
                          value: false,
                          groupValue: _isBseEmployeeOrRelative,
                          activeColor: const Color(0xFFD4A855),
                          onChanged: (val) =>
                              setState(() => _isBseEmployeeOrRelative = val!),
                        ),
                      ),
                    ],
                  ),
                  if (_isBseEmployeeOrRelative) ...[
                    const SizedBox(height: 4),
                    _buildTextField(
                        'Details, e.g. self, spouse of John Doe, market exposure',
                        _employeeDeclarationDetailsController),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) =>
                      setState(() => _agreeToTerms = value ?? false),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected))
                      return const Color(0xFFD4A855);
                    return Colors.transparent;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(
                              color: Color(0xFF6B5D4F), fontSize: 13)),
                      TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                              color: Color(0xFFD4A855),
                              fontSize: 13,
                              decoration: TextDecoration.underline)),
                      TextSpan(
                          text:
                          ' and confirm that all information provided is accurate.',
                          style: TextStyle(
                              color: Color(0xFF6B5D4F), fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFD4A855), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please review all information before submitting. Ensure all required fields are filled.',
                    style:
                    TextStyle(color: Color(0xFF6B5D4F), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _buildBrokerDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBrokerName,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
          hint: _isLoadingBrokers
              ? const Row(children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Loading brokers...', style: TextStyle(fontSize: 14)),
          ])
              : const Text('Select broker', style: TextStyle(fontSize: 14)),
          items: _brokersList.map((broker) {
            final brokerName = broker['fnam']?.toString() ?? 'Unknown';
            final brokerCode = broker['broker_code']?.toString() ?? '';
            return DropdownMenuItem<String>(
              value: brokerName,
              onTap: () => setState(() {
                _selectedBrokerCode = brokerCode;
                _selectedBrokerName = brokerName;
              }),
              child: Text(brokerName),
            );
          }).toList(),
          onChanged: (String? newValue) {},
        ),
      ),
    );
  }

  Widget _buildBankDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBankCode,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
          hint: _isLoadingBanks
              ? const Row(children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Loading banks...', style: TextStyle(fontSize: 14)),
          ])
              : Text('Select bank',
              style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          items: _banksList.map((bank) {
            final code = bank['bank']?.toString() ?? '';
            final name = bank['bank_name']?.toString() ?? 'Unknown';
            return DropdownMenuItem<String>(
              value: code,
              child: Text(name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (String? newCode) {
            if (newCode == null) return;
            final bank = _banksList.firstWhere(
                  (b) => b['bank']?.toString() == newCode,
              orElse: () => {},
            );
            setState(() {
              _selectedBankCode = newCode;
              _selectedBankName = bank['bank_name']?.toString() ?? '';
              _selectedBankSwiftCode = bank['swiftcode']?.toString() ?? '';
            });
            _fetchBranches(newCode);
          },
        ),
      ),
    );
  }

  Widget _buildBranchDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _selectedBankCode == null
            ? const Color(0xFFF5F5F5)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBranchCode,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          icon: _isLoadingBranches
              ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
          hint: Text(
            _selectedBankCode == null
                ? 'Select a bank first'
                : _isLoadingBranches
                ? 'Loading branches...'
                : 'Select branch',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          items: _branchesList.map((branch) {
            final code = branch['branch']?.toString() ?? '';
            final name = branch['branch_name']?.toString() ?? 'Unknown';
            return DropdownMenuItem<String>(
              value: code,
              child: Text(name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (_selectedBankCode == null || _isLoadingBranches)
              ? null
              : (String? newCode) {
            if (newCode == null) return;
            final branch = _branchesList.firstWhere(
                  (b) => b['branch']?.toString() == newCode,
              orElse: () => {},
            );
            setState(() {
              _selectedBranchCode = newCode;
              _selectedBranchName =
                  branch['branch_name']?.toString() ?? '';
            });
          },
        ),
      ),
    );
  }

  Widget _buildLabelWithField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF6B5D4F),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        field,
      ],
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      {TextInputType? keyboardType, VoidCallback? onTap}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onTap: onTap,
        readOnly: onTap != null,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hint, String value, List<String> items,
      Function(String?) onChanged) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          dropdownColor: Colors.white,
          menuMaxHeight: 400,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
          items: items
              .map((String item) =>
              DropdownMenuItem<String>(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}