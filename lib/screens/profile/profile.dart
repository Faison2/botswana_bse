import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _errorMessage = '';

  String _userId = '';
  String _username = '';
  String _email = '';
  String _fullName = '';
  String _phoneNumber = '';
  String _cdsNumber = '';
  String _status = '';
  String _lastLoginDate = '';
  String _dateCreated = '';
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      setState(() => _token = token);

      if (token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No authentication token found. Please login again.';
        });
        return;
      }

      final response = await http
          .post(
        Uri.parse('http://192.168.3.201/MainAPI/Authentication/GetProfile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Token': token}),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['responseCode'] == 200) {
          setState(() {
            _userId = responseData['userId'] ?? '';
            _username = responseData['username'] ?? '';
            _email = responseData['email'] ?? '';
            _fullName = responseData['fullName'] ?? '';
            _phoneNumber = responseData['phoneNumber'] ?? '';
            _cdsNumber = responseData['cdsNumber'] ?? '';
            _status = responseData['status'] ?? '';
            _lastLoginDate = responseData['lastLoginDate'] ?? '';
            _dateCreated = responseData['dateCreated'] ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                responseData['responseMessage'] ?? 'Failed to load profile';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch profile. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF2C1810),
        Color(0xFF1A1A1A),
        Color(0xFF0D0D0D),
      ],
    )
        : const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF8E7),
        Color(0xFFF5F5F5),
        Color(0xFFFFFFFF),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                "My Profile",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: _loadProfileData,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.refresh, color: Colors.amber),
                  ),
                ),
              ],
              flexibleSpace: Container(
                decoration: BoxDecoration(gradient: bgGradient),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              )
                  : _errorMessage.isNotEmpty
                  ? _buildErrorUI(isDark)
                  : _buildProfileUI(isDark, themeProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorUI(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileUI(bool isDark, ThemeProvider themeProvider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 30),

          // Avatar
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFD4A855), Color(0xFFB8860B)],
              ),
            ),
            child: Center(
              child: Text(
                _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Name
          Text(
            _fullName,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _status == 'Active'
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _status == 'Active' ? Colors.green : Colors.red,
              ),
            ),
            child: Text(
              _status,
              style: TextStyle(
                color: _status == 'Active' ? Colors.green : Colors.red,
              ),
            ),
          ),

          const SizedBox(height: 30),

          _buildCard(isDark, [
            _buildDetailRow("User ID", _userId, isDark),
            _spacer(),
            _buildDetailRow("Username", _username, isDark),
            _spacer(),
            _buildDetailRow("Email", _email, isDark),
            _spacer(),
            _buildDetailRow("Phone Number",
                _phoneNumber.isEmpty ? 'Not provided' : _phoneNumber, isDark),
            _spacer(),
            _buildDetailRow("CDS Number",
                _cdsNumber.isEmpty ? 'Not provided' : _cdsNumber, isDark),
          ]),

          const SizedBox(height: 20),

          _buildCard(isDark, [
            Text(
              "Account Information",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            _spacer(),
            _buildDetailRow("Account Created", _dateCreated, isDark),
            _spacer(),
            _buildDetailRow("Last Login", _lastLoginDate, isDark),
          ]),

          const SizedBox(height: 30),

          // Theme Toggle Button
          // _buildActionButton(
          //   isDark ? "Switch to Light Mode" : "Switch to Dark Mode",
          //   isDark ? Icons.light_mode : Icons.dark_mode,
          //   Colors.orange,
          //       () => themeProvider.toggleTheme(),
          //   isDark,
          // ),
          const SizedBox(height: 12),

          // Change Password Button
          _buildActionButton(
            "Change Password",
            Icons.lock,
            Colors.blue,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
            isDark,
          ),
          const SizedBox(height: 12),

          _buildActionButton(
            "Logout",
            Icons.logout,
            Colors.red,
                () {
              _showLogoutDialog(isDark);
            },
            isDark,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _spacer() => const SizedBox(height: 16);

  Widget _buildCard(bool isDark, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : Colors.black.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      bool isDark,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        title: Text(
          'Logout',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ========== CHANGE PASSWORD SCREEN ==========

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('email') ?? '';
    });
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill all fields', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('New password must be at least 6 characters',
          isError: true);
      return;
    }

    if (oldPassword == newPassword) {
      _showSnackBar('New password must be different from old password',
          isError: true);
      return;
    }

    if (_email.isEmpty) {
      _showSnackBar('Email not found. Please login again.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(
            'http://192.168.3.201/MainAPI/Authentication/ChangePassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email': _email,
          'OldPassword': oldPassword,
          'NewPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && data['responseCode'] == 200) {
        _showSnackBar(
            data['responseMessage'] ?? 'Password changed successfully',
            isError: false);

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showSnackBar(
            data['responseMessage'] ?? 'Failed to change password',
            isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('An error occurred. Please try again.', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        duration: const Duration(seconds: 3),
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
      colors: [
        Color(0xFF2C1810),
        Color(0xFF1A1A1A),
        Color(0xFF0D0D0D),
      ],
    )
        : const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF8E7),
        Color(0xFFF5F5F5),
        Color(0xFFFFFFFF),
      ],
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                "Change Password",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(gradient: bgGradient),
              ),
            ),
            Expanded(
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFD4A855), Color(0xFFB8860B)],
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1F1F1F)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3A3A3A)
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                            boxShadow: isDark
                                ? []
                                : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Update Your Password',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Enter your current password and choose a new one',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? const Color(0xFF9E9E9E)
                                      : Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              _buildPasswordField(
                                controller: _oldPasswordController,
                                hintText: 'Current Password',
                                obscureText: _obscureOldPassword,
                                onToggleVisibility: () {
                                  setState(() => _obscureOldPassword =
                                  !_obscureOldPassword);
                                },
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),
                              _buildPasswordField(
                                controller: _newPasswordController,
                                hintText: 'New Password',
                                obscureText: _obscureNewPassword,
                                onToggleVisibility: () {
                                  setState(() => _obscureNewPassword =
                                  !_obscureNewPassword);
                                },
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),
                              _buildPasswordField(
                                controller: _confirmPasswordController,
                                hintText: 'Confirm New Password',
                                obscureText: _obscureConfirmPassword,
                                onToggleVisibility: () {
                                  setState(() => _obscureConfirmPassword =
                                  !_obscureConfirmPassword);
                                },
                                isDark: isDark,
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Colors.blue[300],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Password Requirements:',
                                          style: TextStyle(
                                            color: Colors.blue[300],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildRequirement('At least 6 characters'),
                                    _buildRequirement(
                                        'Different from current password'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed:
                                _isLoading ? null : _handleChangePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4A855),
                                  foregroundColor: Colors.white,
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
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
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                                    : const Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[600] : Colors.grey.shade500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: isDark ? Colors.grey[600] : Colors.grey.shade500,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: isDark ? Colors.grey[600] : Colors.grey.shade500,
            ),
            onPressed: onToggleVisibility,
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: Colors.blue[200],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.blue[200],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}