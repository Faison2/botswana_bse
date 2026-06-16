import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme_provider.dart';
import '../../contants/constants.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen>
    with SingleTickerProviderStateMixin {

  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  String _brokerCode       = '';
  String _brokerName       = '';
  String _mobileNumber     = '';
  String _cdsAccount       = '';
  double _availableBalance = 0.0;

  // All active brokers loaded from prefs
  List<Map<String, String>> _activeBrokers = [];
  int _selectedBrokerIndex = 0;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Load all active brokers saved by login
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
      _activeBrokers    = brokers;
      _mobileNumber     = prefs.getString('phoneNumber')       ?? '';
      _availableBalance = prefs.getDouble('cachedCashBalance') ?? 0.0;
      _selectedBrokerIndex = 0;
      _applyBroker(0);
    });
  }

  void _applyBroker(int index) {
    if (_activeBrokers.isEmpty) return;
    final b = _activeBrokers[index];
    _brokerCode  = b['brokerCode'] ?? '';
    _brokerName  = b['brokerName'] ?? '';
    _cdsAccount  = b['cdsAccount'] ?? '';
  }

  void _selectBroker(int index) {
    setState(() {
      _selectedBrokerIndex = index;
      _applyBroker(index);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _generateReferenceID() {
    final now = DateTime.now();
    final yy  = now.year.toString();
    final mo  = now.month.toString().padLeft(2, '0');
    final dd  = now.day.toString().padLeft(2, '0');
    final hh  = now.hour.toString().padLeft(2, '0');
    final mm  = now.minute.toString().padLeft(2, '0');
    final ss  = now.second.toString().padLeft(2, '0');
    return '$yy$mo$dd$hh$mm$ss';
  }

  Future<void> _submitWithdrawal() async {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      _showSnack('Please enter an amount', isError: true);
      return;
    }
    final parsed = double.tryParse(amount);
    if (parsed == null || parsed <= 0) {
      _showSnack('Please enter a valid amount', isError: true);
      return;
    }
    if (_availableBalance > 0 && parsed > _availableBalance) {
      _showSnack('Amount exceeds your available balance', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs       = await SharedPreferences.getInstance();
      final token       = prefs.getString('token') ?? '';
      final referenceID = _generateReferenceID();

      final response = await http.post(
        Uri.parse('https://zamagm.escrowagm.com/MainAPI/Home/MascomTransactions'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'IncomingTransaction': {
            'MobileNumber':    _mobileNumber,
            'Amount':          amount,
            'ReferenceID':     referenceID,
            'TransactionType': 'DISBURSEMENT',
            'BrokerCode':      _brokerCode,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is List
            ? decoded.first as Map<String, dynamic>
            : decoded as Map<String, dynamic>;

        if (data['responseCode'] == 0) {
          _showSnack(
            data['responseMessage'] ?? 'Withdrawal submitted successfully',
            isError: false,
          );
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          _showSnack(data['responseMessage'] ?? 'Withdrawal failed', isError: true);
        }
      } else {
        _showSnack('Server error ${response.statusCode}', isError: true);
      }
    } catch (_) {
      _showSnack('Network error. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: isError ? const Color(0xFFEF5350) : const Color(0xFF4CAF50),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: Duration(seconds: isError ? 3 : 5),
    ));
  }

  String _formatAmount(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;

        final bgColor      = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
        final surfaceColor = isDark ? const Color(0xFF1C1C1C) : Colors.white;
        final fieldColor   = isDark ? const Color(0xFF242424) : const Color(0xFFF0F0F0);
        final borderColor  = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDDDDD);
        final labelColor   = isDark ? Colors.white70          : Colors.black54;
        final textColor    = isDark ? Colors.white            : Colors.black87;
        final hintColor    = isDark ? Colors.white30          : Colors.black26;
        final iconColor    = isDark ? Colors.white38          : Colors.black26;
        final subTextColor = isDark ? Colors.white38          : Colors.black38;
        const red          = Color(0xFFEF5350);
        const redLight     = Color(0xFFFF7043);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    _buildTopBar(isDark, textColor, red),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBalanceBanner(isDark, red, subTextColor),
                            const SizedBox(height: 20),

                            _buildAmountHeroCard(
                                isDark, fieldColor, hintColor, textColor, red, redLight),
                            const SizedBox(height: 24),

                            // ── Broker selector (only when multiple brokers) ──
                            if (_activeBrokers.length > 1) ...[
                              _buildLabel('Select Broker', labelColor),
                              const SizedBox(height: 8),
                              _buildBrokerSelector(isDark, fieldColor, borderColor, textColor, red),
                              const SizedBox(height: 16),
                            ],

                            _buildLabel('CDS Account', labelColor),
                            const SizedBox(height: 8),
                            _buildLockedField(
                              value: _cdsAccount.isNotEmpty ? _cdsAccount : 'Not set',
                              isDark: isDark,
                              fieldColor: fieldColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              iconColor: iconColor,
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Broker Code', labelColor),
                            const SizedBox(height: 8),
                            _buildLockedField(
                              value: _brokerCode.isNotEmpty ? _brokerCode : 'Not set',
                              isDark: isDark,
                              fieldColor: fieldColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              iconColor: iconColor,
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Mobile Number', labelColor),
                            const SizedBox(height: 8),
                            _buildLockedField(
                              value: _mobileNumber.isNotEmpty ? _mobileNumber : 'Not set',
                              isDark: isDark,
                              fieldColor: fieldColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              iconColor: iconColor,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomButtons(isDark, surfaceColor, red, redLight),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Broker selector chips ──────────────────────────────────────────────────

  Widget _buildBrokerSelector(
      bool isDark,
      Color fieldColor,
      Color borderColor,
      Color textColor,
      Color red,
      ) {
    return Column(
      children: List.generate(_activeBrokers.length, (i) {
        final broker   = _activeBrokers[i];
        final selected = i == _selectedBrokerIndex;
        return GestureDetector(
          onTap: () => _selectBroker(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? red.withOpacity(isDark ? 0.18 : 0.08)
                  : fieldColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? red : borderColor,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Radio indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? red : borderColor,
                      width: 2,
                    ),
                    color: selected ? red : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
                const SizedBox(width: 14),
                // Broker info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        broker['brokerName'] ?? '',
                        style: TextStyle(
                          color: selected ? red : textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${broker['brokerCode']}  ·  ${broker['cdsAccount']}',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SELECTED',
                      style: TextStyle(
                        color: red,
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
    );
  }

  Widget _buildTopBar(bool isDark, Color textColor, Color red) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
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
          const SizedBox(width: 16),
          Expanded(
            child: Text('Withdraw Funds',
                style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFEF5350), Color(0xFFFF7043)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.remove_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('WITHDRAW',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceBanner(bool isDark, Color red, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: red.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.account_balance_wallet_outlined,
                color: red, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Balance',
                  style: TextStyle(color: subTextColor, fontSize: 11)),
              const SizedBox(height: 2),
              Text('P ${_formatAmount(_availableBalance)}',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() =>
            _amountController.text = _availableBalance.toStringAsFixed(2)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: red.withOpacity(0.25), width: 1),
              ),
              child: Text('MAX',
                  style: TextStyle(
                      color: red,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountHeroCard(bool isDark, Color fieldColor, Color hintColor,
      Color textColor, Color red, Color redLight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E0E0E), const Color(0xFF2A2A2A)]
              : [const Color(0xFFFFF0F0), const Color(0xFFFAE8E8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: red.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: red.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: red.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.payments_outlined, color: red, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Enter Amount (BWP)',
                  style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
            ],
            style: TextStyle(
                color: textColor,
                fontSize: 36,
                fontWeight: FontWeight.w300,
                letterSpacing: 1),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                  color: hintColor, fontSize: 36, fontWeight: FontWeight.w300),
              prefixText: 'P  ',
              prefixStyle: TextStyle(
                  color: red, fontSize: 28, fontWeight: FontWeight.w500),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['500', '1,000', '2,500', '5,000'].map((amt) {
              return GestureDetector(
                onTap: () => setState(
                        () => _amountController.text = amt.replaceAll(',', '')),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: red.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: red.withOpacity(0.28), width: 1),
                  ),
                  child: Text('P $amt',
                      style: TextStyle(
                          color: red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedField({
    required String value,
    required bool isDark,
    required Color fieldColor,
    required Color borderColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
          Icon(Icons.lock_outline_rounded, color: iconColor, size: 18),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(text,
        style: TextStyle(
            color: color,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2));
  }

  Widget _buildBottomButtons(
      bool isDark, Color surfaceColor, Color red, Color redLight) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6)),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.1),
                      width: 1),
                ),
                alignment: Alignment.center,
                child: Text('CLOSE',
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _isLoading ? null : _submitWithdrawal,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isLoading
                        ? [Colors.grey.shade700, Colors.grey.shade600]
                        : [red, redLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isLoading
                      ? []
                      : [
                    BoxShadow(
                        color: red.withOpacity(0.40),
                        blurRadius: 16,
                        offset: const Offset(0, 5)),
                  ],
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text('WITHDRAW',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}