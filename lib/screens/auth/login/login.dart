import 'package:bse/contants/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../dashboard/dashboard.dart';
import '../forgot_password/forgot-password.dart';
import '../signup/signup_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please enter email and password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Authentication/Login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email': _emailController.text,
          'Password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['responseCode'] == 200) {
          final prefs = await SharedPreferences.getInstance();

          // ── Top-level profile fields ──────────────────────────────
          await prefs.setString('token',        responseData['token']       ?? '');
          await prefs.setString('username',     responseData['username']    ?? '');
          await prefs.setString('email',        responseData['email']       ?? '');
          await prefs.setString('fullName',     responseData['fullName']    ?? '');
          await prefs.setString('userId',       responseData['userId']?.toString() ?? '');
          await prefs.setString('phoneNumber',  responseData['phoneNumber'] ?? '');
          await prefs.setString('cdsNumber',    responseData['cdsNumber']   ?? '');
          await prefs.setString('status',       responseData['status']      ?? '');
          await prefs.setString('lastLoginDate', responseData['lastLoginDate'] ?? '');
          await prefs.setString('dateCreated',   responseData['dateCreated']   ?? '');

          // ── Personal / KYC fields ─────────────────────────────────
          await prefs.setString('title',         responseData['title']         ?? '');
          await prefs.setString('forenames',     responseData['forenames']     ?? '');
          await prefs.setString('middlename',    responseData['middlename']    ?? '');
          await prefs.setString('surname',       responseData['surname']       ?? '');
          await prefs.setString('gender',        responseData['gender']        ?? '');
          await prefs.setString('dob',           responseData['dob']           ?? '');
          await prefs.setString('nationality',   responseData['nationality']   ?? '');
          await prefs.setString('idType',        responseData['idType']        ?? '');
          await prefs.setString('idNumber',      responseData['idNumber']      ?? '');
          await prefs.setString('placeOfBirth',  responseData['placeOfBirth']  ?? '');
          await prefs.setString('maritalStatus', responseData['maritalStatus'] ?? '');

          // ── Address ───────────────────────────────────────────────
          await prefs.setString('address1', responseData['address1'] ?? '');
          await prefs.setString('address2', responseData['address2'] ?? '');
          await prefs.setString('address3', responseData['address3'] ?? '');
          await prefs.setString('address4', responseData['address4'] ?? '');
          await prefs.setString('city',     responseData['city']     ?? '');
          await prefs.setString('country',  responseData['country']  ?? '');
          await prefs.setString('postCode', responseData['postCode'] ?? '');

          // ── Employment / financial ────────────────────────────────
          await prefs.setString('occupation',       responseData['occupation']       ?? '');
          await prefs.setString('employmentStatus', responseData['employmentStatus'] ?? '');
          await prefs.setString('employerName',     responseData['employerName']     ?? '');
          await prefs.setString('industry',         responseData['industry']         ?? '');
          await prefs.setString('sourceOfIncome',   responseData['sourceOfIncome']   ?? '');
          await prefs.setString('tin',              responseData['tin']              ?? '');
          await prefs.setBool('taxExempt',          responseData['taxExempt']        ?? false);

          // ── Banking / settlement ──────────────────────────────────
          await prefs.setString('dividendBank',       responseData['dividendBank']       ?? '');
          await prefs.setString('dividendBranch',     responseData['dividendBranch']     ?? '');
          await prefs.setString('dividendAccountNo',  responseData['dividendAccountNo']  ?? '');
          await prefs.setString('cashAccountNo',      responseData['cashAccountNo']      ?? '');
          await prefs.setString('iban',               responseData['iban']               ?? '');
          await prefs.setString('mobileMoneyProvider', responseData['mobileMoneyProvider'] ?? '');
          await prefs.setString('mobileMoneyNumber',   responseData['mobileMoneyNumber']   ?? '');

          // ── Trading ───────────────────────────────────────────────
          await prefs.setString('accountType',         responseData['accountType']         ?? '');
          await prefs.setString('tradingStatus',        responseData['tradingStatus']        ?? '');
          await prefs.setString('tradingAccountNumber', responseData['tradingAccountNumber'] ?? '');
          await prefs.setString('csdAccountNumber',     responseData['csdAccountNumber']     ?? '');

          // ── Brokers: save full list + extract active broker fields ─
          final List<dynamic> brokers = responseData['brokers'] ?? [];

          // Store the full list as a JSON string for use anywhere in the app
          await prefs.setString('brokersList', jsonEncode(brokers));

          // Find the first ACTIVE broker; fallback to first in list
          final activeBroker = brokers.firstWhere(
                (b) => (b['status'] ?? '').toString().toUpperCase() == 'ACTIVE',
            orElse: () => brokers.isNotEmpty ? brokers.first : null,
          );

          await prefs.setString('BrokerCode', activeBroker?['brokerCode'] ?? '');
          await prefs.setString('CDSAccount', activeBroker?['CDSAccount'] ?? '');
          await prefs.setString('BrokerName', activeBroker?['brokerName'] ?? '');

          // ── Navigate or prompt password change ────────────────────
          if (responseData['requirePasswordChange'] == true) {
            _showPasswordChangeDialog(responseData['email']);
          } else {
            _showSnackBar('Login successful');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            }
          }
        } else {
          _showSnackBar(
            responseData['responseMessage'] ?? 'Login failed',
            isError: true,
          );
        }
      } else {
        _showSnackBar('Login failed. Please try again.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPasswordChangeDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Change Password Required'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your password needs to be changed before you can continue.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B5D4F)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  hintText: 'Enter your current password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter new password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm new password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearPasswordFields();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handlePasswordChange(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A855),
            ),
            child: const Text(
              'Change Password',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePasswordChange(String email) async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match', isError: true);
      return;
    }

    if (_newPasswordController.text.isEmpty ||
        _oldPasswordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Authentication/SetPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email': email,
          'TempPassword': _oldPasswordController.text,
          'NewPassword': _newPasswordController.text,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['responseCode'] == 200) {
          _showSnackBar('Password changed successfully');
          _clearPasswordFields();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        } else {
          _showSnackBar(
            responseData['responseMessage'] ?? 'Password change failed',
            isError: true,
          );
        }
      } else {
        _showSnackBar('Failed to change password', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearPasswordFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _handleSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _handleForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
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
            colors: [
              Color(0xFFFFF8DC),
              Color(0xFFFFF4D6),
              Color(0xFFFFEFCC),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  width: 120,
                  height: 120,
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
                  padding: const EdgeInsets.all(16),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),

                const SizedBox(height: 40),

                // Login Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF0).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE8D7B8),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C1810),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 30),

                      // Email TextField
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password TextField
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Remember me and Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey[400]!,
                                    width: 1.5,
                                  ),
                                  fillColor: WidgetStateProperty.resolveWith((
                                      states,
                                      ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return const Color(0xFFD4A855);
                                    }
                                    return Colors.transparent;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  color: Color(0xFF6B5D4F),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _handleForgotPassword,
                            child: const Text(
                              'Forgot Password ?',
                              style: TextStyle(
                                color: Color(0xFFD4A855),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A855),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                            : const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider with text
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: const Color(0xFFD4A855).withOpacity(0.5),
                              thickness: 1,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Color(0xFF6B5D4F),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: const Color(0xFFD4A855).withOpacity(0.5),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sign Up Button
                      GestureDetector(
                        onTap: _handleSignUp,
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFFD4A855),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}