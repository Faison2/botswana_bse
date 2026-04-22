import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme_provider.dart';
import '../../contants/constants.dart';

class TransactionsScreens extends StatefulWidget {
  const TransactionsScreens({super.key});

  @override
  State<TransactionsScreens> createState() => _TransactionsScreensState();
}

class _TransactionsScreensState extends State<TransactionsScreens>
    with SingleTickerProviderStateMixin {

  // ── State ──
  String? _selectedBroker;
  double _totalCashBalance = 0.0;
  double _weeklyChange     = 0.0;
  double _weeklyChangePct  = 0.0;
  bool   _isLoadingBalance = false;
  bool   _isLoadingTx      = false;
  String? _txError;
  String  _cdsNumber       = '';

  List<Map<String, dynamic>> _transactions = [];

  // ── Animation ──
  late AnimationController _animController;
  late Animation<double>   _fadeAnim;

  static const List<String> _brokers = [
    'Motswedi Securities',
    'African Alliance',
    'Stockbrokers Botswana',
    'Imara',
    'Capital Securities',
  ];

  @override
  void initState() {
    super.initState();
    _selectedBroker = _brokers.first;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _cdsNumber       = prefs.getString('cdsNumber') ?? '';
      _totalCashBalance =
          prefs.getDouble('cachedCashBalance') ?? 0.0;
    });
    await _fetchBalance();
    await _fetchTransactions();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  API – Cash Balance
  // ─────────────────────────────────────────────────────────────

  Future<void> _fetchBalance() async {
    if (!mounted) return;
    setState(() => _isLoadingBalance = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final cds   = _cdsNumber.isNotEmpty
          ? _cdsNumber
          : (prefs.getString('cdsNumber') ?? '');

      final response = await http.post(
        Uri.parse('$baseUrl/Transactions/GetCashBalance'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'CDSNumber': cds, 'Broker': _selectedBroker}),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final balance =
            double.tryParse(data['cashBalance']?.toString() ?? '0') ?? 0.0;
        final change =
            double.tryParse(data['weeklyChange']?.toString() ?? '0') ?? 0.0;
        final pct =
            double.tryParse(data['weeklyChangePct']?.toString() ?? '0') ?? 0.0;

        await prefs.setDouble('cachedCashBalance', balance);

        setState(() {
          _totalCashBalance = balance;
          _weeklyChange     = change;
          _weeklyChangePct  = pct;
        });
      }
    } catch (_) {
      // Silently fail — cached value is already shown
    } finally {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  API – Transactions
  // ─────────────────────────────────────────────────────────────

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTx = true;
      _txError     = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final cds   = _cdsNumber.isNotEmpty
          ? _cdsNumber
          : (prefs.getString('cdsNumber') ?? '');

      final response = await http.post(
        Uri.parse('$baseUrl/Transactions/GetMyTransactions'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'CDSNumber': cds, 'Broker': _selectedBroker}),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        List<dynamic> raw = [];
        if (decoded is List) {
          raw = decoded;
        } else if (decoded is Map) {
          raw = decoded.values
              .firstWhere((v) => v is List, orElse: () => []) as List;
        }

        final txList = raw.whereType<Map>().map((item) {
          return <String, dynamic>{
            'date':        item['Date']?.toString()        ?? 'N/A',
            'description': item['Description']?.toString() ?? '-',
            'type':        item['Type']?.toString()        ?? 'Debit',
            'amount': double.tryParse(
                item['Amount']?.toString() ?? '0') ??
                0.0,
          };
        }).toList();

        setState(() => _transactions = txList);
      } else {
        setState(() => _txError = 'Server error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _txError = 'Could not load transactions');
    } finally {
      if (mounted) setState(() => _isLoadingTx = false);
    }
  }

  String _formatAmount(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  // ─────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;

        final bgColor      = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
        final surfaceColor = isDark ? const Color(0xFF1C1C1C) : Colors.white;
        final borderColor  = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0);
        final labelColor   = isDark ? Colors.white70          : Colors.black54;
        final textColor    = isDark ? Colors.white            : Colors.black87;
        final subColor     = isDark ? Colors.white38          : Colors.black38;
        const gold         = Color(0xFFB8860B);
        const goldLight    = Color(0xFFFFB300);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildTopBar(isDark, textColor),
                  Expanded(
                    child: RefreshIndicator(
                      color: goldLight,
                      onRefresh: () async {
                        await _fetchBalance();
                        await _fetchTransactions();
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          // ── Balance card ──
                          _buildBalanceCard(isDark),
                          const SizedBox(height: 20),

                          // ── Broker row ──
                          _buildBrokerRow(
                              isDark, surfaceColor, borderColor,
                              textColor, labelColor, gold),
                          const SizedBox(height: 20),

                          // ── Table header ──
                          _buildTableHeader(isDark, textColor),
                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 4),

                          // ── Rows ──
                          _buildTransactionRows(
                              isDark, surfaceColor, borderColor,
                              textColor, subColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Top bar
  // ─────────────────────────────────────────────────────────────

  Widget _buildTopBar(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: textColor, size: 18),
              ),
            ),
          if (Navigator.canPop(context)) const SizedBox(width: 12),
          Expanded(
            child: Text('My Transactions',
                style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3)),
          ),
          // Receipt icon badge
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                color: const Color(0xFF29B6F6), size: 20),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Balance card
  // ─────────────────────────────────────────────────────────────

  Widget _buildBalanceCard(bool isDark) {
    final isPositive = _weeklyChange >= 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B6914), Color(0xFF5C4400)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              const Expanded(
                child: Text('Total Cash Balance',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              GestureDetector(
                onTap: () {
                  _fetchBalance();
                  _fetchTransactions();
                },
                child: _isLoadingBalance
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white70))
                    : const Icon(Icons.refresh_rounded,
                    color: Colors.white70, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main amount
          Text(
            'BWP ${_formatAmount(_totalCashBalance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Weekly change
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isPositive
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFEF5350),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${_formatAmount(_weeklyChange)} '
                    '(${_weeklyChangePct.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: isPositive
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFEF5350),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Text('this week',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Broker row
  // ─────────────────────────────────────────────────────────────

  Widget _buildBrokerRow(
      bool isDark,
      Color surfaceColor,
      Color borderColor,
      Color textColor,
      Color labelColor,
      Color gold,
      ) {
    final fieldColor =
    isDark ? const Color(0xFF242424) : const Color(0xFFF0F0F0);

    return Row(
      children: [
        Text('Broker:',
            style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),

        // Dropdown
        Expanded(
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBroker,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white54 : Colors.black38,
                    size: 20),
                dropdownColor:
                isDark ? const Color(0xFF242424) : Colors.white,
                style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                items: _brokers.map((b) {
                  return DropdownMenuItem(
                    value: b,
                    child: Text(b,
                        style:
                        TextStyle(color: textColor, fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedBroker = val);
                  _fetchBalance();
                  _fetchTransactions();
                },
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Refresh icon
        GestureDetector(
          onTap: () {
            _fetchBalance();
            _fetchTransactions();
          },
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.04),
              shape: BoxShape.circle,
              border: Border.all(color: gold.withOpacity(0.3), width: 1),
            ),
            child: _isLoadingTx
                ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: gold))
                : Icon(Icons.refresh_rounded, color: gold, size: 18),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Table header
  // ─────────────────────────────────────────────────────────────

  Widget _buildTableHeader(bool isDark, Color textColor) {
    final style = TextStyle(
      color: textColor,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Date',        style: style)),
          Expanded(flex: 3, child: Text('Description', style: style)),
          Expanded(flex: 2, child: Text('Type',        style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Amount',      style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Transaction rows
  // ─────────────────────────────────────────────────────────────

  Widget _buildTransactionRows(
      bool isDark,
      Color surfaceColor,
      Color borderColor,
      Color textColor,
      Color subColor,
      ) {
    // Loading
    if (_isLoadingTx && _transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error
    if (_txError != null && _transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: Colors.red.shade300, size: 40),
              const SizedBox(height: 10),
              Text(_txError!,
                  style: TextStyle(color: subColor, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: _fetchTransactions,
                icon: const Icon(Icons.refresh,
                    color: Color(0xFFFFB300)),
                label: const Text('Retry',
                    style: TextStyle(color: Color(0xFFFFB300))),
              ),
            ],
          ),
        ),
      );
    }

    // Empty
    if (_transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined,
                  color: subColor, size: 48),
              const SizedBox(height: 12),
              Text('No transactions found',
                  style: TextStyle(color: subColor, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _transactions.asMap().entries.map((entry) {
        final i  = entry.key;
        final tx = entry.value;
        return _buildTxRow(tx, i, isDark, borderColor, textColor, subColor);
      }).toList(),
    );
  }

  Widget _buildTxRow(
      Map<String, dynamic> tx,
      int index,
      bool isDark,
      Color borderColor,
      Color textColor,
      Color subColor,
      ) {
    final isCredit = (tx['type'] as String).toLowerCase() == 'credit';
    final amount   = tx['amount'] as double;

    final typeColor  = isCredit ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);
    final typeBg     = typeColor.withOpacity(0.15);
    final amountColor = isCredit
        ? const Color(0xFF4CAF50)
        : const Color(0xFF4CAF50); // matches screenshot (green for both)

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Date
              Expanded(
                flex: 2,
                child: Text(
                  tx['date'] as String,
                  style: TextStyle(
                      color: subColor, fontSize: 12, height: 1.3),
                ),
              ),

              // Description
              Expanded(
                flex: 3,
                child: Text(
                  tx['description'] as String,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Type badge
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCredit ? 'Credit' : 'Debit',
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),

              // Amount
              Expanded(
                flex: 2,
                child: Text(
                  'BWP ${_formatAmount(amount)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: borderColor, height: 1),
      ],
    );
  }
}