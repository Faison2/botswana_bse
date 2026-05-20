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
  String _cvNumber = '';
  String _status = '';
  String _lastLoginDate = '';
  String _dateCreated = '';
  String _token = '';

  // ← NEW fields from API response
  String _cdsAccountNumber = '';
  String _employmentStatus = '';

  // Brokers now come from the profile response
  List<Map<String, dynamic>> _brokersList = [];

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
        Uri.parse(
            'https://zamagm.escrowagm.com/MainAPI/Authentication/GetProfile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Token': token}),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['responseCode'] == 200) {
          final phoneNumber = responseData['phoneNumber'] ?? '';
          final cvNumber = responseData['username'] ?? '';

          await prefs.setString('phoneNumber', phoneNumber);

          // ← Extract brokers list from profile response
          List<Map<String, dynamic>> brokers = [];
          if (responseData['brokers'] != null &&
              responseData['brokers'] is List) {
            brokers = List<Map<String, dynamic>>.from(
                responseData['brokers']);
          }

          setState(() {
            _userId = responseData['userId'] ?? '';
            _username = responseData['username'] ?? '';
            _email = responseData['email'] ?? '';
            _fullName = responseData['fullName'] ?? '';
            _phoneNumber = phoneNumber;
            _cvNumber = cvNumber;
            _status = responseData['status'] ?? '';
            _lastLoginDate = responseData['lastLoginDate'] ?? '';
            _dateCreated = responseData['dateCreated'] ?? '';

            // ← NEW
            _cdsAccountNumber =
                responseData['csdAccountNumber'] ?? '';
            _employmentStatus =
                responseData['employmentStatus'] ?? '';

            _brokersList = brokers;
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

  Future<void> _linkBroker(String brokerCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (_cvNumber.isEmpty) {
        _showSnackBar('CV Number not available', Colors.red);
        return;
      }

      final response = await http.post(
        Uri.parse('https://zamagm.escrowagm.com/MainAPI/Home/BrokerLink'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'CvNumber': _cvNumber,
          'BrokerCode': brokerCode,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseCode'] == 200) {
          _showSnackBar(
              data['responseMessage'] ?? 'Broker linked successfully',
              Colors.green);
          Navigator.pop(context);
        } else {
          _showSnackBar(
              data['responseMessage'] ?? 'Failed to link broker', Colors.red);
        }
      } else {
        _showSnackBar('Failed to link broker. Please try again.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showBrokerLinkDialog(bool isDark) {
    String? selectedBrokerCode;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4A855), Color(0xFFB8860B)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BROKER LINK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Link your account to a broker',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CV Number Display
                Text(
                  'CV Number',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3C3C3C)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _cvNumber.isEmpty ? 'Not available' : _cvNumber,
                    style: TextStyle(
                      color: _cvNumber.isEmpty
                          ? Colors.grey
                          : (isDark ? Colors.white : Colors.black87),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Broker List — each as a tappable tile
                Text(
                  'Select Broker',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // ← Replaced DropdownButton with a list of tiles
                //   Active brokers are grayed out and non-tappable
                ..._brokersList.map((broker) {
                  final brokerName =
                      broker['brokerName']?.toString() ?? 'Unknown Broker';
                  final brokerCode =
                      broker['brokerCode']?.toString() ?? '';
                  final brokerStatus =
                  (broker['status']?.toString() ?? '').toUpperCase();
                  final cdsAccount =
                      broker['CDSAccount']?.toString() ?? '';
                  final isActive = brokerStatus == 'ACTIVE';
                  final isSelected = selectedBrokerCode == brokerCode;

                  return GestureDetector(
                    // ← Disable tap for ACTIVE brokers
                    onTap: isActive
                        ? null
                        : () {
                      setDialogState(() {
                        selectedBrokerCode = brokerCode;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        // ← Gray background for ACTIVE, highlight for selected
                        color: isActive
                            ? (isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey[100])
                            : isSelected
                            ? const Color(0xFFD4A855).withOpacity(0.15)
                            : (isDark
                            ? const Color(0xFF3C3C3C)
                            : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? Colors.grey.withOpacity(0.3)
                              : isSelected
                              ? const Color(0xFFD4A855)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Selection indicator
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isActive
                                ? Colors.grey.withOpacity(0.4)
                                : isSelected
                                ? const Color(0xFFD4A855)
                                : (isDark
                                ? Colors.white38
                                : Colors.black38),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  brokerName,
                                  style: TextStyle(
                                    // ← Gray text for ACTIVE
                                    color: isActive
                                        ? Colors.grey.withOpacity(0.5)
                                        : (isDark
                                        ? Colors.white
                                        : Colors.black87),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (cdsAccount.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'CDS: $cdsAccount',
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.grey.withOpacity(0.4)
                                          : (isDark
                                          ? Colors.white54
                                          : Colors.black54),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                                Text(
                                  brokerCode,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.grey.withOpacity(0.4)
                                        : (isDark
                                        ? Colors.white38
                                        : Colors.black38),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.grey.withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isActive
                                    ? Colors.grey.withOpacity(0.3)
                                    : Colors.orange.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              brokerStatus,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.grey
                                    : Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 10),

                // Info Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: Your broker link request will be submitted for approval. You will be notified once it has been processed.',
                          style: TextStyle(
                            color: isDark
                                ? Colors.blue[200]
                                : Colors.blue[900],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selectedBrokerCode == null || _cvNumber.isEmpty
                  ? null
                  : () => _linkBroker(selectedBrokerCode!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A855),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: const Text(
                'LINK BROKER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.amber),
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
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.amber),
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

          Text(
            _fullName,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

          // ── Personal Info Card ──────────────────────────────
          _buildCard(isDark, [
            _buildDetailRow("User ID", _userId, isDark),
            _spacer(),
            _buildDetailRow("Username", _username, isDark),
            _spacer(),
            _buildDetailRow("Email", _email, isDark),
            _spacer(),
            _buildDetailRow(
                "Phone Number",
                _phoneNumber.isEmpty ? 'Not provided' : _phoneNumber,
                isDark),
            _spacer(),
            _buildDetailRow(
                "ACC Number",
                _cvNumber.isEmpty ? 'Not provided' : _cvNumber,
                isDark),
            _spacer(),
            // ← NEW: CDS Account from API
            _buildDetailRow(
                "CDS Account",
                _cdsAccountNumber.isEmpty
                    ? 'Not provided'
                    : _cdsAccountNumber,
                isDark),
            _spacer(),
            // ← NEW: Employment Status from API
            _buildDetailRow(
                "Employment Status",
                _employmentStatus.isEmpty
                    ? 'Not provided'
                    : _employmentStatus,
                isDark),
          ]),

          const SizedBox(height: 20),

          // ── Account Info Card ───────────────────────────────
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
            // ← Already present — now properly populated
            _buildDetailRow(
                "Last Login",
                _lastLoginDate.isEmpty ? 'Not available' : _lastLoginDate,
                isDark),
          ]),

          const SizedBox(height: 30),

          _buildActionButton(
            "Link Broker",
            Icons.link,
            const Color(0xFFD4A855),
                () => _showBrokerLinkDialog(isDark),
            isDark,
          ),

          const SizedBox(height: 12),

          _buildActionButton(
            "Logout",
            Icons.logout,
            Colors.red,
                () => _showLogoutDialog(isDark),
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
        backgroundColor:
        isDark ? const Color(0xFF1F1F1F) : Colors.white,
        title: Text(
          'Logout',
          style:
          TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87),
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
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}