import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import 'withdrawals_tab.dart';
import 'deposits_tab.dart';
import 'transactions_tab.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTab('WITHDRAWALS', 0, isDark),
                                const SizedBox(width: 8),
                                _buildTab('DEPOSITS', 1, isDark),
                                const SizedBox(width: 8),
                                _buildTab('TRANSACTIONS', 2, isDark),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Balance Card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                            const Color(0xFF8B6914),
                            const Color(0xFF6B5010),
                          ]
                              : [
                            const Color(0xFFDAA520),
                            const Color(0xFF8B6914),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Cash Balance',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'BWP 300.50',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white, size: 32),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content based on selected tab
                  Expanded(
                    child: _selectedTab == 0
                        ? WithdrawalsTab(isDark: isDark)
                        : _selectedTab == 1
                        ? DepositsTab(isDark: isDark)
                        : TransactionsTab(isDark: isDark),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(String title, int index, bool isDark) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTab = index;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF8B6914) : const Color(0xFFDAA520))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white24 : Colors.black26),
            width: 1,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60),
          child: Text(
            title,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}