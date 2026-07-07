import 'package:bse/contants/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../dashboard/dashboard.dart';
import '../forgot_password/forgot-password.dart';
import '../signup/signup_home.dart';

// ── BSE Brand Palette ──────────────────────────────────────────
class BSEColors {
  static const marigold = Color(0xFFC6912D);
  static const marigoldDark = Color(0xFFA97620);
  static const marigoldLight = Color(0xFFE8C88A);
  static const ink = Color(0xFF1A1A1A);
  static const charcoal = Color(0xFF3A3A3A);
  static const muted = Color(0xFF8A8A8A);
  static const surface = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFFAFAF8);
}

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
          await prefs.setString('token',         responseData['token']         ?? '');
          await prefs.setString('username',      responseData['username']      ?? '');
          await prefs.setString('email',         responseData['email']         ?? '');
          await prefs.setString('fullName',      responseData['fullName']      ?? '');
          await prefs.setString('userId',        responseData['userId']?.toString() ?? '');
          await prefs.setString('phoneNumber',   responseData['phoneNumber']   ?? '');
          await prefs.setString('cdsNumber',     responseData['cdsNumber']     ?? '');
          await prefs.setString('status',        responseData['status']        ?? '');
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
          await prefs.setString('dividendBank',        responseData['dividendBank']        ?? '');
          await prefs.setString('dividendBranch',      responseData['dividendBranch']      ?? '');
          await prefs.setString('dividendAccountNo',   responseData['dividendAccountNo']   ?? '');
          await prefs.setString('cashAccountNo',       responseData['cashAccountNo']       ?? '');
          await prefs.setString('iban',                responseData['iban']                ?? '');
          await prefs.setString('mobileMoneyProvider', responseData['mobileMoneyProvider'] ?? '');
          await prefs.setString('mobileMoneyNumber',   responseData['mobileMoneyNumber']   ?? '');

          // ── Trading ───────────────────────────────────────────────
          await prefs.setString('accountType',          responseData['accountType']          ?? '');
          await prefs.setString('tradingStatus',        responseData['tradingStatus']        ?? '');
          await prefs.setString('tradingAccountNumber', responseData['tradingAccountNumber'] ?? '');
          await prefs.setString('csdAccountNumber',     responseData['csdAccountNumber']     ?? '');

          // ── Brokers: save full list + each active broker individually ─
          final List<dynamic> brokers = responseData['brokers'] ?? [];

          await prefs.setString('brokersList', jsonEncode(brokers));

          final List<dynamic> activeBrokers = brokers
              .where((b) => (b['status'] ?? '').toString().toUpperCase() == 'ACTIVE')
              .toList();

          await prefs.setInt('activeBrokersCount', activeBrokers.length);

          for (int i = 0; i < activeBrokers.length; i++) {
            final broker = activeBrokers[i];
            await prefs.setString('broker_${i}_BrokerCode', broker['brokerCode'] ?? '');
            await prefs.setString('broker_${i}_CDSAccount', broker['CDSAccount'] ?? '');
            await prefs.setString('broker_${i}_BrokerName', broker['brokerName'] ?? '');
            await prefs.setString('broker_${i}_Status',     broker['status']     ?? '');
          }

          if (activeBrokers.isNotEmpty) {
            await prefs.setString('BrokerCode', activeBrokers[0]['brokerCode'] ?? '');
            await prefs.setString('CDSAccount', activeBrokers[0]['CDSAccount'] ?? '');
            await prefs.setString('BrokerName', activeBrokers[0]['brokerName'] ?? '');
          }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: BSEColors.surface,
        title: const Text(
          'Change Password Required',
          style: TextStyle(color: BSEColors.ink, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your password needs to be changed before you can continue.',
                style: TextStyle(fontSize: 14, color: BSEColors.charcoal),
              ),
              const SizedBox(height: 20),
              _buildDialogField(_oldPasswordController, 'Current Password', 'Enter your current password'),
              const SizedBox(height: 16),
              _buildDialogField(_newPasswordController, 'New Password', 'Enter new password'),
              const SizedBox(height: 16),
              _buildDialogField(_confirmPasswordController, 'Confirm Password', 'Confirm new password'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearPasswordFields();
            },
            child: const Text('Cancel', style: TextStyle(color: BSEColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handlePasswordChange(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BSEColors.marigold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Change Password',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: BSEColors.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: BSEColors.muted),
        hintText: hint,
        filled: true,
        fillColor: BSEColors.canvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: BSEColors.marigold, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        backgroundColor: isError ? const Color(0xFFC0392B) : BSEColors.marigoldDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: BSEColors.muted.withOpacity(0.8), fontSize: 15),
      prefixIcon: Icon(icon, color: BSEColors.marigold, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: BSEColors.canvas,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEDEAE3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BSEColors.marigold, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BSEColors.canvas,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDF9F1),
              BSEColors.canvas,
              Color(0xFFF7F3EC),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),

                // ── Marigold accent bar + Logo ────────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: BSEColors.marigoldLight, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: BSEColors.marigold.withOpacity(0.18),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),

                const SizedBox(height: 16),

                Text(
                  'BOTSWANA STOCK EXCHANGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                    color: BSEColors.marigoldDark,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Login Card ─────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                  decoration: BoxDecoration(
                    color: BSEColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: BSEColors.ink.withOpacity(0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: BSEColors.ink,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Log in to manage your trading account',
                        style: TextStyle(fontSize: 13.5, color: BSEColors.muted),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 15.5, color: BSEColors.ink),
                        decoration: _fieldDecoration(
                          hint: 'Email address',
                          icon: Icons.mail_outline_rounded,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Password
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 15.5, color: BSEColors.ink),
                        decoration: _fieldDecoration(
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: BSEColors.muted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Remember me + Forgot Password
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
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  side: const BorderSide(
                                    color: BSEColors.muted,
                                    width: 1.4,
                                  ),
                                  fillColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return BSEColors.marigold;
                                    }
                                    return Colors.transparent;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember me',
                                style: TextStyle(color: BSEColors.charcoal, fontSize: 13.5),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _handleForgotPassword,
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: BSEColors.marigoldDark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      // Login Button — marigold gradient
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [BSEColors.marigold, BSEColors.marigoldDark],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: BSEColors.marigold.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _isLoading ? null : _handleLogin,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Divider with text
                      Row(
                        children: [
                          Expanded(child: Divider(color: BSEColors.marigoldLight, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              "Don't have an account?",
                              style: TextStyle(color: BSEColors.muted, fontSize: 13),
                            ),
                          ),
                          Expanded(child: Divider(color: BSEColors.marigoldLight, thickness: 1)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Sign Up
                      GestureDetector(
                        onTap: _handleSignUp,
                        child: const Text(
                          'Create an account',
                          style: TextStyle(
                            color: BSEColors.marigoldDark,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}