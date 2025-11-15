import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String _selectedAccountType = ''; // 'individual' or 'company'
  bool _hasCDSNumber = false;

  void _handleAccountTypeSelection(String type) {
    setState(() {
      _selectedAccountType = type;
    });
  }

  void _handleNext() {
    if (_selectedAccountType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an account type'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // TODO: Navigate to next signup step with selected account type and CDS info
    print('Account Type: $_selectedAccountType, Has CDS: $_hasCDSNumber');
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => SignUpDetailsScreen(
    //       accountType: _selectedAccountType,
    //       hasCDSNumber: _hasCDSNumber,
    //     ),
    //   ),
    // );
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
              const Color(0xFF2C1810),
              const Color(0xFF8B4513).withOpacity(0.6),
              const Color(0xFF654321).withOpacity(0.4),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'Account Creation',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // Subtitle
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Create an account or log in to explore about our app',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),

                // Question
                const Text(
                  'Whose Account Is This For',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Individual Option
                GestureDetector(
                  onTap: () => _handleAccountTypeSelection('individual'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedAccountType == 'individual'
                            ? Colors.amber
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: _selectedAccountType == 'individual'
                          ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: Container(
                            height: 180,
                            color: Colors.grey[100],
                            child: Center(
                              child: Image.asset(
                                'assets/individual.png', // You'll need to add this image
                                height: 150,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 100,
                                    color: Colors.grey[400],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedAccountType == 'individual'
                                ? Colors.amber
                                : Colors.grey[200],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Individual',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _selectedAccountType == 'individual'
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Company Option
                GestureDetector(
                  onTap: () => _handleAccountTypeSelection('company'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedAccountType == 'company'
                            ? Colors.amber
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: _selectedAccountType == 'company'
                          ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: Container(
                            height: 180,
                            color: Colors.grey[100],
                            child: Center(
                              child: Image.asset(
                                'assets/company.png', // You'll need to add this image
                                height: 150,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.business,
                                    size: 100,
                                    color: Colors.grey[400],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedAccountType == 'company'
                                ? Colors.amber
                                : Colors.grey[200],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Company',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _selectedAccountType == 'company'
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // CDS Number Checkbox
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _hasCDSNumber,
                          onChanged: (value) {
                            setState(() {
                              _hasCDSNumber = value ?? false;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                          fillColor: MaterialStateProperty.resolveWith(
                                (states) {
                              if (states.contains(MaterialState.selected)) {
                                return Colors.amber;
                              }
                              return Colors.transparent;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Do you have a CDS Number Already',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      // Back Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Colors.amber,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Next Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}