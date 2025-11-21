import 'package:flutter/material.dart';

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C1810), Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTabSelector(),
              const SizedBox(height: 20),
              _buildPortfolioCard(),
              const SizedBox(height: 20),
              Expanded(child: _buildPortfolioTable()),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  color: _selectedTab == 'PORTFOLIO'
                      ? const Color(0xFF8B6914)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'PORTFOLIO',
                  style: TextStyle(
                    color: _selectedTab == 'PORTFOLIO'
                        ? Colors.white
                        : Colors.white54,
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
                  color: _selectedTab == 'ORDERS'
                      ? const Color(0xFF8B6914)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'ORDERS',
                  style: TextStyle(
                    color: _selectedTab == 'ORDERS'
                        ? Colors.white
                        : Colors.white54,
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
    );
  }

  Widget _buildPortfolioCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF8B6914), const Color(0xFF6B5010)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Total Portfolio Balance',
            style: TextStyle(
              color: Colors.white,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1,
                ),
              ),
              const Icon(Icons.refresh, color: Colors.white, size: 28),
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
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
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
                      color: Colors.white.withOpacity(0.7),
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
                      color: Colors.white.withOpacity(0.7),
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
                      color: Colors.white.withOpacity(0.7),
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
                      color: Colors.white.withOpacity(0.7),
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
                      color: Colors.white.withOpacity(0.7),
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
                        color: Colors.white.withOpacity(0.1),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item['company'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['currentPrice'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['quantity'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['value'],
                          style: const TextStyle(
                            color: Colors.white,
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
