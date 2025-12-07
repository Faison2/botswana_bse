import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bse/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification Settings
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _tradeAlerts = true;
  bool _priceAlerts = true;
  bool _marketNews = false;

  // Security Settings
  bool _biometricLogin = false;
  bool _twoFactorAuth = false;

  // Display Settings
  bool _showBalance = true;
  bool _compactView = false;

  // Trading Settings
  String _defaultOrderType = 'Market Order';
  String _confirmationLevel = 'All Trades';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _emailNotifications = prefs.getBool('emailNotifications') ?? false;
      _tradeAlerts = prefs.getBool('tradeAlerts') ?? true;
      _priceAlerts = prefs.getBool('priceAlerts') ?? true;
      _marketNews = prefs.getBool('marketNews') ?? false;
      _biometricLogin = prefs.getBool('biometricLogin') ?? false;
      _twoFactorAuth = prefs.getBool('twoFactorAuth') ?? false;
      _showBalance = prefs.getBool('showBalance') ?? true;
      _compactView = prefs.getBool('compactView') ?? false;
      _defaultOrderType = prefs.getString('defaultOrderType') ?? 'Market Order';
      _confirmationLevel = prefs.getString('confirmationLevel') ?? 'All Trades';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(isDark),

              // Settings Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Appearance Section
                        _buildSectionHeader('Appearance', isDark),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          isDark,
                          [
                            _buildSwitchTile(
                              'Dark Mode',
                              'Switch between light and dark theme',
                              Icons.dark_mode_outlined,
                              themeProvider.isDarkMode,
                                  (value) => themeProvider.toggleTheme(),
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildSwitchTile(
                              'Compact View',
                              'Show more content on screen',
                              Icons.view_compact_outlined,
                              _compactView,
                                  (value) {
                                setState(() => _compactView = value);
                                _saveSetting('compactView', value);
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildSwitchTile(
                              'Show Balance',
                              'Display balance by default',
                              Icons.visibility_outlined,
                              _showBalance,
                                  (value) {
                                setState(() => _showBalance = value);
                                _saveSetting('showBalance', value);
                              },
                              isDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Notifications Section
                        _buildSectionHeader('Notifications', isDark),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          isDark,
                          [
                            _buildSwitchTile(
                              'Push Notifications',
                              'Receive notifications on your device',
                              Icons.notifications_outlined,
                              _pushNotifications,
                                  (value) {
                                setState(() => _pushNotifications = value);
                                _saveSetting('pushNotifications', value);
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildSwitchTile(
                              'Email Notifications',
                              'Receive updates via email',
                              Icons.email_outlined,
                              _emailNotifications,
                                  (value) {
                                setState(() => _emailNotifications = value);
                                _saveSetting('emailNotifications', value);
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildSwitchTile(
                              'Trade Alerts',
                              'Get notified about trade execution',
                              Icons.swap_horiz,
                              _tradeAlerts,
                                  (value) {
                                setState(() => _tradeAlerts = value);
                                _saveSetting('tradeAlerts', value);
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildSwitchTile(
                              'Price Alerts',
                              'Notify when stock reaches target price',
                              Icons.price_change_outlined,
                              _priceAlerts,
                                  (value) {
                                setState(() => _priceAlerts = value);
                                _saveSetting('priceAlerts', value);
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildSwitchTile(
                              'Market News',
                              'Receive market updates and news',
                              Icons.newspaper_outlined,
                              _marketNews,
                                  (value) {
                                setState(() => _marketNews = value);
                                _saveSetting('marketNews', value);
                              },
                              isDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Security Section
                        _buildSectionHeader('Security', isDark),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          isDark,
                          [
                            _buildSwitchTile(
                              'Biometric Login',
                              'Use fingerprint or face ID',
                              Icons.fingerprint,
                              _biometricLogin,
                                  (value) {
                                setState(() => _biometricLogin = value);
                                _saveSetting('biometricLogin', value);
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildSwitchTile(
                              'Two-Factor Authentication',
                              'Add extra security to your account',
                              Icons.security_outlined,
                              _twoFactorAuth,
                                  (value) {
                                setState(() => _twoFactorAuth = value);
                                _saveSetting('twoFactorAuth', value);
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildNavigationTile(
                              'Change Password',
                              'Update your account password',
                              Icons.lock_outline,
                                  () {
                                Navigator.pushNamed(context, '/change-password');
                              },
                              isDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Trading Preferences Section
                        _buildSectionHeader('Trading Preferences', isDark),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          isDark,
                          [
                            _buildDropdownTile(
                              'Default Order Type',
                              'Select default type for new orders',
                              Icons.receipt_long_outlined,
                              _defaultOrderType,
                              ['Market Order', 'Limit Order', 'Stop Order'],
                                  (value) {
                                setState(() => _defaultOrderType = value!);
                                _saveSetting('defaultOrderType', value);
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildDropdownTile(
                              'Trade Confirmation',
                              'When to show confirmation dialog',
                              Icons.check_circle_outline,
                              _confirmationLevel,
                              ['All Trades', 'Large Trades Only', 'Never'],
                                  (value) {
                                setState(() => _confirmationLevel = value!);
                                _saveSetting('confirmationLevel', value);
                              },
                              isDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Account Section
                        _buildSectionHeader('Account', isDark),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          isDark,
                          [
                            _buildNavigationTile(
                              'Profile Information',
                              'View and edit your profile',
                              Icons.person_outline,
                                  () {
                                Navigator.pushNamed(context, '/profile');
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildNavigationTile(
                              'Payment Methods',
                              'Manage your payment options',
                              Icons.payment_outlined,
                                  () {
                                _showComingSoonDialog('Payment Methods');
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildNavigationTile(
                              'Tax Documents',
                              'Download tax forms and statements',
                              Icons.description_outlined,
                                  () {
                                _showComingSoonDialog('Tax Documents');
                              },
                              isDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Support Section
                        _buildSectionHeader('Support', isDark),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          isDark,
                          [
                            _buildNavigationTile(
                              'Help Center',
                              'Get help and support',
                              Icons.help_outline,
                                  () {
                                _showComingSoonDialog('Help Center');
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildNavigationTile(
                              'Contact Us',
                              'Reach out to our support team',
                              Icons.contact_support_outlined,
                                  () {
                                _showContactDialog(isDark);
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildNavigationTile(
                              'Terms & Conditions',
                              'Read our terms of service',
                              Icons.article_outlined,
                                  () {
                                _showComingSoonDialog('Terms & Conditions');
                              },
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildNavigationTile(
                              'Privacy Policy',
                              'Learn how we protect your data',
                              Icons.privacy_tip_outlined,
                                  () {
                                _showComingSoonDialog('Privacy Policy');
                              },
                              isDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // About Section
                        _buildSectionHeader('About', isDark),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          isDark,
                          [
                            _buildInfoTile(
                              'Version',
                              '1.0.0',
                              Icons.info_outline,
                              isDark,
                            ),
                            _buildDivider(isDark),
                            _buildNavigationTile(
                              'Rate Us',
                              'Share your feedback',
                              Icons.star_outline,
                                  () {
                                _showComingSoonDialog('Rate Us');
                              },
                              isDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Danger Zone
                        _buildSectionHeader('Danger Zone', isDark, color: Colors.red),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          isDark,
                          [
                            _buildNavigationTile(
                              'Clear Cache',
                              'Remove temporary files',
                              Icons.cleaning_services_outlined,
                                  () {
                                _showClearCacheDialog(isDark);
                              },
                              isDark,
                              textColor: Colors.orange,
                            ),
                            _buildDivider(isDark),
                            _buildNavigationTile(
                              'Logout',
                              'Sign out of your account',
                              Icons.logout,
                                  () {
                                _showLogoutDialog(isDark);
                              },
                              isDark,
                              textColor: Colors.red,
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black87,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            'Settings',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        color: color ?? (isDark ? Colors.amber : const Color(0xFF8B6914)),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      bool isDark,
      ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(
        icon,
        color: isDark ? Colors.amber : const Color(0xFF8B6914),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 13,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF8B6914),
      ),
    );
  }

  Widget _buildNavigationTile(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap,
      bool isDark, {
        Color? textColor,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(
        icon,
        color: textColor ?? (isDark ? Colors.amber : const Color(0xFF8B6914)),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (isDark ? Colors.white : Colors.black87),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile(
      String title,
      String subtitle,
      IconData icon,
      String value,
      List<String> options,
      Function(String?) onChanged,
      bool isDark,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? Colors.amber : const Color(0xFF8B6914),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              underline: const SizedBox(),
              dropdownColor: isDark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      String title,
      String value,
      IconData icon,
      bool isDark,
      ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(
        icon,
        color: isDark ? Colors.amber : const Color(0xFF8B6914),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      color: isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05),
      height: 1,
      indent: 20,
      endIndent: 20,
    );
  }

  void _showComingSoonDialog(String feature) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        title: Text(
          'Coming Soon',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          '$feature will be available in a future update.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF8B6914))),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        title: Text(
          'Contact Us',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email: support@bse.co.bw',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone: +267 123 4567',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Hours: Mon-Fri, 8:00 AM - 5:00 PM',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF8B6914))),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        title: Text(
          'Clear Cache',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'This will remove all temporary files. Are you sure?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear cache logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Clear'),
          ),
        ],
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
                  context,
                  '/login',
                      (route) => false,
                );
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