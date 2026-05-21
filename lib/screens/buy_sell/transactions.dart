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
  double  _totalCashBalance   = 0.0;
  double  _lockedInOpenOrders = 0.0;
  bool    _isLoadingBalance   = false;
  bool    _isLoadingTx        = false;
  String? _balanceError;
  String? _txError;
  String  _cdsAccount  = '';
  String  _brokerCode  = '';

  List<Map<String, dynamic>> _transactions = [];

  // ── Animation ──
  late AnimationController _animController;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _cdsAccount         = prefs.getString('CDSAccount')  ?? '';
      _brokerCode         = prefs.getString('BrokerCode')  ?? '';
      _totalCashBalance   = prefs.getDouble('cachedCashBalance')   ?? 0.0;
      _lockedInOpenOrders = prefs.getDouble('cachedLockedBalance')  ?? 0.0;
    });
    // Run both calls in parallel
    await Future.wait([_fetchBalance(), _fetchTransactions()]);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  API 1 – Wallet balance
  // ─────────────────────────────────────────────────────────────

  Future<void> _fetchBalance() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBalance = true;
      _balanceError     = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final uri = Uri.parse(
        'https://zamagm.escrowagm.com/MainAPI/Home/GetMainWalletBalance',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['responseCode'] == 0) {
          final balance = double.tryParse(
              data['mainWalletBalance']?.toString() ?? '0') ?? 0.0;
          final locked  = double.tryParse(
              data['totalLockedInOpenOrders']?.toString() ?? '0') ?? 0.0;

          await prefs.setDouble('cachedCashBalance',  balance);
          await prefs.setDouble('cachedLockedBalance', locked);

          if (mounted) {
            setState(() {
              _totalCashBalance   = balance;
              _lockedInOpenOrders = locked;
            });
          }
        } else {
          setState(() => _balanceError = 'Could not load balance');
        }
      } else {
        setState(() => _balanceError = 'Balance error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _balanceError = 'Could not load balance');
    } finally {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  API 2 – Transactions
  // ─────────────────────────────────────────────────────────────

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTx = true;
      _txError     = null;
    });

    try {
      final prefs      = await SharedPreferences.getInstance();
      final token      = prefs.getString('token') ?? '';
      final brokerCode = _brokerCode.isNotEmpty
          ? _brokerCode
          : (prefs.getString('BrokerCode') ?? '');

      final uri = Uri.parse(
        'https://zamagm.escrowagm.com/MainAPI/Home/GetMyRecentTransactions'
            '?brokerCode=${Uri.encodeComponent(brokerCode)}&limit=20',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // responseCode 0 = success for this API
        if (data['responseCode'] == 0) {
          final raw = (data['transactions'] as List<dynamic>? ?? []);
          final txList = raw.whereType<Map>().map((item) {
            return <String, dynamic>{
              'reference': item['reference']?.toString()       ?? 'N/A',
              'provider':  item['provider']?.toString()        ?? '-',
              'source':    item['source']?.toString()          ?? '-',
              'status':    item['status']?.toString()          ?? 'UNKNOWN',
              'type':      item['transactionType']?.toString() ?? '-',
              'amount': double.tryParse(
                  item['amount']?.toString() ?? '0') ?? 0.0,
              'currency':  item['currency']?.toString()        ?? 'BWP',
              'date':      item['createdAt']?.toString()       ?? 'N/A',
            };
          }).toList();

          if (mounted) setState(() => _transactions = txList);
        } else {
          setState(() => _txError = 'No transactions available');
        }
      } else {
        setState(() => _txError = 'Server error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _txError = 'Could not load transactions');
    } finally {
      if (mounted) setState(() => _isLoadingTx = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Refresh both
  // ─────────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    await Future.wait([_fetchBalance(), _fetchTransactions()]);
  }

  // ─────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────

  String _formatAmount(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw.replaceFirst(' ', 'T'));
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month]}\n$h:$m';
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESSFUL':
        return const Color(0xFF4CAF50);
      case 'FAILED':
        return const Color(0xFFEF5350);
      case 'REJECTED':
        return const Color(0xFFE53935);
      case 'PENDING':
        return const Color(0xFFFFB300);
      case 'PAUSED':
        return const Color(0xFFFFB300);
      default:
      // Catches long strings like "INSUFFICIENT BALANCE OR DAILY LIMIT REACHED"
        if (status.toUpperCase().contains('INSUFFICIENT') ||
            status.toUpperCase().contains('LIMIT')) {
          return const Color(0xFFFF7043);
        }
        return Colors.grey;
    }
  }

  /// Short label for statuses that are too long to fit in the badge
  String _statusLabel(String status) {
    final upper = status.toUpperCase();
    if (upper.contains('INSUFFICIENT') || upper.contains('LIMIT')) {
      return 'LIMIT HIT';
    }
    return upper;
  }

  Color _typeColor(String type) {
    switch (type.toUpperCase()) {
      case 'DEPOSIT':      return const Color(0xFF4CAF50);
      case 'WITHDRAWAL':   return const Color(0xFFFF7043);
      case 'COLLECTION':   return const Color(0xFF29B6F6);
      case 'DISBURSEMENT': return const Color(0xFFAB47BC);
      default:             return Colors.grey;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark      = themeProvider.isDarkMode;
        final bgColor     = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
        final borderColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0);
        final textColor   = isDark ? Colors.white            : Colors.black87;
        final subColor    = isDark ? Colors.white38          : Colors.black38;
        const goldLight   = Color(0xFFFFB300);

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
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          _buildBalanceCard(),
                          const SizedBox(height: 20),

                          if (_cdsAccount.isNotEmpty || _brokerCode.isNotEmpty)
                            _buildAccountInfoRow(isDark, textColor, subColor),
                          if (_cdsAccount.isNotEmpty || _brokerCode.isNotEmpty)
                            const SizedBox(height: 20),

                          _buildTableHeader(isDark, textColor),
                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 4),

                          _buildTransactionRows(
                              isDark, borderColor, textColor, subColor),
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
          GestureDetector(
            onTap: _refresh,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: (_isLoadingTx || _isLoadingBalance)
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFFFB300)))
                  : const Icon(Icons.refresh_rounded,
                  color: Color(0xFF29B6F6), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Balance card
  // ─────────────────────────────────────────────────────────────

  Widget _buildBalanceCard() {
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
          Row(
            children: [
              const Expanded(
                child: Text('Main Wallet Balance',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              if (_isLoadingBalance)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 14),

          // Show error or amount
          if (_balanceError != null)
            Text(_balanceError!,
                style: const TextStyle(color: Colors.white54, fontSize: 14))
          else
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

          Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: Colors.white54, size: 15),
              const SizedBox(width: 5),
              Text(
                'Locked in orders: BWP ${_formatAmount(_lockedInOpenOrders)}',
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Account info row
  // ─────────────────────────────────────────────────────────────

  Widget _buildAccountInfoRow(bool isDark, Color textColor, Color subColor) {
    final chipBg = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.04);

    Widget chip(IconData icon, String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFFB300), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(color: subColor, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(Icons.credit_card_rounded,  'CDS Account', _cdsAccount),
        const SizedBox(width: 10),
        chip(Icons.business_rounded, 'Broker Code', _brokerCode),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Table header
  // ─────────────────────────────────────────────────────────────

  Widget _buildTableHeader(bool isDark, Color textColor) {
    final style = TextStyle(
      color: textColor,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Date',     style: style)),
          Expanded(flex: 2, child: Text('Provider', style: style)),
          Expanded(flex: 2, child: Text('Type',     style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Status',   style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Amount',   style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Transaction rows
  // ─────────────────────────────────────────────────────────────

  Widget _buildTransactionRows(
      bool isDark, Color borderColor, Color textColor, Color subColor) {
    if (_isLoadingTx && _transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_txError != null && _transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 40),
              const SizedBox(height: 10),
              Text(_txError!,
                  style: TextStyle(color: subColor, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: _fetchTransactions,
                icon: const Icon(Icons.refresh, color: Color(0xFFFFB300)),
                label: const Text('Retry',
                    style: TextStyle(color: Color(0xFFFFB300))),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, color: subColor, size: 48),
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
        return _buildTxRow(
            entry.value, entry.key, isDark, borderColor, textColor, subColor);
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
    final status   = tx['status']   as String;
    final type     = tx['type']     as String;
    final amount   = tx['amount']   as double;
    final currency = tx['currency'] as String;
    final provider = tx['provider'] as String;

    final statusColor = _statusColor(status);
    final typeColor   = _typeColor(type);
    final statusLabel = _statusLabel(status);

    // Amount colour: green for deposits, red/orange for withdrawals
    final amountColor = type.toUpperCase() == 'DEPOSIT'
        ? const Color(0xFF4CAF50)
        : type.toUpperCase() == 'WITHDRAWAL'
        ? const Color(0xFFFF7043)
        : textColor;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Date
              Expanded(
                flex: 2,
                child: Text(
                  _formatDate(tx['date'] as String),
                  style: TextStyle(color: subColor, fontSize: 11, height: 1.4),
                ),
              ),

              // Provider
              Expanded(
                flex: 2,
                child: Text(
                  provider,
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
                        horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type.isEmpty ? '-' : type,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: typeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2),
                    ),
                  ),
                ),
              ),

              // Status badge
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2),
                    ),
                  ),
                ),
              ),

              // Amount
              Expanded(
                flex: 2,
                child: Text(
                  '$currency\n${_formatAmount(amount)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: amountColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4),
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