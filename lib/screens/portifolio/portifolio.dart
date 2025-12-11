import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String _selectedTab = 'PORTFOLIO';
  final bool _isBalanceVisible = true;

  final List<Map<String, dynamic>> _portfolioData = [
    {
      'date': '2023-01-15',
      'company': 'Botswana\nDevelopment\nCorp.',
      'currentPrice': 'BWP 1.50',
      'quantity': '1,000',
      'value': 'BWP 1,500.00',
    },
    {
      'date': '2023-02-20',
      'company': 'Choppies\nEnterprises Ltd.',
      'currentPrice': 'BWP 0.75',
      'quantity': '500',
      'value': 'BWP 375.00',
    },
    {
      'date': '2023-03-10',
      'company': 'First National\nBank',
      'currentPrice': 'BWP 18.00',
      'quantity': '20',
      'value': 'BWP 360.00',
    },
    {
      'date': '2023-04-05',
      'company': 'Industrial Assets\nHoldings',
      'currentPrice': 'BWP 1.10',
      'quantity': '1,500',
      'value': 'BWP 1,650.00',
    },
  ];

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
              _buildTabSelector(isDark),
              const SizedBox(height: 20),
              _buildPortfolioCard(isDark),
              const SizedBox(height: 20),
              Expanded(child: _buildPortfolioTable(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector(bool isDark) {
    final accentColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
    final inactiveColor = isDark ? Colors.white54 : Colors.black45;
    final bgColor = isDark ? Colors.transparent : Colors.white.withOpacity(0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = 'PORTFOLIO');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 'PORTFOLIO' ? accentColor : bgColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: _selectedTab == 'PORTFOLIO'
                        ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : [],
                  ),
                  child: Text(
                    'PORTFOLIO',
                    style: TextStyle(
                      color: _selectedTab == 'PORTFOLIO'
                          ? Colors.white
                          : inactiveColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = 'ORDERS');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 'ORDERS' ? accentColor : bgColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: _selectedTab == 'ORDERS'
                        ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : [],
                  ),
                  child: Text(
                    'ORDERS',
                    style: TextStyle(
                      color: _selectedTab == 'ORDERS'
                          ? Colors.white
                          : inactiveColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard(bool isDark) {
    final cardGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF8B6914),
        Color(0xFF6B5010),
      ],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFD4A855),
        Color(0xFFB8860B),
      ],
    );

    final textColor = Colors.white;
    final subtextColor = isDark ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.9);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Total Portfolio Balance',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),

          // Balance with refresh icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBalanceVisible ? '\$ 16,300.50' : '••••••••',
                style: TextStyle(
                  color: textColor,
                  fontSize: 42,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1,
                ),
              ),
              Icon(Icons.refresh, color: textColor, size: 28),
            ],
          ),
          const SizedBox(height: 12),

          // Percentage Change
          Row(
            children: [
              const Icon(
                Icons.arrow_upward,
                color: Color(0xFF4CAF50),
                size: 14,
              ),
              const SizedBox(width: 4),
              const Text(
                '10.9%',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'in the past week',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioTable(bool isDark) {
    final tableBgColor = isDark
        ? const Color(0xFF2A2A2A).withOpacity(0.5)
        : Colors.white.withOpacity(0.7);
    final headerBgColor = isDark
        ? Colors.black.withOpacity(0.2)
        : Colors.grey.shade200.withOpacity(0.5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final headerTextColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: tableBgColor,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      color: headerTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Company',
                    style: TextStyle(
                      color: headerTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Current Price',
                    style: TextStyle(
                      color: headerTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Quantity',
                    style: TextStyle(
                      color: headerTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Value',
                    style: TextStyle(
                      color: headerTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _portfolioData.length,
              itemBuilder: (context, index) {
                final item = _portfolioData[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['date'],
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item['company'],
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['currentPrice'],
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['quantity'],
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['value'],
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}