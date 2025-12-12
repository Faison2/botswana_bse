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
          // _buildActionButton(
          //   "Change Password",
          //   Icons.lock,
          //   Colors.blue,
          //       () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const ChangePasswordScreen(),
          //       ),
          //     );
          //   },
          //   isDark,
          // ),
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

