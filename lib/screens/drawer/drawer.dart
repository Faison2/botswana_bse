import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Image.asset(
                      'assets/avatar.png',
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Colors.black, size: 35);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Victor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'victor@example.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.home_outlined,
              title: 'Dashboard',
              onTap: () {
                onMenuItemTapped(0);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.bar_chart_outlined,
              title: 'Market Analysis',
              onTap: () {
                onMenuItemTapped(1);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.attach_money,
              title: 'Transactions',
              onTap: () {
                onMenuItemTapped(3);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.shopping_bag_outlined,
              title: 'Portfolio',
              onTap: () {
                onMenuItemTapped(4);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.trending_up,
              title: 'Market Watch',
              onTap: () {
                onMarketWatchTapped();
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.swap_horiz,
              title: 'Buy/Sell',
              onTap: () {
                onBuySellTapped();
                Navigator.pop(context);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Divider(color: Colors.white24, height: 1),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                Navigator.pop(context);
                // Add your logout logic here
              },
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