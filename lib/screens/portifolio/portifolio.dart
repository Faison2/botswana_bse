import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme_provider.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String _selectedTab = 'PORTFOLIO';
  List<Map<String, dynamic>> _portfolioData = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _cdsNumber;
  double _totalBalance = 0.0;
  String _currency = '';

  @override
  void initState() {
    super.initState();
    _loadDataFromApi();
  }

  /// Extracts a List<dynamic> from any API response shape:
  /// - Already a list:  [ {...}, {...} ]
  /// - Wrapped in key:  { "data": [...] } / { "Transactions": [...] } etc.
  /// - Single object:   { ... }  → wrapped in list
  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map) {
      // Try common wrapper keys
      const wrapperKeys = [
        'data', 'Data',
        'transactions', 'Transactions',
        'result', 'Result',
        'results', 'Results',
        'records', 'Records',
        'items', 'Items',
        'response', 'Response',
      ];
      for (final key in wrapperKeys) {
        if (decoded.containsKey(key) && decoded[key] is List) {
          return decoded[key] as List<dynamic>;
        }
      }
      // No known wrapper key — treat the single object as one item
      return [decoded];
    }
    return [];
  }

  Future<void> _loadDataFromApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cdsNumber = prefs.getString('cdsNumber');

      if (cdsNumber == null || cdsNumber.isEmpty) {
        setState(() {
          _errorMessage = 'CDS number not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      _cdsNumber = cdsNumber;

      final response = await http.post(
        Uri.parse('https://zamagm.escrowagm.com/MainAPI/home/Transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'CDSNumber': cdsNumber}),
      );

      // DEBUG: print raw response — check your console/logcat
      debugPrint('=== Portfolio API Response ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('==============================');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = _extractList(decoded);

        debugPrint('Extracted ${data.length} transaction(s)');

        if (data.isEmpty) {
          setState(() {
            _portfolioData = [];
            _totalBalance = 0.0;
            _currency = '';
            _isLoading = false;
          });
          return;
        }

        double total = 0.0;
        String currency = '';

        final List<Map<String, dynamic>> parsed = data
            .where((item) => item is Map)
            .map((item) {
          final amount =
              double.tryParse(item['Amount']?.toString() ?? '0') ?? 0.0;
          total += amount;
          if (item['Currency'] != null) {
            currency = item['Currency'].toString();
          }
          return <String, dynamic>{
            'date': _formatDate(item['DateCreated']?.toString() ?? ''),
            'description': item['Description']?.toString() ?? '-',
            'reference': item['Reference']?.toString() ?? '-',
            'amount': _formatAmount(amount),
          };
        })
            .toList();

        setState(() {
          _portfolioData = parsed;
          _totalBalance = total;
          _currency = currency;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
          'Server error: ${response.statusCode}\n${response.body}';
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Portfolio error: $e\n$stack');
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String rawDate) {
    try {
      final parts = rawDate.split(' ');
      final dateParts = parts[0].split('/');
      if (dateParts.length == 3) {
        final month = dateParts[0].padLeft(2, '0');
        final day = dateParts[1].padLeft(2, '0');
        final year = dateParts[2];
        return '$year-$month-$day';
      }
    } catch (_) {}
    return rawDate;
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'),
          (m) => '${m[1]},',
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
      colors: [Color(0xFF2C1810), Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
    )
        : const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF8E7), Color(0xFFF5F5F5), Color(0xFFFFFFFF)],
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
    final accentColor =
    isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
    final inactiveColor = isDark ? Colors.white54 : Colors.black45;
    final bgColor =
    isDark ? Colors.transparent : Colors.white.withOpacity(0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1A1A)
              : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: ['PORTFOLIO', 'ORDERS'].map((tab) {
            final isSelected = _selectedTab == tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : bgColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                        : [],
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isSelected ? Colors.white : inactiveColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPortfolioCard(bool isDark) {
    final cardGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B6914), Color(0xFF6B5010)],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD4A855), Color(0xFFB8860B)],
    );

    final subtextColor = Colors.white.withOpacity(0.85);
    final balanceText = _isLoading
        ? 'Loading...'
        : (_errorMessage != null
        ? '—'
        : _currency.isEmpty
        ? _formatAmount(_totalBalance)
        : '$_currency ${_formatAmount(_totalBalance)}');

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Portfolio Balance',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
              if (_cdsNumber != null)
                Text(
                  _cdsNumber!,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  balanceText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _loadDataFromApi,
                child:
                const Icon(Icons.refresh, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                '${_portfolioData.length} transaction${_portfolioData.length == 1 ? '' : 's'}',
                style: TextStyle(color: subtextColor, fontSize: 13),
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
    final headerTextColor =
    isDark ? Colors.white.withOpacity(0.7) : Colors.black54;
    final borderColor =
    isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2);

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
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _headerCell('Date',
                    flex: 2,
                    color: headerTextColor,
                    align: TextAlign.left),
                _headerCell('Description',
                    flex: 4,
                    color: headerTextColor,
                    align: TextAlign.left),
                _headerCell('Reference',
                    flex: 4,
                    color: headerTextColor,
                    align: TextAlign.left),
                _headerCell('Amount',
                    flex: 3,
                    color: headerTextColor,
                    align: TextAlign.right),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade300, size: 40),
                    const SizedBox(height: 12),
                    Text(_errorMessage!,
                        style: TextStyle(color: textColor),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadDataFromApi,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
                : _portfolioData.isEmpty
                ? Center(
              child: Text('No transactions found.',
                  style: TextStyle(color: textColor)),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _portfolioData.length,
              itemBuilder: (context, index) {
                final item = _portfolioData[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: borderColor, width: 1)),
                  ),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(item['date'] ?? '-',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 10)),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          item['description'] ?? '-',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 10,
                              height: 1.3),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          item['reference'] ?? '-',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 10,
                              height: 1.3),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item['amount'] ?? '0.00',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
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

  Widget _headerCell(String label,
      {required int flex,
        required Color color,
        required TextAlign align}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
        textAlign: align,
      ),
    );
  }
}