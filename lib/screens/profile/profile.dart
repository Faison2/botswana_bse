import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
          _errorMessage =
          'No authentication token found. Please login again.';
        });
        return;
      }

      final response = await http
          .post(
        Uri.parse(
            'http://192.168.3.201/MainAPI/Authentication/GetProfile'),
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
                responseData['responseMessage'] ??
                    'Failed to load profile';
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
    return Scaffold(
      // FIXED: full screen gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C1810),
              Color(0xFF1A1A1A),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: Column(
          children: [
            // FIXED: Gradient AppBar
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                "My Profile",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2C1810),
                      Color(0xFF1A1A1A),
                      Color(0xFF0D0D0D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              )
                  : _errorMessage.isNotEmpty
                  ? _buildErrorUI()
                  : _buildProfileUI(),
            ),
          ],
        ),
      ),
    );
  }

  // --- ERROR UI ---
  Widget _buildErrorUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.red, size: 60),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16),
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

  // --- MAIN PROFILE UI ---
  Widget _buildProfileUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 30),

          // Avatar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFD4A855), Color(0xFFB8860B)],
              ),
            ),
            child: Center(
              child: Text(
                _fullName.isNotEmpty
                    ? _fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Name
          Text(
            _fullName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // Status Badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _status == 'Active'
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _status == 'Active'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            child: Text(
              _status,
              style: TextStyle(
                  color:
                  _status == 'Active' ? Colors.green : Colors.red),
            ),
          ),

          const SizedBox(height: 30),

          _buildCard([
            _buildDetailRow("User ID", _userId),
            _spacer(),
            _buildDetailRow("Username", _username),
            _spacer(),
            _buildDetailRow("Email", _email),
            _spacer(),
            _buildDetailRow("Phone Number",
                _phoneNumber.isEmpty ? 'Not provided' : _phoneNumber),
            _spacer(),
            _buildDetailRow(
                "CDS Number",
                _cdsNumber.isEmpty ? 'Not provided' : _cdsNumber),
          ]),

          const SizedBox(height: 20),

          _buildCard([
            const Text(
              "Account Information",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            _spacer(),
            _buildDetailRow("Account Created", _dateCreated),
            _spacer(),
            _buildDetailRow("Last Login", _lastLoginDate),
          ]),

          const SizedBox(height: 30),

          // _buildActionButton(
          //     "Edit Profile", Icons.edit, Colors.amber,
          //         () {
          //       _comingSoon("Edit Profile");
          //     }),
          const SizedBox(height: 12),

          _buildActionButton(
              "Change Password", Icons.lock, Colors.blue,
                  () {
                _comingSoon("Change Password");
              }),
          const SizedBox(height: 12),

          _buildActionButton("Logout", Icons.logout, Colors.red, () {
            _showLogoutDialog();
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _spacer() => const SizedBox(height: 16);

  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
          TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
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
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15), // Slightly more visible color
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
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
  void _comingSoon(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text - Coming Soon'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
