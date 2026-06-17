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
  String  _mainCurrency       = 'BWP';
  bool    _isLoadingBalance   = false;
  bool    _isLoadingTx        = false;
  String? _balanceError;
  String? _txError;
  String  _cdsAccount  = '';
  String  _brokerCode  = '';

  // ── Multi-broker ──
  List<Map<String, String>> _activeBrokers     = [];
  int                       _selectedBrokerIndex = 0;

  // ── Per-broker balances from API ──
  // keyed by brokerCode
  Map<String, Map<String, dynamic>> _perBrokerBalance = {};

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

    // ── Load all active brokers ──
    final int count = prefs.getInt('activeBrokersCount') ?? 0;
    final List<Map<String, String>> brokers = [];

    if (count > 0) {
      for (int i = 0; i < count; i++) {
        brokers.add({
          'brokerCode': prefs.getString('broker_${i}_BrokerCode') ?? '',
          'cdsAccount': prefs.getString('broker_${i}_CDSAccount') ?? '',
          'brokerName': prefs.getString('broker_${i}_BrokerName') ?? '',
          'status':     prefs.getString('broker_${i}_Status')     ?? '',
        });
      }
    } else {
      // Fallback: legacy single-broker keys
      final code = prefs.getString('BrokerCode') ?? '';
      final cds  = prefs.getString('CDSAccount') ?? '';
      final name = prefs.getString('BrokerName') ?? '';
      if (code.isNotEmpty) {
        brokers.add({
          'brokerCode': code,
          'cdsAccount': cds,
          'brokerName': name,
          'status': 'ACTIVE',
        });
      }
    }

    setState(() {
      _activeBrokers       = brokers;
      _selectedBrokerIndex = 0;
      _totalCashBalance    = prefs.getDouble('cachedCashBalance')   ?? 0.0;
      _lockedInOpenOrders  = prefs.getDouble('cachedLockedBalance') ?? 0.0;
      _applyBroker(0);
    });

    await Future.wait([_fetchBalance(), _fetchTransactions()]);
  }

  void _applyBroker(int index) {
    if (_activeBrokers.isEmpty) return;
    final b = _activeBrokers[index];
    _brokerCode = b['brokerCode'] ?? '';
    _cdsAccount = b['cdsAccount'] ?? '';
  }

  void _onBrokerChanged(int? index) {
    if (index == null) return;
    setState(() {
      _selectedBrokerIndex = index;
      _applyBroker(index);
    });
    _fetchTransactions();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  Derived: selected broker's balance (falls back to main)
  // ─────────────────────────────────────────────────────────────

  /// Returns the per-broker entry for the currently selected broker,
  /// or null if the API didn't return one (single-broker accounts).
  Map<String, dynamic>? get _selectedBrokerData {
    if (_perBrokerBalance.isEmpty) return null;
    return _perBrokerBalance[_brokerCode];
  }

  double get _displayBalance {
    final d = _selectedBrokerData;
    if (d != null) return (d['balance'] as num?)?.toDouble() ?? 0.0;
    return _totalCashBalance;
  }

  double get _displayLocked {
    final d = _selectedBrokerData;
    if (d != null) {
      return (d['lockedInOpenOrders'] as num?)?.toDouble() ?? 0.0;
    }
    return _lockedInOpenOrders;
  }

  bool get _isMultiBroker => _perBrokerBalance.length > 1;

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

      final response = await http.get(
        Uri.parse('https://zamagm.escrowagm.com/MainAPI/Home/GetMainWalletBalance'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['responseCode'] == 0) {
          final balance  = (data['mainWalletBalance']       as num?)?.toDouble() ?? 0.0;
          final locked   = (data['totalLockedInOpenOrders'] as num?)?.toDouble() ?? 0.0;
          final currency = data['currency']?.toString() ?? 'BWP';

          await prefs.setDouble('cachedCashBalance',  balance);
          await prefs.setDouble('cachedLockedBalance', locked);

          // ── Parse perBroker array ──
          final Map<String, Map<String, dynamic>> perBroker = {};
          final rawList = data['perBroker'];
          if (rawList is List) {
            for (final item in rawList) {
              if (item is Map) {
                final code = item['brokerCode']?.toString() ?? '';
                if (code.isNotEmpty) {
                  perBroker[code] = {
                    'brokerCode':         code,
                    'cdsAccount':         item['cdsAccount']?.toString() ?? '',
                    'balance':            (item['balance']             as num?)?.toDouble() ?? 0.0,
                    'lockedInOpenOrders': (item['lockedInOpenOrders']  as num?)?.toDouble() ?? 0.0,
                  };
                }
              }
            }
          }

          if (mounted) {
            setState(() {
              _totalCashBalance   = balance;
              _lockedInOpenOrders = locked;
              _mainCurrency       = currency;
              _perBrokerBalance   = perBroker;
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
      case 'SUCCESSFUL': return const Color(0xFF4CAF50);
      case 'FAILED':     return const Color(0xFFEF5350);
      case 'REJECTED':   return const Color(0xFFE53935);
      case 'PENDING':    return const Color(0xFFFFB300);
      case 'PAUSED':     return const Color(0xFFFFB300);
      default:
        if (status.toUpperCase().contains('INSUFFICIENT') ||
            status.toUpperCase().contains('LIMIT')) {
          return const Color(0xFFFF7043);
        }
        return Colors.grey;
    }
  }

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

                          // ── Broker dropdown (only when multiple brokers) ──
                          if (_activeBrokers.length > 1) ...[
                            _buildBrokerDropdown(isDark, textColor, subColor),
                            const SizedBox(height: 16),
                          ],

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
  //  Balance card  (per-broker + optional main total footer)
  // ─────────────────────────────────────────────────────────────

  Widget _buildBalanceCard() {
    final brokerData   = _selectedBrokerData;
    final showPerBroker = brokerData != null;

    // Label: broker name if available, else generic
    String cardTitle = 'Wallet Balance';
    if (showPerBroker && _activeBrokers.isNotEmpty) {
      final name = _activeBrokers[_selectedBrokerIndex]['brokerName'] ?? '';
      cardTitle = name.isNotEmpty ? '$name Balance' : '${_brokerCode} Balance';
    }

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
          // ── Title row ──
          Row(
            children: [
              Expanded(
                child: Text(
                  cardTitle,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
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

          // ── Primary balance ──
          if (_balanceError != null)
            Text(_balanceError!,
                style: const TextStyle(color: Colors.white54, fontSize: 14))
          else
            Text(
              '$_mainCurrency ${_formatAmount(_displayBalance)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
          const SizedBox(height: 10),

          // ── Locked in orders ──
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: Colors.white54, size: 15),
              const SizedBox(width: 5),
              Text(
                'Locked in orders: $_mainCurrency ${_formatAmount(_displayLocked)}',
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),

          // ── Main wallet total (only shown for multi-broker) ──
          if (_isMultiBroker) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white38, size: 15),
                  const SizedBox(width: 8),
                  Text(
                    'Total across all brokers:',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '$_mainCurrency ${_formatAmount(_totalCashBalance)}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Broker dropdown
  // ─────────────────────────────────────────────────────────────

  Widget _buildBrokerDropdown(bool isDark, Color textColor, Color subColor) {
    const gold       = Color(0xFFB8860B);
    const goldLight  = Color(0xFFFFB300);
    final fieldColor  = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDDDDD);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Broker',
          style: TextStyle(
            color: subColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedBrokerIndex,
              isExpanded: true,
              dropdownColor: fieldColor,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: goldLight, size: 22),
              onChanged: _onBrokerChanged,
              selectedItemBuilder: (context) {
                return List.generate(_activeBrokers.length, (i) {
                  final b        = _activeBrokers[i];
                  final bCode    = b['brokerCode'] ?? '';
                  final bData    = _perBrokerBalance[bCode];
                  final bBalance = bData != null
                      ? '$_mainCurrency ${_formatAmount((bData['balance'] as num?)?.toDouble() ?? 0.0)}'
                      : '';

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.business_rounded,
                            color: goldLight, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              b['brokerName'] ?? '',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              b['brokerCode'] ?? '',
                              style: TextStyle(color: subColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (bBalance.isNotEmpty)
                        Text(
                          bBalance,
                          style: const TextStyle(
                              color: goldLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                    ],
                  );
                });
              },
              items: List.generate(_activeBrokers.length, (i) {
                final b        = _activeBrokers[i];
                final bCode    = b['brokerCode'] ?? '';
                final isActive = i == _selectedBrokerIndex;
                final bData    = _perBrokerBalance[bCode];

                return DropdownMenuItem<int>(
                  value: i,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: borderColor.withOpacity(0.5),
                          width: i < _activeBrokers.length - 1 ? 1 : 0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isActive
                                ? goldLight.withOpacity(0.18)
                                : gold.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.business_rounded,
                            color: isActive ? goldLight : gold,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b['brokerName'] ?? '',
                                style: TextStyle(
                                  color: isActive ? goldLight : textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${b['brokerCode']}  ·  ${b['cdsAccount']}',
                                style: TextStyle(color: subColor, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                              // ── Per-broker balance inline in dropdown ──
                              if (bData != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  '$_mainCurrency ${_formatAmount((bData['balance'] as num?)?.toDouble() ?? 0.0)}',
                                  style: TextStyle(
                                    color: isActive
                                        ? goldLight
                                        : const Color(0xFFFFB300).withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: goldLight.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: goldLight,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
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
              Expanded(
                flex: 2,
                child: Text(
                  _formatDate(tx['date'] as String),
                  style: TextStyle(color: subColor, fontSize: 11, height: 1.4),
                ),
              ),
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