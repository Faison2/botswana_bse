import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _currentStep = 0;
  bool _agreeToTerms = false;

  // Step 1 controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2 controllers (Personal Details)
  final _dobController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _tinController = TextEditingController();
  final _occupationController = TextEditingController();
  final _designationController = TextEditingController();

  // Step 3 controllers (Location Details)
  final _regionController = TextEditingController();
  final _districtController = TextEditingController();
  final _add4Controller = TextEditingController();
  final _add5Controller = TextEditingController();
  final _landmarkController = TextEditingController();

  // Step 4 controllers (Employment & Income)
  final _employerNameController = TextEditingController();
  final _employerAddressController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();

  // Step 5 controllers (Bank Details)
  final _ibanController = TextEditingController();
  final _bankDivisionController = TextEditingController();
  final _bankBranchController = TextEditingController();
  final _swiftCodeController = TextEditingController();
  final _jointNameController = TextEditingController();
  final _payee2Controller = TextEditingController();

  // Step 6 controllers (Additional & Final)
  final _idExpiryDateController = TextEditingController();
  final _agreementDateController = TextEditingController();

  // Dropdown values
  String _selectedCountryCode = '+267'; // Botswana
  String _selectedTitle = 'Mr.';
  String _selectedGender = 'Male';
  String _selectedIdType = 'National Id';
  String _selectedMaritalStatus = 'Single';
  String _selectedSourceOfIncome = 'Employment';
  String _selectedEmploymentStatus = 'Full-time';
  String _selectedNationality = 'Botswana';
  String _selectedCountry = 'Botswana';
  String _selectedAccountClass = 'Local Bank';
  String _selectedAccountType = 'Individual';
  String _selectedInvestorType = 'Local';
  String _selectedPrincipalOfficer = 'Sarah Johnson';

  // Hardcoded values
  final String _branchCode = "HRE001";
  final String _cdsNumber = "";
  final String _brokerLink = "0";
  final String _preFunding = "1";

  @override
  void dispose() {
    // Dispose all controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _birthPlaceController.dispose();
    _tinController.dispose();
    _occupationController.dispose();
    _designationController.dispose();
    _regionController.dispose();
    _districtController.dispose();
    _add4Controller.dispose();
    _add5Controller.dispose();
    _landmarkController.dispose();
    _employerNameController.dispose();
    _employerAddressController.dispose();
    _monthlyIncomeController.dispose();
    _ibanController.dispose();
    _bankDivisionController.dispose();
    _bankBranchController.dispose();
    _swiftCodeController.dispose();
    _jointNameController.dispose();
    _payee2Controller.dispose();
    _idExpiryDateController.dispose();
    _agreementDateController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep == 5 && !_validateStep6()) return;

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
        _emailController.text.isEmpty ||
        _idNumberController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showSnackBar('Please fill all required fields');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_dobController.text.isEmpty) {
      _showSnackBar('Please enter your date of birth');
      return false;
    }
    return true;
  }

  bool _validateStep6() {
    if (!_agreeToTerms) {
      _showSnackBar('Please agree to the Terms & Conditions');
      return false;
    }
    return true;
  }

  Future<void> _submitForm() async {
    try {
      final payload = {
        "Othernames": _firstNameController.text,
        "Surname": _lastNameController.text,
        "accountClass": _selectedAccountClass,
        "AccountType": _selectedAccountType,
        "idtype": _selectedIdType,
        "myIdentification": _idNumberController.text,
        "myJointName": _jointNameController.text,
        "myTitle": _selectedTitle,
        "DOB": _dobController.text,
        "Gender": _selectedGender,
        "PrincipalOfficer": _selectedPrincipalOfficer,
        "Nationality": _selectedNationality,
        "Country": _selectedCountry,
        "sourceofIncome": _selectedSourceOfIncome,
        "Address1": _addressController.text,
        "Tel": _selectedCountryCode + _phoneController.text,
        "Email": _emailController.text,
        "Payee2": _payee2Controller.text,
        "IBAN": _ibanController.text,
        "BankDiv": _bankDivisionController.text,
        "BankBranch": _bankBranchController.text,
        "SwiftCode": _swiftCodeController.text,
        "BirthPlace": _birthPlaceController.text,
        "MiddleNames": _firstNameController.text,
        "myRegion": _regionController.text,
        "myDistrict": _districtController.text,
        "Add4": _add4Controller.text,
        "Add5": _add5Controller.text,
        "InvestorType": _selectedInvestorType,
        "Landmark": _landmarkController.text,
        "MaritalStatus": _selectedMaritalStatus,
        "Occupation": _occupationController.text,
        "Designation": _designationController.text,
        "branchcode": _branchCode,
        "cdsnumber": _cdsNumber,
        "brokerlink": _brokerLink,
        "PreFunding": _preFunding,
        "TIN": _tinController.text,
        "MonthlyIncome": _monthlyIncomeController.text,
        "EmployerName": _employerNameController.text,
        "EmployerAddress": _employerAddressController.text,
        "EmploymentStatus": _selectedEmploymentStatus,
        "IDExpiryDate": _idExpiryDateController.text,
        "AgreementDate": _agreementDateController.text
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
        Uri.parse('http://192.168.3.201/MainAPI/Home/AccountOpening'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      Navigator.of(context).pop();

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is List) {
          if (responseData.isNotEmpty && responseData[0]['responseCode'] == 0) {
            _showSuccessDialog(responseData[0]['responseMessage'] ?? 'Account Submitted Successfully');
          } else if (responseData.isNotEmpty) {
            _showErrorDialog(responseData[0]['responseMessage'] ?? 'Unknown error occurred');
          } else {
            _showErrorDialog('Empty response from server');
          }
        } else if (responseData is Map) {
          if (responseData.containsKey('message')) {
            if (responseData['status'] == 401) {
              _showErrorDialog('Unauthorized: ${responseData['message']}');
            } else {
              _showErrorDialog(responseData['message']);
            }
          } else if (responseData.containsKey('responseMessage')) {
            _showSuccessDialog(responseData['responseMessage']);
          } else {
            _showErrorDialog('Unexpected response format: ${response.body}');
          }
        } else {
          _showErrorDialog('Invalid response format: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        _showErrorDialog('Unauthorized access (401).');
      } else if (response.statusCode == 500) {
        _showErrorDialog('Server error (500). Please try again later.');
      } else {
        _showErrorDialog('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorDialog('Network error: $e');
    } on Exception catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorDialog('Error: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success', style: TextStyle(color: Colors.green)),
          ],
        ),
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
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error', style: TextStyle(color: Colors.red)),
          ],
        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFD4A855),
      ),
    );
  }

  Widget _buildStepIndicator() {
    List<String> stepNames = ['Basic Info', 'Personal', 'Location', 'Work', 'Bank', 'Final'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Row(
              children: [
                _buildStepCircle(index, stepNames[index]),
                if (index < 5) _buildStepLine(),
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
      onTap: () {
        setState(() => _currentStep = stepNumber);
      },
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
            width: 50, // Fixed width for label
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? const Color(0xFFD4A855) : Colors.grey[600],
                fontSize: 9, // Smaller font size
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
      width: 20, // Reduced from 30
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.grey[300],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFF8DC),
              const Color(0xFFFFF4D6),
              const Color(0xFFFFEFCC),
            ],
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
                      spreadRadius: 2,
                    ),
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
                  color: Color(0xFF2C1810),
                ),
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
                        spreadRadius: 2,
                      ),
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
                          side: const BorderSide(
                            color: Color(0xFFD4A855),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentStep == 0 ? 'Cancel' : 'Previous',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD4A855),
                          ),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentStep == 5 ? 'Submit' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
      case 5:
        return _buildStep6();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildLabelWithField('Title', _buildDropdownField(
                  'Title',
                  _selectedTitle,
                  ['Mr.', 'Mrs.', 'Ms.', 'Dr.'],
                      (val) {
                    setState(() => _selectedTitle = val!);
                  },
                )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLabelWithField('Gender', _buildDropdownField(
                  'Gender',
                  _selectedGender,
                  ['Male', 'Female'],
                      (val) {
                    setState(() => _selectedGender = val!);
                  },
                )),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildLabelWithField('First Name *', _buildTextField('Enter first name', _firstNameController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Last Name *', _buildTextField('Enter last name', _lastNameController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Email *', _buildTextField('Enter email address', _emailController, keyboardType: TextInputType.emailAddress)),
          const SizedBox(height: 15),
          _buildLabelWithField('ID Number *', _buildTextField('Enter ID number', _idNumberController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Address *', _buildTextField('Enter address', _addressController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Phone Number *', _buildPhoneField()),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Personal Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C1810),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLabelWithField('Date of Birth *', _buildTextField(
            'YYYY-MM-DD',
            _dobController,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                _dobController.text = formattedDate;
              }
            },
          )),
          const SizedBox(height: 15),
          _buildLabelWithField('Birth Place', _buildTextField('Enter birth place', _birthPlaceController)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildLabelWithField('ID Type', _buildDropdownField(
                  'ID Type',
                  _selectedIdType,
                  ['National Id', 'Passport', 'Drivers License'],
                      (val) {
                    setState(() => _selectedIdType = val!);
                  },
                )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLabelWithField('Marital Status', _buildDropdownField(
                  'Marital Status',
                  _selectedMaritalStatus,
                  ['Single', 'Married', 'Divorced', 'Widowed'],
                      (val) {
                    setState(() => _selectedMaritalStatus = val!);
                  },
                )),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildLabelWithField('Nationality', _buildDropdownField(
                  'Nationality',
                  _selectedNationality,
                  ['Botswana', 'Other'],
                      (val) {
                    setState(() => _selectedNationality = val!);
                  },
                )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLabelWithField('Country', _buildDropdownField(
                  'Country',
                  _selectedCountry,
                  ['Botswana', 'Other'],
                      (val) {
                    setState(() => _selectedCountry = val!);
                  },
                )),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildLabelWithField('TIN Number', _buildTextField('Enter TIN number', _tinController)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildLabelWithField('Occupation', _buildTextField('Enter occupation', _occupationController)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLabelWithField('Designation', _buildTextField('Enter designation', _designationController)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Location Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C1810),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildLabelWithField('Region', _buildTextField('Enter region', _regionController)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLabelWithField('District', _buildTextField('Enter district', _districtController)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildLabelWithField('Area (Add4)', _buildTextField('Enter area', _add4Controller)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLabelWithField('City (Add5)', _buildTextField('Enter city', _add5Controller)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildLabelWithField('Landmark', _buildTextField('Enter nearby landmark', _landmarkController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Investor Type', _buildDropdownField(
            'Investor Type',
            _selectedInvestorType,
            ['Local', 'International'],
                (val) {
              setState(() => _selectedInvestorType = val!);
            },
          )),
          const SizedBox(height: 15),
          _buildLabelWithField('Principal Officer', _buildDropdownField(
            'Principal Officer',
            _selectedPrincipalOfficer,
            ['Sarah Johnson', 'John Doe', 'Jane Smith'],
                (val) {
              setState(() => _selectedPrincipalOfficer = val!);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Employment & Income',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C1810),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildLabelWithField('Source of Income', _buildDropdownField(
                  'Source of Income',
                  _selectedSourceOfIncome,
                  ['Employment', 'Business', 'Investments', 'Other'],
                      (val) {
                    setState(() => _selectedSourceOfIncome = val!);
                  },
                )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLabelWithField('Employment Status', _buildDropdownField(
                  'Employment Status',
                  _selectedEmploymentStatus,
                  ['Full-time', 'Part-time', 'Self-employed', 'Unemployed'],
                      (val) {
                    setState(() => _selectedEmploymentStatus = val!);
                  },
                )),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildLabelWithField('Employer Name', _buildTextField('Enter employer name', _employerNameController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Employer Address', _buildTextField('Enter employer address', _employerAddressController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Monthly Income', _buildTextField('Enter monthly income', _monthlyIncomeController, keyboardType: TextInputType.number)),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Bank Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C1810),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildLabelWithField('Account Class', _buildDropdownField(
                  'Account Class',
                  _selectedAccountClass,
                  ['Local Bank', 'International Bank'],
                      (val) {
                    setState(() => _selectedAccountClass = val!);
                  },
                )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLabelWithField('Account Type', _buildDropdownField(
                  'Account Type',
                  _selectedAccountType,
                  ['Individual', 'Corporate'],
                      (val) {
                    setState(() => _selectedAccountType = val!);
                  },
                )),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildLabelWithField('IBAN Number', _buildTextField('Enter IBAN number', _ibanController)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildLabelWithField('Bank Division', _buildTextField('Enter bank division', _bankDivisionController)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLabelWithField('Bank Branch', _buildTextField('Enter bank branch', _bankBranchController)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildLabelWithField('Swift Code', _buildTextField('Enter swift code', _swiftCodeController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Joint Account Name', _buildTextField('Enter joint account name', _jointNameController)),
          const SizedBox(height: 15),
          _buildLabelWithField('Payee 2', _buildTextField('Enter payee 2 name', _payee2Controller)),
        ],
      ),
    );
  }

  Widget _buildStep6() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Final Step',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C1810),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildLabelWithField('ID Expiry Date', _buildTextField(
                  'YYYY-MM-DD',
                  _idExpiryDateController,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2050),
                    );
                    if (date != null) {
                      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      _idExpiryDateController.text = formattedDate;
                    }
                  },
                )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLabelWithField('Agreement Date', _buildTextField(
                  'YYYY-MM-DD',
                  _agreementDateController,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      _agreementDateController.text = formattedDate;
                    }
                  },
                )),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() => _agreeToTerms = value ?? false);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(
                    color: Colors.grey[400]!,
                    width: 1.5,
                  ),
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFFD4A855);
                    }
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
                          color: Color(0xFF6B5D4F),
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                          color: Color(0xFFD4A855),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                        text: ' and confirm that all information provided is accurate.',
                        style: TextStyle(
                          color: Color(0xFF6B5D4F),
                          fontSize: 13,
                        ),
                      ),
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
                    style: TextStyle(
                      color: Color(0xFF6B5D4F),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelWithField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 4),
        field,
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF6B5D4F),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField(
      String hint,
      TextEditingController controller, {
        TextInputType? keyboardType,
        VoidCallback? onTap,
      }) {
    return Container(
      height: 50, // Increased from 45 for better spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
      String hint,
      String value,
      List<String> items,
      Function(String?) onChanged,
      ) {
    return Container(
      height: 50, // Increased from 45 for better spacing
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      height: 50, // Increased from 45 for better spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botswana Flag
                  Container(
                    width: 24,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                            ),
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedCountryCode,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(
              color: Color(0xFFE8D7B8),
              width: 1,
              thickness: 1,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}