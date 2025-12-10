import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../settings /settings.dart';

class AppDrawer extends StatefulWidget {
  final Function(int) onMenuItemTapped;
  final VoidCallback onMarketWatchTapped;
  final VoidCallback onBuySellTapped;

  const AppDrawer({
    super.key,
    required this.onMenuItemTapped,
    required this.onMarketWatchTapped,
    required this.onBuySellTapped,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _fullName = 'Loading...';
  String _email = 'Loading...';
  String _avatar = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _fullName = prefs.getString('fullName') ?? 'User';
        _email = prefs.getString('email') ?? 'No email';
        _avatar = _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'U';
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Call logout API
      final response = await http.post(
        Uri.parse('http://192.168.3.201/MainAPI/Authentication/Logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Token': token}),
      ).timeout(const Duration(seconds: 30));

      // Clear SharedPreferences regardless of API response
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      // Still clear preferences and navigate to login on error
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );
      }
    }
  }

  void _navigateToProfile() {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1A1A1A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B6914),
                    Color(0xFF6B5010),
                  ],
                ),
              ),
              child: GestureDetector(
                onTap: _navigateToProfile,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.amber,
                      child: Text(
                        _avatar,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.home_outlined,
              title: 'Dashboard',
              onTap: () {
                widget.onMenuItemTapped(0);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.bar_chart_outlined,
              title: 'Market Analysis',
              onTap: () {
                widget.onMenuItemTapped(1);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.attach_money,
              title: 'Transactions',
              onTap: () {
                widget.onMenuItemTapped(3);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.shopping_bag_outlined,
              title: 'Portfolio',
              onTap: () {
                widget.onMenuItemTapped(4);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.trending_up,
              title: 'Market Watch',
              onTap: () {
                widget.onMarketWatchTapped();
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.swap_horiz,
              title: 'Buy/Sell',
              onTap: () {
                widget.onBuySellTapped();
                Navigator.pop(context);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Divider(color: Colors.white24, height: 1),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: _navigateToProfile,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context); // Close drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: _handleLogout,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.amber,
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: isLast ? null : const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }
}