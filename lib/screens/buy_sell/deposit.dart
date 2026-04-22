import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme_provider.dart';
import '../../contants/constants.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen>
    with SingleTickerProviderStateMixin {
  // ── Form state ──
  String? _selectedProvider;
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  // ── User data ──
  String _brokerCode  = 'MOTS';
  String _phoneNumber = '';
  String _cdsAccount  = '';

  // ── Animation ──
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const List<String> _providers = [
    'Botswana Telecommunications',
    'Orange Botswana',
    'Mascom Wireless',
    'MyZaka',
    'Standard Chartered',
    'First National Bank',
    'Absa Bank',
  ];

  @override
  void initState() {
    super.initState();
    _selectedProvider = _providers.first;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _brokerCode  = prefs.getString('brokerCode')  ?? 'MOTS';
      _phoneNumber = prefs.getString('phoneNumber') ?? '';
      _cdsAccount  = prefs.getString('cdsNumber')   ?? '';
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  Submit
  // ─────────────────────────────────────────────────────────────

  Future<void> _submitDeposit() async {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      _showSnack('Please enter an amount', isError: true);
      return;
    }
    if (double.tryParse(amount) == null || double.parse(amount) <= 0) {
      _showSnack('Please enter a valid amount', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/Transactions/Deposit'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'Provider':   _selectedProvider,
          'BrokerCode': _brokerCode,
          'Phone':      _phoneNumber,
          'Amount':     amount,
          'CDSAccount': _cdsAccount,
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseCode'] == 200) {
          _showSnack('Deposit initiated successfully!', isError: false);
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          _showSnack(data['message'] ?? 'Deposit failed', isError: true);
        }
      } else {
        _showSnack('Server error ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnack('Network error. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFEF5350) : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;

        // ── Color tokens ──
        final bgColor       = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
        final surfaceColor  = isDark ? const Color(0xFF1C1C1C) : Colors.white;
        final fieldColor    = isDark ? const Color(0xFF242424) : const Color(0xFFF0F0F0);
        final borderColor   = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDDDDD);
        final labelColor    = isDark ? Colors.white70          : Colors.black54;
        final textColor     = isDark ? Colors.white            : Colors.black87;
        final hintColor     = isDark ? Colors.white30          : Colors.black26;
        final iconColor     = isDark ? Colors.white38          : Colors.black26;
        final subTextColor  = isDark ? Colors.white38          : Colors.black38;
        const gold          = Color(0xFFB8860B);
        const goldLight     = Color(0xFFFFB300);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // ── Top bar ──
                    _buildTopBar(isDark, textColor, gold),

                    // ── Scrollable form body ──
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Amount hero card
                            _buildAmountHeroCard(
                              isDark, surfaceColor, fieldColor,
                              hintColor, textColor, gold, goldLight,
                            ),
                            const SizedBox(height: 24),

                            // Provider dropdown
                            _buildLabel('Select Provider', labelColor),
                            const SizedBox(height: 8),
                            _buildProviderDropdown(
                              isDark, fieldColor, borderColor, textColor, gold,
                            ),
                            const SizedBox(height: 20),

                            // Broker Code (read-only)
                            _buildLabel('Broker Code', labelColor),
                            const SizedBox(height: 8),
                            _buildLockedField(
                              value: _brokerCode,
                              isDark: isDark,
                              fieldColor: fieldColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              iconColor: iconColor,
                            ),
                            const SizedBox(height: 20),

                            // Phone Number (read-only)
                            _buildLabel('Phone Number', labelColor),
                            const SizedBox(height: 8),
                            _buildLockedField(
                              value: _phoneNumber.isNotEmpty
                                  ? _phoneNumber
                                  : 'Not set',
                              isDark: isDark,
                              fieldColor: fieldColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              iconColor: iconColor,
                            ),
                            const SizedBox(height: 28),

                            // CDS account info
                            if (_cdsAccount.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: gold.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: gold.withOpacity(0.2), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.account_balance_outlined,
                                        color: gold, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'CDS Account: $_cdsAccount',
                                        style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 12,
                                            letterSpacing: 0.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),

                    // ── Bottom action buttons ──
                    _buildBottomButtons(isDark, surfaceColor, gold, goldLight),
                  ],
                ),
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

  Widget _buildTopBar(bool isDark, Color textColor, Color gold) {
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
            child: Text(
              'Deposit Funds',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Gold accent badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B6914), Color(0xFFFFB300)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('ADD FUNDS',
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

  // ─────────────────────────────────────────────────────────────
  //  Amount hero card
  // ─────────────────────────────────────────────────────────────

  Widget _buildAmountHeroCard(
      bool isDark,
      Color surfaceColor,
      Color fieldColor,
      Color hintColor,
      Color textColor,
      Color gold,
      Color goldLight,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1A0E), const Color(0xFF2A2A2A)]
              : [const Color(0xFFFFF8E7), const Color(0xFFFAF0D7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
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
                  color: gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.payments_outlined, color: gold, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Enter Amount (BWP)',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
            ],
            style: TextStyle(
              color: textColor,
              fontSize: 36,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 36,
                fontWeight: FontWeight.w300,
              ),
              prefixText: 'P  ',
              prefixStyle: TextStyle(
                color: gold,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          // Quick-amount chips
          Wrap(
            spacing: 8,
            children: ['500', '1,000', '2,500', '5,000'].map((amt) {
              return GestureDetector(
                onTap: () => setState(() =>
                _amountController.text = amt.replaceAll(',', '')),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: gold.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    'P $amt',
                    style: TextStyle(
                      color: gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Provider dropdown
  // ─────────────────────────────────────────────────────────────

  Widget _buildProviderDropdown(
      bool isDark,
      Color fieldColor,
      Color borderColor,
      Color textColor,
      Color gold,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProvider,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white54 : Colors.black38),
          dropdownColor: isDark ? const Color(0xFF242424) : Colors.white,
          style: TextStyle(
              color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
          items: _providers.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(p,
                    style: TextStyle(color: textColor, fontSize: 15)),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedProvider = val),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Locked / read-only field
  // ─────────────────────────────────────────────────────────────

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
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.lock_outline_rounded, color: iconColor, size: 18),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Label
  // ─────────────────────────────────────────────────────────────

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Bottom buttons
  // ─────────────────────────────────────────────────────────────

  Widget _buildBottomButtons(
      bool isDark,
      Color surfaceColor,
      Color gold,
      Color goldLight,
      ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Close
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
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'CLOSE',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Deposit
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _isLoading ? null : _submitDeposit,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isLoading
                        ? [Colors.grey.shade700, Colors.grey.shade600]
                        : [gold, goldLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isLoading
                      ? []
                      : [
                    BoxShadow(
                      color: gold.withOpacity(0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'DEPOSIT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
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