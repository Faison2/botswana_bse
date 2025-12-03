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
  bool _obscurePassword = true;

  // Form controllers - CLEARED hardcoded data, only placeholders remain
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  //final _passwordController = TextEditingController();

  // Step 2 & 3 controllers - CLEARED hardcoded data
  final _dobController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _tinController = TextEditingController();
  final _regionController = TextEditingController();
  final _districtController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _occupationController = TextEditingController();
  final _designationController = TextEditingController();
  final _employerNameController = TextEditingController();
  final _employerAddressController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bankDivisionController = TextEditingController();
  final _bankBranchController = TextEditingController();
  final _swiftCodeController = TextEditingController();
  final _jointNameController = TextEditingController();
  final _payee2Controller = TextEditingController();
  final _add4Controller = TextEditingController();
  final _add5Controller = TextEditingController();
  final _idExpiryDateController = TextEditingController();
  final _agreementDateController = TextEditingController();

  // Dropdown values
  String _selectedCountryCode = '+255';
  String _selectedTitle = 'Mr.';
  String _selectedGender = 'Male';
  String _selectedIdType = 'National Id';
  String _selectedMaritalStatus = 'Single';
  String _selectedSourceOfIncome = 'Employment';
  String _selectedEmploymentStatus = 'Full-time';
  String _selectedNationality = 'Zimbabwean';
  String _selectedCountry = 'Zimbabwe';
  String _selectedAccountClass = 'Local Bank';
  String _selectedAccountType = 'I';
  String _selectedInvestorType = 'Local';
  String _selectedPrincipalOfficer = 'Sarah Johnson';

  // Hardcoded values that don't need user input
  final String _branchCode = "HRE001";
  final String _cdsNumber = "";
  final String _brokerLink = "0";
  final String _preFunding = "1";

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    // All hardcoded data has been removed
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
   // _passwordController.dispose();
    _dobController.dispose();
    _birthPlaceController.dispose();
    _tinController.dispose();
    _regionController.dispose();
    _districtController.dispose();
    _landmarkController.dispose();
    _occupationController.dispose();
    _designationController.dispose();
    _employerNameController.dispose();
    _employerAddressController.dispose();
    _monthlyIncomeController.dispose();
    _ibanController.dispose();
    _bankDivisionController.dispose();
    _bankBranchController.dispose();
    _swiftCodeController.dispose();
    _jointNameController.dispose();
    _payee2Controller.dispose();
    _add4Controller.dispose();
    _add5Controller.dispose();
    _idExpiryDateController.dispose();
    _agreementDateController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep == 2 && !_validateStep3()) return;

    if (_currentStep < 2) {
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
        _phoneController.text.isEmpty
        //_passwordController.text.isEmpty
    ) {
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

  bool _validateStep3() {
    if (!_agreeToTerms) {
      _showSnackBar('Please agree to the Terms & Conditions');
      return false;
    }
    return true;
  }

  Future<void> _submitForm() async {
    try {
      // Complete payload with ALL fields from the API body
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

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFFD4A855)),
              SizedBox(width: 20),
              Text('Submitting to API...'),
            ],
          ),
        ),
      );

      final response = await http.post(
        Uri.parse('http://192.168.3.201/MainAPI/Home/AccountOpening'),
        headers: {
          'Content-Type': 'application/json',
          // Authorization header removed as requested
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));

      // Hide loading dialog
      Navigator.of(context).pop();

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle both array and object responses
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(0, 'Personal'),
          _buildStepLine(),
          _buildStepCircle(1, 'Details'),
          _buildStepLine(),
          _buildStepCircle(2, 'Finish'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepNumber, String label) {
    bool isActive = _currentStep == stepNumber;
    bool isCompleted = _currentStep > stepNumber;

    return Column(
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
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFFD4A855) : Colors.grey[600],
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
              const SizedBox(height: 20),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 15),
              const Text(
                'Account Creation',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C1810),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _buildStepIndicator(),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
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
                          _currentStep == 0 ? 'Back' : 'Previous',
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
                          _currentStep == 2 ? 'Submit' : 'Next',
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
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Title',
          style: TextStyle(
            color: Color(0xFF6B5D4F),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                'Title',
                _selectedTitle,
                ['Mr.', 'Mrs.', 'Ms.', 'Dr.'],
                    (val) {
                  setState(() => _selectedTitle = val!);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDropdownField(
                'Gender',
                _selectedGender,
                ['Male', 'Female'],
                    (val) {
                  setState(() => _selectedGender = val!);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildLabel('First Name *'),
        _buildTextField('Enter your first name', _firstNameController),
        const SizedBox(height: 15),
        _buildLabel('Last Name *'),
        _buildTextField('Enter your last name', _lastNameController),
        const SizedBox(height: 15),
        _buildLabel('Email *'),
        _buildTextField(
          'Enter your email address',
          _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),
        _buildLabel('ID Number *'),
        _buildTextField('Enter your ID number', _idNumberController),
        const SizedBox(height: 15),
        _buildLabel('Address *'),
        _buildTextField('Enter your address', _addressController),
        const SizedBox(height: 15),
        _buildLabel('Phone Number *'),
        _buildPhoneField(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Date of Birth *'),
        _buildTextField(
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
        ),
        const SizedBox(height: 15),
        _buildLabel('Birth Place'),
        _buildTextField('Enter your birth place', _birthPlaceController),
        const SizedBox(height: 15),
        _buildLabel('TIN Number'),
        _buildTextField('Enter your TIN number', _tinController),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('ID Type'),
                  _buildDropdownField(
                    'ID Type',
                    _selectedIdType,
                    ['National Id', 'Passport', 'Drivers License'],
                        (val) {
                      setState(() => _selectedIdType = val!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Marital Status'),
                  _buildDropdownField(
                    'Marital Status',
                    _selectedMaritalStatus,
                    ['Single', 'Married', 'Divorced', 'Widowed'],
                        (val) {
                      setState(() => _selectedMaritalStatus = val!);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Nationality'),
                  _buildDropdownField(
                    'Nationality',
                    _selectedNationality,
                    ['Zimbabwean', 'Other'],
                        (val) {
                      setState(() => _selectedNationality = val!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Country'),
                  _buildDropdownField(
                    'Country',
                    _selectedCountry,
                    ['Zimbabwe', 'Other'],
                        (val) {
                      setState(() => _selectedCountry = val!);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildLabel('Region'),
        _buildTextField('Enter your region', _regionController),
        const SizedBox(height: 15),
        _buildLabel('District'),
        _buildTextField('Enter your district', _districtController),
        const SizedBox(height: 15),
        _buildLabel('Add4 (Area)'),
        _buildTextField('Enter your area', _add4Controller),
        const SizedBox(height: 15),
        _buildLabel('Add5 (City)'),
        _buildTextField('Enter your city', _add5Controller),
        const SizedBox(height: 15),
        _buildLabel('Landmark'),
        _buildTextField('Enter nearby landmark', _landmarkController),
        const SizedBox(height: 15),
        _buildLabel('Occupation'),
        _buildTextField('Enter your occupation', _occupationController),
        const SizedBox(height: 15),
        _buildLabel('Designation'),
        _buildTextField('Enter your designation', _designationController),
        const SizedBox(height: 15),
        _buildLabel('Monthly Income'),
        _buildTextField('Enter monthly income', _monthlyIncomeController, keyboardType: TextInputType.number),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Source of Income'),
                  _buildDropdownField(
                    'Source of Income',
                    _selectedSourceOfIncome,
                    ['Employment', 'Business', 'Investments', 'Other'],
                        (val) {
                      setState(() => _selectedSourceOfIncome = val!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Employment Status'),
                  _buildDropdownField(
                    'Employment Status',
                    _selectedEmploymentStatus,
                    ['Full-time', 'Part-time', 'Self-employed', 'Unemployed'],
                        (val) {
                      setState(() => _selectedEmploymentStatus = val!);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildLabel('Employer Name'),
        _buildTextField('Enter employer name', _employerNameController),
        const SizedBox(height: 15),
        _buildLabel('Employer Address'),
        _buildTextField('Enter employer address', _employerAddressController),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Account Class'),
                  _buildDropdownField(
                    'Account Class',
                    _selectedAccountClass,
                    ['Local Bank', 'International Bank'],
                        (val) {
                      setState(() => _selectedAccountClass = val!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Account Type'),
                  _buildDropdownField(
                    'Account Type',
                    _selectedAccountType,
                    ['I', 'C'],
                        (val) {
                      setState(() => _selectedAccountType = val!);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildLabel('IBAN Number'),
        _buildTextField('Enter IBAN number', _ibanController),
        const SizedBox(height: 15),
        _buildLabel('Bank Division'),
        _buildTextField('Enter bank division', _bankDivisionController),
        const SizedBox(height: 15),
        _buildLabel('Bank Branch'),
        _buildTextField('Enter bank branch', _bankBranchController),
        const SizedBox(height: 15),
        _buildLabel('Swift Code'),
        _buildTextField('Enter swift code', _swiftCodeController),
        const SizedBox(height: 15),
        _buildLabel('Joint Account Name'),
        _buildTextField('Enter joint account name', _jointNameController),
        const SizedBox(height: 15),
        _buildLabel('Payee 2'),
        _buildTextField('Enter payee 2 name', _payee2Controller),
        const SizedBox(height: 15),
        _buildLabel('ID Expiry Date'),
        _buildTextField(
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
        ),
        const SizedBox(height: 15),
        _buildLabel('Agreement Date'),
        _buildTextField(
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
        ),
        const SizedBox(height: 20),
        Row(
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
            const Text(
              'I agree to the ',
              style: TextStyle(
                color: Color(0xFF6B5D4F),
                fontSize: 13,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Show terms and conditions
              },
              child: const Text(
                'Terms & Conditions',
                style: TextStyle(
                  color: Color(0xFFD4A855),
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Please fill all required fields before submitting.',
          style: TextStyle(
            color: Color(0xFFD4A855),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B5D4F),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onTap: onTap,
        readOnly: onTap != null,
        style: const TextStyle(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D7B8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                  size: 20,
                ),
                items: ['+255', '+267', '+27', '+260', '+263'].map((String code) {
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(3),
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
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(code),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCountryCode = value!);
                },
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}