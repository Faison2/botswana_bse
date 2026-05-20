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

  // Step 1 – Basic Info (KYC)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _dobController = TextEditingController();
  final _cdsNumberController = TextEditingController();

  // Step 2 – Address
  final _addressController = TextEditingController();
  final _physicalAddressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _villageController = TextEditingController();
  final _villageTownCityController = TextEditingController();
  final _residentInController = TextEditingController();
  final _tinController = TextEditingController();

  // Step 3 – Contact & Work
  final _phoneController = TextEditingController();
  final _faxController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();
  final _natureOfBusinessController = TextEditingController();

  // Step 4 – Banking
  final _ibanController = TextEditingController();

  // Dropdown values
  String _selectedTitle = 'Mr.';
  String _selectedGender = 'Male';
  String _selectedIdType = 'National Id';
  String _selectedNationality = 'Botswana';
  String _selectedCountry = 'Botswana';
  String _selectedAccountType = 'I';
  String _selectedEmploymentStatus = 'Full-time';
  String _selectedSourceOfIncome = 'Employment';
  String _selectedMNO = 'Mascom- MyZaka';

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

  // Documents
  File? _idDocument;
  File? _proofOfAddressDocument;
  File? _proofOfEmploymentDocument;

  // Hardcoded
  final String _branchCode = "HRE001";
  final String _preFunding = "1";

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
    _addressController.dispose();
    _physicalAddressController.dispose();
    _postalCodeController.dispose();
    _villageController.dispose();
    _villageTownCityController.dispose();
    _residentInController.dispose();
    _tinController.dispose();
    _phoneController.dispose();
    _faxController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    _natureOfBusinessController.dispose();
    _ibanController.dispose();
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
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep == 2 && !_validateStep3()) return;
    if (_currentStep == 4 && !_validateStep5()) return;

    if (_currentStep < 4) {
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
    if (_idNumberController.text.length != 9) {
      _showSnackBar('ID number must be exactly 9 digits');
      return false;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(_idNumberController.text)) {
      _showSnackBar('ID number must contain only numbers');
      return false;
    }
    if (!_isNewClient && _cdsNumberController.text.isEmpty) {
      _showSnackBar('Please enter CDS number for existing client');
      return false;
    }
    if (_selectedBrokerCode == null || _selectedBrokerCode!.isEmpty) {
      _showSnackBar('Please select a broker');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_addressController.text.isEmpty) {
      _showSnackBar('Please enter postal address');
      return false;
    }
    if (_villageTownCityController.text.isEmpty) {
      _showSnackBar('Please enter town or city');
      return false;
    }
    if (_residentInController.text.isEmpty) {
      _showSnackBar('Please enter place of residence');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (_emailController.text.isEmpty || _phoneController.text.isEmpty) {
      _showSnackBar('Please fill email and phone number');
      return false;
    }
    return true;
  }

  bool _validateStep5() {
    if (!_agreeToTerms) {
      _showSnackBar('Please agree to the Terms & Conditions');
      return false;
    }
    if (_isNewClient) {
      if (_idDocument == null) {
        _showSnackBar('Please upload ID document');
        return false;
      }
      if (_proofOfAddressDocument == null) {
        _showSnackBar('Please upload Proof of Address document');
        return false;
      }
      if (_proofOfEmploymentDocument == null) {
        _showSnackBar('Please upload Proof of Employment/Income document');
        return false;
      }
    }
    return true;
  }

  Future<void> _submitForm() async {
    try {
      final documents = await _prepareDocuments();

      final now = DateTime.now();
      final agreementDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final payload = {
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
        "Country": _selectedCountry,
        "Address1": _addressController.text,
        "PostalAddress": _postalCodeController.text,
        "City": _physicalAddressController.text,
        "Village": _villageController.text,
        "Town": _villageTownCityController.text,
        "ResidesIn": _residentInController.text,
        "myRegion": "",
        "myDistrict": "",
        "Landmark": "",
        "Tel": _phoneController.text,
        "MNO": _getMNOCode(_selectedMNO),
        "Fax": _faxController.text,
        "Email": _emailController.text,
        "Occupation": _occupationController.text,
        "EmploymentStatus": _selectedEmploymentStatus,
        "EmployerName": "",
        "EmployerAddress": "",
        "Designation": "",
        "NatureOfBusiness": _natureOfBusinessController.text,
        "sourceofIncome": _selectedSourceOfIncome,
        "TIN": _tinController.text,
        "MaritalStatus": "",
        "IBAN": _ibanController.text,
        "BankDiv": _selectedBankCode ?? '',        // bank code from API
        "BankBranch": _selectedBranchCode ?? '',   // branch code from API
        "SwiftCode": _selectedBankSwiftCode ?? '', // auto-filled from bank API
        "InvestorType": "",
        "AccountType": _selectedAccountType,
        "accountClass": "",
        "branchcode": _branchCode,
        "brokerlink": "0",
        "BrokerCode": _selectedBrokerCode,
        "PreFunding": _preFunding,
        "cdsnumber": _isNewClient ? "" : _cdsNumberController.text,
        "clientType": _isNewClient ? "new" : "existing",
        "PrincipalOfficer": "",
        "myJointName": "",
        "Payee2": "",
        "AgreementDate": agreementDate,
        "CreatedBy": "MOBILE",
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
    List<String> stepNames = ['Basic Info', 'Address', 'Contact', 'Banking', 'Final'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Row(
              children: [
                _buildStepCircle(index, stepNames[index]),
                if (index < 4) _buildStepLine(),
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
                          _currentStep == 4 ? 'Submit' : 'Next',
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
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      case 4:
        return _buildStep5();
      default:
        return _buildStep1();
    }
  }

  // ── Step 1: Basic Info (KYC) ───────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClientTypeToggle(),
          const SizedBox(height: 15),
          if (!_isNewClient) ...[
            _buildLabelWithField('CDS Number *',
                _buildTextField('Enter CDS number', _cdsNumberController)),
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
                Container(
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
                    controller: _idNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 9,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9)
                    ],
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '9-digit ID',
                      hintStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 15),
          _buildLabelWithField(
            'Account Type',
            Container(
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
                  value: _selectedAccountType,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  icon:
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
                  items: const [
                    DropdownMenuItem(value: 'I', child: Text('Individual')),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedAccountType = val!),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Address ────────────────────────────────────────────────────────
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
          Row(children: [
            Expanded(
                child: _buildLabelWithField(
                    'Postal Code',
                    _buildTextField(
                        'Enter postal code', _postalCodeController))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildLabelWithField('Village',
                    _buildTextField('Enter village', _villageController))),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(
                child: _buildLabelWithField(
                    'Town / City *',
                    _buildTextField(
                        'Enter town or city', _villageTownCityController))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildLabelWithField(
                    'Resides In *',
                    _buildTextField(
                        'e.g. Gaborone', _residentInController))),
          ]),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Country *',
              _buildDropdownField(
                  'Country',
                  _selectedCountry,
                  ['Botswana', 'Other'],
                      (val) => setState(() => _selectedCountry = val!))),
          const SizedBox(height: 15),
          _buildLabelWithField('TIN / Tax Code',
              _buildTextField('Enter TIN number', _tinController)),
        ],
      ),
    );
  }

  // ── Step 3: Contact & Work ─────────────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelWithField(
            'Mobile Wallet Provider *',
            _buildDropdownField(
              'Select MNO',
              _selectedMNO,
              ['Mascom- MyZaka', 'Orange Money', 'BTC Mobile Money/ Smega'],
                  (val) => setState(() => _selectedMNO = val!),
            ),
          ),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Mobile Number *',
              _buildTextField('Enter phone number', _phoneController,
                  keyboardType: TextInputType.phone)),
          const SizedBox(height: 15),
          _buildLabelWithField(
              'Email *',
              _buildTextField('Enter email address', _emailController,
                  keyboardType: TextInputType.emailAddress)),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(
                child: _buildLabelWithField(
                    'Employment Status *',
                    _buildDropdownField(
                        'Employment Status',
                        _selectedEmploymentStatus,
                        [
                          'Student',
                          'Employed',
                          'Unemployed'
                        ],
                            (val) => setState(
                                () => _selectedEmploymentStatus = val!)))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildLabelWithField(
                    'Occupation',
                    _buildTextField(
                        'Enter occupation', _occupationController))),
          ]),
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

  // ── Step 4: Banking ────────────────────────────────────────────────────────
  Widget _buildStep4() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Account Number
          _buildLabelWithField(
              'Account Number',
              _buildTextField('Enter account number', _ibanController,
                  keyboardType: TextInputType.number)),
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
          if (_isNewClient) ...[
            const Text(
              'Attachments *',
              style: TextStyle(
                  color: Color(0xFF6B5D4F),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildDocumentUploadField(
                '1. Certified Copy of National Identity Card',
                _idDocument,
                'ID'),
            const SizedBox(height: 15),
            _buildDocumentUploadField(
                '2. Proof of Address', _proofOfAddressDocument, 'ProofOfAddress'),
            const SizedBox(height: 15),
            _buildDocumentUploadField(
                '3. Proof of Source of Income / Employment',
                _proofOfEmploymentDocument,
                'ProofOfEmployment'),
            const SizedBox(height: 25),
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
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
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