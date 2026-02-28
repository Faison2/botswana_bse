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

  // ── Portfolio state ──
  List<Map<String, dynamic>> _portfolioData = [];
  bool _isLoadingPortfolio = false;
  String? _portfolioError;
  double _totalPortfolioValue = 0.0;
  double _totalShares = 0.0;

  // ── Orders state ──
  List<Map<String, dynamic>> _ordersData = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  // Shared
  String? _cdsNumber;

  @override
  void initState() {
    super.initState();
    _loadFromCacheThenRefresh();
    _loadOrdersFromApi();
  }

  /// Instantly populate the UI from the cache the Dashboard wrote,
  /// then silently refresh from the API in the background.
  Future<void> _loadFromCacheThenRefresh() async {
    await _loadPortfolioFromCache();
    await _loadPortfolioFromApi();
  }

  // ─────────────────────────────────────────────────────────────
  //  SharedPreferences cache (written by DashboardScreen)
  // ─────────────────────────────────────────────────────────────

  static const _kHoldingsKey      = 'cachedPortfolioHoldings';
  static const _kTotalValueKey    = 'cachedPortfolioValue';
  static const _kTotalSharesKey   = 'cachedTotalShares';

  Future<void> _loadPortfolioFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHoldingsKey);
      if (raw == null || raw.isEmpty) return;

      final List<dynamic> decoded = jsonDecode(raw);
      final holdings = decoded
          .whereType<Map>()
          .map((item) => <String, dynamic>{
        'company':      item['company']?.toString() ?? '-',
        'cdsNumber':    item['cdsNumber']?.toString() ?? '-',
        'totalShares':  (item['totalShares'] as num?)?.toDouble() ?? 0.0,
        'currentValue': (item['currentValue'] as num?)?.toDouble() ?? 0.0,
      })
          .toList();

      if (!mounted) return;
      setState(() {
        _portfolioData       = holdings;
        _totalPortfolioValue = prefs.getDouble(_kTotalValueKey)  ?? 0.0;
        _totalShares         = prefs.getDouble(_kTotalSharesKey) ?? 0.0;
        _cdsNumber           = prefs.getString('cdsNumber');
      });
    } catch (e) {
      debugPrint('Cache load error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      const wrapperKeys = [
        'data', 'Data',
        'portfolio', 'Portfolio',
        'transactions', 'Transactions',
        'orders', 'Orders',
        'result', 'Result',
        'results', 'Results',
        'records', 'Records',
        'items', 'Items',
        'response', 'Response',
        'value', 'Value',
        'list', 'List',
        'content', 'Content',
      ];
      for (final key in wrapperKeys) {
        if (decoded.containsKey(key) && decoded[key] is List) {
          debugPrint('_extractList: found list under key "$key"');
          return decoded[key] as List<dynamic>;
        }
      }
      for (final key in decoded.keys) {
        if (decoded[key] is List) {
          final list = decoded[key] as List<dynamic>;
          debugPrint('_extractList: found list under dynamic key "$key" (${list.length} items)');
          return list;
        }
      }
      debugPrint('_extractList: no list key found, wrapping single map. Keys: ${decoded.keys.toList()}');
      return [decoded];
    }
    return [];
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'),
          (m) => '${m[1]},',
    );
  }

  String _formatDatetime(String rawDate) {
    try {
      final parts = rawDate.split(' ');
      final dateParts = parts[0].split('/');
      if (dateParts.length == 3) {
        final month = dateParts[0].padLeft(2, '0');
        final day = dateParts[1].padLeft(2, '0');
        final year = dateParts[2];
        final time = parts.length >= 3 ? ' ${parts[1]} ${parts[2]}' : '';
        return '$year-$month-$day$time';
      }
    } catch (_) {}
    return rawDate;
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CAPTURED':
        return const Color(0xFF4CAF50);
      case 'PENDING':
        return const Color(0xFFFFC107);
      case 'CANCELLED':
      case 'REJECTED':
        return const Color(0xFFF44336);
      case 'EXECUTED':
      case 'FILLED':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  API calls
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadPortfolioFromApi() async {
    setState(() {
      _isLoadingPortfolio = true;
      _portfolioError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cdsNumber = prefs.getString('cdsNumber');

      if (cdsNumber == null || cdsNumber.isEmpty) {
        setState(() {
          _portfolioError = 'CDS number not found. Please log in again.';
          _isLoadingPortfolio = false;
        });
        return;
      }

      _cdsNumber = cdsNumber;

      final token = prefs.getString('token');

      final portfolioHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        portfolioHeaders['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('https://zamagm.escrowagm.com/MainAPI/Home/GetMyPortfolio'),
        headers: portfolioHeaders,
        body: jsonEncode({'CDSNumber': cdsNumber}),
      );

      debugPrint('=== Portfolio API Response ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('==============================');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = _extractList(decoded);

        if (data.isEmpty) {
          setState(() {
            _portfolioData = [];
            _totalPortfolioValue = 0.0;
            _totalShares = 0.0;
            _isLoadingPortfolio = false;
          });
          return;
        }

        double totalValue = 0.0;
        double totalShares = 0.0;

        final parsed = data.where((item) => item is Map).map((item) {
          final currentValue =
              double.tryParse(item['CurrentValue']?.toString() ?? '0') ?? 0.0;
          final shares =
              double.tryParse(item['Total_Shares']?.toString() ?? '0') ?? 0.0;

          totalValue += currentValue;
          totalShares += shares;

          return <String, dynamic>{
            'company': item['Company']?.toString() ?? '-',
            'cdsNumber': item['CDS_Number']?.toString() ?? '-',
            'totalShares': shares,
            'currentValue': currentValue,
          };
        }).toList();

        setState(() {
          _portfolioData = parsed;
          _totalPortfolioValue = totalValue;
          _totalShares = totalShares;
          _isLoadingPortfolio = false;
        });
      } else {
        setState(() {
          _portfolioError =
          'Server error: ${response.statusCode}\n${response.body}';
          _isLoadingPortfolio = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Portfolio error: $e\n$stack');
      setState(() {
        _portfolioError = 'Failed to load data: $e';
        _isLoadingPortfolio = false;
      });
    }
  }

  Future<void> _loadOrdersFromApi() async {
    setState(() {
      _isLoadingOrders = true;
      _ordersError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cdsNumber = prefs.getString('cdsNumber');
      final token = prefs.getString('token');

      if (cdsNumber == null || cdsNumber.isEmpty) {
        setState(() {
          _ordersError = 'CDS number not found. Please log in again.';
          _isLoadingOrders = false;
        });
        return;
      }

      _cdsNumber = cdsNumber;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('https://zamagm.escrowagm.com/MainAPI/Home/GetMyOrders'),
        headers: headers,
        body: jsonEncode({'CDSNumber': cdsNumber}),
      );

      debugPrint('=== Orders API Response ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('===========================');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = _extractList(decoded);

        if (data.isEmpty) {
          setState(() {
            _ordersData = [];
            _isLoadingOrders = false;
          });
          return;
        }

        final parsed = data.where((item) => item is Map).map((item) {
          return <String, dynamic>{
            'orderType': item['OrderType']?.toString() ?? '-',
            'brokerCode': item['Broker_Code']?.toString() ?? '-',
            'status': item['OrderStatus']?.toString() ?? '-',
            'createDate':
            _formatDatetime(item['Create_date']?.toString() ?? ''),
          };
        }).toList();

        setState(() {
          _ordersData = parsed;
          _isLoadingOrders = false;
        });
      } else {
        setState(() {
          _ordersError =
          'Server error: ${response.statusCode}\n${response.body}';
          _isLoadingOrders = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Orders error: $e\n$stack');
      setState(() {
        _ordersError = 'Failed to load orders: $e';
        _isLoadingOrders = false;
      });
    }
  }

  void _refreshCurrentTab() {
    if (_selectedTab == 'PORTFOLIO') {
      _loadPortfolioFromApi();
    } else {
      _loadOrdersFromApi();
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────

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
              _buildSummaryCard(isDark),
              const SizedBox(height: 20),
              Expanded(
                child: _selectedTab == 'PORTFOLIO'
                    ? _buildPortfolioList(isDark)
                    : _buildOrdersList(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Tab selector
  // ─────────────────────────────────────────────────────────────

  Widget _buildTabSelector(bool isDark) {
    final accentColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
    final inactiveColor = isDark ? Colors.white54 : Colors.black45;
    final bgColor = isDark ? Colors.transparent : Colors.white.withOpacity(0.3);

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

  // ─────────────────────────────────────────────────────────────
  //  Summary card
  // ─────────────────────────────────────────────────────────────

  Widget _buildSummaryCard(bool isDark) {
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _selectedTab == 'PORTFOLIO'
          ? _buildPortfolioCard(isDark, cardGradient)
          : _buildOrdersCard(isDark, cardGradient),
    );
  }

  Widget _buildPortfolioCard(bool isDark, LinearGradient gradient) {
    final isLoading = _isLoadingPortfolio;
    final hasError = _portfolioError != null;
    final subtextColor = Colors.white.withOpacity(0.85);

    final valueText = isLoading
        ? 'Loading...'
        : (hasError ? '—' : _formatAmount(_totalPortfolioValue));

    return Container(
      key: const ValueKey('portfolio_card'),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
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
                'Total Portfolio Value',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
              if (_cdsNumber != null)
                Text(_cdsNumber!,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  valueText,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _refreshCurrentTab,
                child:
                const Icon(Icons.refresh, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.pie_chart_outline, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                '${_portfolioData.length} holding${_portfolioData.length == 1 ? '' : 's'}',
                style: TextStyle(color: subtextColor, fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.bar_chart, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                '${_formatAmount(_totalShares)} total shares',
                style: TextStyle(color: subtextColor, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersCard(bool isDark, LinearGradient gradient) {
    final capturedCount = _ordersData
        .where((o) => (o['status'] as String).toUpperCase() == 'CAPTURED')
        .length;

    return Container(
      key: const ValueKey('orders_card'),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
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
      child: Row(
        children: [
          Expanded(
            child: _summaryTile(
              label: 'Total Orders',
              value: _isLoadingOrders ? '—' : '${_ordersData.length}',
              icon: Icons.list_alt_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _summaryTile(
              label: 'Captured',
              value: _isLoadingOrders ? '—' : '$capturedCount',
              icon: Icons.check_circle_outline,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _summaryTile(
              label: 'Other',
              value: _isLoadingOrders
                  ? '—'
                  : '${_ordersData.length - capturedCount}',
              icon: Icons.pending_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(
      {required String label,
        required String value,
        required IconData icon}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label,
            style:
            TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Portfolio holdings list
  // ─────────────────────────────────────────────────────────────

  Widget _buildPortfolioList(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardBg = isDark
        ? const Color(0xFF2A2A2A).withOpacity(0.6)
        : Colors.white.withOpacity(0.85);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.grey.withOpacity(0.15);
    final subtleColor = isDark ? Colors.white54 : Colors.black45;
    final accentColor =
    isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);

    if (_isLoadingPortfolio) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_portfolioError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 44),
              const SizedBox(height: 12),
              Text(_portfolioError!,
                  style: TextStyle(color: textColor),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPortfolioFromApi,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_portfolioData.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                color: isDark ? Colors.white30 : Colors.black26, size: 52),
            const SizedBox(height: 12),
            Text('No holdings found.',
                style: TextStyle(color: subtleColor, fontSize: 15)),
          ],
        ),
      );
    }

    // Compute max value for the relative bar
    final maxValue = _portfolioData
        .map((h) => h['currentValue'] as double)
        .reduce((a, b) => a > b ? a : b);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _portfolioData.length,
      itemBuilder: (context, index) {
        final holding = _portfolioData[index];
        final company = holding['company'] as String;
        final shares = holding['totalShares'] as double;
        final value = holding['currentValue'] as double;
        final cds = holding['cdsNumber'] as String;
        final barFraction = maxValue > 0 ? value / maxValue : 0.0;

        // Pick a color per index for the company avatar
        final avatarColors = [
          const Color(0xFFD4A855),
          const Color(0xFF4CAF50),
          const Color(0xFF2196F3),
          const Color(0xFF9C27B0),
          const Color(0xFFFF5722),
          const Color(0xFF00BCD4),
        ];
        final avatarColor = avatarColors[index % avatarColors.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Avatar + Company name + Value ──
                Row(
                  children: [
                    // Company initial avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: avatarColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: avatarColor.withOpacity(0.4), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          company.isNotEmpty
                              ? company.substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: avatarColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Company name + CDS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cds,
                            style: TextStyle(
                                color: subtleColor, fontSize: 10),
                          ),
                        ],
                      ),
                    ),

                    // Current Value
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatAmount(value),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current Value',
                          style:
                          TextStyle(color: subtleColor, fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Row 2: Shares stat ──
                Row(
                  children: [
                    _holdingStatChip(
                      icon: Icons.layers_outlined,
                      label: 'Total Shares',
                      value: _formatAmount(shares),
                      isDark: isDark,
                      textColor: textColor,
                      subtleColor: subtleColor,
                    ),
                    const Spacer(),
                    // Percentage of total portfolio
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: accentColor.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        _totalPortfolioValue > 0
                            ? '${(value / _totalPortfolioValue * 100).toStringAsFixed(1)}% of portfolio'
                            : '0.0% of portfolio',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Relative value bar ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: barFraction.toDouble(),
                    minHeight: 5,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey.withOpacity(0.15),
                    valueColor:
                    AlwaysStoppedAnimation<Color>(avatarColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _holdingStatChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required Color textColor,
    required Color subtleColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: subtleColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: subtleColor, fontSize: 9)),
            Text(value,
                style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Orders list
  // ─────────────────────────────────────────────────────────────

  Widget _buildOrdersList(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardBg = isDark
        ? const Color(0xFF2A2A2A).withOpacity(0.6)
        : Colors.white.withOpacity(0.85);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.grey.withOpacity(0.15);
    final subtleColor = isDark ? Colors.white54 : Colors.black45;

    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ordersError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 44),
              const SizedBox(height: 12),
              Text(_ordersError!,
                  style: TextStyle(color: textColor),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadOrdersFromApi,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_ordersData.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                color: isDark ? Colors.white30 : Colors.black26, size: 52),
            const SizedBox(height: 12),
            Text('No orders found.',
                style: TextStyle(color: subtleColor, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _ordersData.length,
      itemBuilder: (context, index) {
        final order = _ordersData[index];
        final statusColor = _statusColor(order['status'] as String);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Type',
                              style: TextStyle(
                                  color: subtleColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(order['orderType'] as String,
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Broker Code',
                              style: TextStyle(
                                  color: subtleColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(order['brokerCode'] as String,
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Date',
                              style: TextStyle(
                                  color: subtleColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(order['createDate'] as String,
                              style:
                              TextStyle(color: subtleColor, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withOpacity(0.4), width: 1),
                      ),
                      child: Text(
                        order['status'] as String,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}