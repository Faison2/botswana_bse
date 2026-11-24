import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme_provider.dart';
import 'absa_service.dart';

/// ABSA brand palette, sampled from assets/absa.png.
class AbsaColors {
  static const Color red = Color(0xFFDC0032);
  static const Color redBright = Color(0xFFE8073F);
  static const Color redDeep = Color(0xFFA30027);
  static const Color redInk = Color(0xFF6E001B);
  static const Color gold = Color(0xFFD4A95A);
}

class AbsaDepositScreen extends StatefulWidget {
  /// Brokers to choose from: each map holds brokerCode / brokerName /
  /// cdsAccount. When empty the screen loads them from prefs itself.
  final List<Map<String, String>> brokers;
  final int initialBrokerIndex;

  const AbsaDepositScreen({
    super.key,
    this.brokers = const [],
    this.initialBrokerIndex = 0,
  });

  @override
  State<AbsaDepositScreen> createState() => _AbsaDepositScreenState();
}

class _AbsaDepositScreenState extends State<AbsaDepositScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final FocusNode _cardFocus = FocusNode();
  final FocusNode _expiryFocus = FocusNode();
  final FocusNode _cvvFocus = FocusNode();

  List<Map<String, String>> _brokers = [];
  int _selectedBroker = 0;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
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

    // PREVIEW-SEED-START
    _cardController.text = '4111  1111  1111  1111';
    _expiryController.text = '12 / 2031';
    _cvvController.text = '123';
    _amountController.text = '1500.00';
    // PREVIEW-SEED-END
    _brokers = List<Map<String, String>>.from(widget.brokers);
    _selectedBroker = widget.initialBrokerIndex < _brokers.length
        ? widget.initialBrokerIndex
        : 0;
    if (_brokers.isEmpty) _loadBrokers();

    // Repaint the card face as the user types.
    for (final c in [_cardController, _expiryController, _cvvController]) {
      c.addListener(() => setState(() {}));
    }
    for (final f in [_cardFocus, _expiryFocus, _cvvFocus]) {
      f.addListener(() => setState(() {}));
    }
  }

  Future<void> _loadBrokers() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final int count = prefs.getInt('activeBrokersCount') ?? 0;
    final List<Map<String, String>> brokers = [];

    if (count > 0) {
      for (int i = 0; i < count; i++) {
        brokers.add({
          'brokerCode': prefs.getString('broker_${i}_BrokerCode') ?? '',
          'cdsAccount': prefs.getString('broker_${i}_CDSAccount') ?? '',
          'brokerName': prefs.getString('broker_${i}_BrokerName') ?? '',
        });
      }
    } else {
      final code = prefs.getString('BrokerCode') ?? '';
      if (code.isNotEmpty) {
        brokers.add({
          'brokerCode': code,
          'cdsAccount': prefs.getString('CDSAccount') ?? '',
          'brokerName': prefs.getString('BrokerName') ?? '',
        });
      }
    }

    setState(() {
      _brokers = brokers;
      _selectedBroker = 0;
    });
  }

  bool _isDark = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDark = context.read<ThemeProvider>().isDarkMode;
  }

  @override
  void dispose() {
    // The header is always ABSA red, so this screen forces light status-bar
    // icons; hand the app's own style back on the way out.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: _isDark ? Brightness.dark : Brightness.light,
      ),
    );
    _animController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _amountController.dispose();
    _cardFocus.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  // ── Derived card state ──

  String get _cardDigits => _cardController.text.replaceAll(' ', '');
  String get _brand => AbsaCard.brand(_cardDigits);

  /// The field shows 'MM / YYYY'; the API wants the two parts separately.
  String get _expiryDigits =>
      _expiryController.text.replaceAll(RegExp(r'[^0-9]'), '');

  String get _expiryMonth =>
      _expiryDigits.length >= 2 ? _expiryDigits.substring(0, 2) : '';

  String get _expiryYear =>
      _expiryDigits.length >= 6 ? _expiryDigits.substring(2, 6) : '';

  // ── Submit ──

  Future<void> _pay() async {
    final amount = double.tryParse(_amountController.text.trim());

    if (_brokers.isEmpty) {
      _showSnack('No active broker account found. Please log in again.');
      return;
    }
    if (_cardDigits.isEmpty) {
      _showSnack('Please enter your card number');
      _cardFocus.requestFocus();
      return;
    }
    if (!AbsaCard.isValidNumber(_cardDigits)) {
      _showSnack('That card number doesn\'t look right. Please check it.');
      _cardFocus.requestFocus();
      return;
    }
    if (!AbsaCard.isValidExpiry(_expiryMonth, _expiryYear)) {
      _showSnack('Please enter a valid expiry date (MM/YYYY)');
      _expiryFocus.requestFocus();
      return;
    }
    if (_cvvController.text.length < AbsaCard.cvvLength(_cardDigits)) {
      _showSnack(
        'Please enter the ${AbsaCard.cvvLength(_cardDigits)}-digit '
        'security code on your card',
      );
      _cvvFocus.requestFocus();
      return;
    }
    if (amount == null || amount <= 0) {
      _showSnack('Please enter a valid amount');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final result = await AbsaService.deposit(
      brokerCode: _brokers[_selectedBroker]['brokerCode'] ?? '',
      amount: amount,
      cardNumber: _cardDigits,
      expiryMonth: _expiryMonth,
      expiryYear: _expiryYear,
      cvv: _cvvController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _clearCard();
      _showResultSheet(result, amount);
    } else if (result.timedOut) {
      _showTimeoutSheet(result, amount);
    } else {
      _showResultSheet(result, amount);
    }
  }

  void _clearCard() {
    _cardController.clear();
    _expiryController.clear();
    _cvvController.clear();
    _amountController.clear();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AbsaColors.redDeep,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ── Result sheets ──

  void _showResultSheet(AbsaResult result, double amount) {
    final bool ok = result.success;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !ok,
      enableDrag: !ok,
      builder: (ctx) => _ResultSheet(
        icon: ok ? Icons.check_rounded : Icons.close_rounded,
        accent: ok ? const Color(0xFF16A34A) : AbsaColors.red,
        title: result.title,
        message: result.message,
        amount: ok ? amount : null,
        reference: result.reference.isNotEmpty && result.reference != '0'
            ? result.reference
            : null,
        primaryLabel: ok ? 'DONE' : 'TRY AGAIN',
        onPrimary: () {
          Navigator.of(ctx).pop();
          if (ok) Navigator.of(context).pop(true);
        },
        secondaryLabel: ok ? null : 'CLOSE',
        onSecondary: ok
            ? null
            : () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(false);
              },
      ),
    );
  }

  /// A timeout means the card may already have been charged, so the only safe
  /// action is to look the reference up — never to resend.
  void _showTimeoutSheet(AbsaResult result, double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // A timeout can leave us without a reference to look up. In that case
        // the only honest advice is to check the balance rather than retry.
        final bool canCheck = result.reference.isNotEmpty;
        return _ResultSheet(
          icon: Icons.schedule_rounded,
          accent: const Color(0xFFD97706),
          title: 'Still Processing',
          message: canCheck
              ? result.message
              : '${result.message}\n\nPlease check your balance before '
                    'trying again, or contact support.',
          amount: null,
          reference: canCheck ? result.reference : null,
          primaryLabel: canCheck ? 'CHECK STATUS' : 'CLOSE',
          onPrimary: () async {
            Navigator.of(ctx).pop();
            if (!canCheck) {
              Navigator.of(context).pop(false);
              return;
            }
            setState(() => _isLoading = true);
            final status = await AbsaService.checkStatus(result.reference);
            if (!mounted) return;
            setState(() => _isLoading = false);
            if (status.success) _clearCard();
            _showResultSheet(status, amount);
          },
          secondaryLabel: canCheck ? 'CLOSE' : null,
          onSecondary: canCheck ? () => Navigator.of(ctx).pop() : null,
        );
      },
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF6F2F3);
        final surface = isDark ? const Color(0xFF1A1618) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final labelColor = isDark ? Colors.white60 : Colors.black54;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: bg,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                // Brand wash behind the header so the card sits on ABSA red.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.42,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AbsaColors.redDeep, AbsaColors.red],
                          ),
                        ),
                        child: CustomPaint(painter: _RingsPainter()),
                      ),
                      // Melts the wash into the page so there is no hard edge.
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [bg.withOpacity(0), bg],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          _buildTopBar(),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCardFace(),
                                  const SizedBox(height: 20),
                                  _buildAmountCard(
                                    isDark,
                                    surface,
                                    textColor,
                                    labelColor,
                                  ),
                                  if (_brokers.length > 1) ...[
                                    const SizedBox(height: 16),
                                    _buildBrokerCard(
                                      isDark,
                                      surface,
                                      textColor,
                                      labelColor,
                                    ),
                                  ] else if (_brokers.length == 1) ...[
                                    const SizedBox(height: 16),
                                    _buildSingleBroker(
                                      isDark,
                                      surface,
                                      textColor,
                                      labelColor,
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  _buildSecurityNote(labelColor),
                                ],
                              ),
                            ),
                          ),
                          _buildPayBar(isDark, surface),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CARD DEPOSIT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pay with ABSA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/absa.png', width: 34, height: 34),
          ),
        ],
      ),
    );
  }

  // ── The card face: inputs live directly on the plastic ──

  Widget _buildCardFace() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AbsaColors.redInk.withOpacity(0.45),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AbsaColors.redBright,
                      AbsaColors.red,
                      AbsaColors.redDeep,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _CardSheenPainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chip + contactless + brand
                  Row(
                    children: [
                      const _Chip(),
                      const SizedBox(width: 12),
                      Transform.rotate(
                        angle: math.pi / 2,
                        child: Icon(
                          Icons.wifi_rounded,
                          color: Colors.white.withOpacity(0.85),
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _brand.isEmpty
                            ? const SizedBox(key: ValueKey('none'))
                            : Container(
                                key: ValueKey(_brand),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _brand,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _cardLabel('CARD NUMBER'),
                  const SizedBox(height: 4),
                  _cardField(
                    controller: _cardController,
                    focusNode: _cardFocus,
                    hint: '0000  0000  0000  0000',
                    fontSize: 21,
                    letterSpacing: 1.6,
                    keyboardType: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(19),
                      _CardNumberFormatter(),
                    ],
                    onSubmitted: (_) => _expiryFocus.requestFocus(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardLabel('VALID THRU'),
                            const SizedBox(height: 4),
                            _cardField(
                              controller: _expiryController,
                              focusNode: _expiryFocus,
                              hint: 'MM / YYYY',
                              fontSize: 16,
                              letterSpacing: 1.2,
                              keyboardType: TextInputType.number,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                                _ExpiryFormatter(),
                              ],
                              onSubmitted: (_) => _cvvFocus.requestFocus(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardLabel('CVV'),
                            const SizedBox(height: 4),
                            _cardField(
                              controller: _cvvController,
                              focusNode: _cvvFocus,
                              hint: _brand == 'AMEX' ? '••••' : '•••',
                              fontSize: 16,
                              letterSpacing: 3,
                              obscure: true,
                              keyboardType: TextInputType.number,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                  AbsaCard.cvvLength(_cardDigits),
                                ),
                              ],
                              onSubmitted: (_) =>
                                  FocusScope.of(context).unfocus(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardLabel(String text) => Text(
    text,
    style: TextStyle(
      color: Colors.white.withOpacity(0.72),
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
    ),
  );

  Widget _cardField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required double fontSize,
    required double letterSpacing,
    required TextInputType keyboardType,
    required List<TextInputFormatter> formatters,
    bool obscure = false,
    ValueChanged<String>? onSubmitted,
  }) {
    final bool focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          obscuringCharacter: '•',
          keyboardType: keyboardType,
          inputFormatters: formatters,
          textInputAction: TextInputAction.next,
          onSubmitted: onSubmitted,
          cursorColor: Colors.white,
          cursorWidth: 1.6,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: letterSpacing,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 6),
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.38),
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              letterSpacing: letterSpacing,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: focused ? 2 : 1,
          color: Colors.white.withOpacity(focused ? 0.95 : 0.35),
        ),
      ],
    );
  }

  // ── Amount ──

  Widget _buildAmountCard(
    bool isDark,
    Color surface,
    Color textColor,
    Color labelColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: _panel(isDark, surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AbsaColors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: AbsaColors.red,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Amount to deposit',
                style: TextStyle(
                  color: labelColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'BWP',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: (_) => setState(() {}),
                  cursorColor: AbsaColors.red,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '0.00',
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 34,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(height: 1, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['100', '500', '1000', '5000'].map((amt) {
              final selected = _amountController.text == amt;
              return GestureDetector(
                onTap: () => setState(() {
                  _amountController.text = amt;
                  _amountController.selection = TextSelection.collapsed(
                    offset: _amountController.text.length,
                  );
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AbsaColors.red
                        : AbsaColors.red.withOpacity(isDark ? 0.14 : 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AbsaColors.red.withOpacity(selected ? 1 : 0.25),
                    ),
                  ),
                  child: Text(
                    'P $amt',
                    style: TextStyle(
                      color: selected ? Colors.white : AbsaColors.red,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
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

  // ── Broker ──

  Widget _buildBrokerCard(
    bool isDark,
    Color surface,
    Color textColor,
    Color labelColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      decoration: _panel(isDark, surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deposit into',
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_brokers.length, (i) {
            final b = _brokers[i];
            final selected = i == _selectedBroker;
            return GestureDetector(
              onTap: () => setState(() => _selectedBroker = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AbsaColors.red.withOpacity(isDark ? 0.16 : 0.06)
                      : (isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.black.withOpacity(0.02)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AbsaColors.red
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AbsaColors.red : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? AbsaColors.red
                              : (isDark ? Colors.white30 : Colors.black26),
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 11,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b['brokerName']?.isNotEmpty == true
                                ? b['brokerName']!
                                : (b['brokerCode'] ?? ''),
                            style: TextStyle(
                              color: selected ? AbsaColors.red : textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${b['brokerCode']}  ·  ${b['cdsAccount']}',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSingleBroker(
    bool isDark,
    Color surface,
    Color textColor,
    Color labelColor,
  ) {
    final b = _brokers.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: _panel(isDark, surface),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AbsaColors.red.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AbsaColors.red,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deposit into',
                  style: TextStyle(color: labelColor, fontSize: 11.5),
                ),
                const SizedBox(height: 3),
                Text(
                  b['brokerName']?.isNotEmpty == true
                      ? '${b['brokerName']} · ${b['brokerCode']}'
                      : (b['brokerCode'] ?? ''),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote(Color labelColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: labelColor),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Secured by ABSA · Your card is charged once and its details are '
            'never stored on this device.',
            style: TextStyle(color: labelColor, fontSize: 11.5, height: 1.45),
          ),
        ),
      ],
    );
  }

  Widget _buildPayBar(bool isDark, Color surface) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        14,
        18,
        16 + MediaQuery.of(context).viewPadding.bottom * 0.2,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _isLoading ? null : _pay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: _isLoading
                  ? [Colors.grey.shade600, Colors.grey.shade500]
                  : const [AbsaColors.red, AbsaColors.redBright],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isLoading
                ? []
                : [
                    BoxShadow(
                      color: AbsaColors.red.withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
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
                    Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'PAY SECURELY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  BoxDecoration _panel(bool isDark, Color surface) => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

// ── Reusable pieces ──────────────────────────────────────────────────────────

/// The gold EMV chip on the card face.
class _Chip extends StatelessWidget {
  const _Chip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8CB8A), AbsaColors.gold, Color(0xFFB98F3E)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomPaint(painter: _ChipPainter()),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B6914).withOpacity(0.55)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * 0.33),
      Offset(size.width, size.height * 0.33),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.67),
      Offset(size.width, size.height * 0.67),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.3,
          size.height * 0.33,
          size.width * 0.4,
          size.height * 0.34,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..color = const Color(0xFFF0DCA8)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Concentric ABSA rings, echoing the logo, on the card face.
class _CardSheenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.93, size.height * 0.42);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 1.2;
    for (double r = 22; r < size.width * 0.95; r += 17) {
      canvas.drawCircle(center, r, ring);
    }
    // Soft diagonal highlight.
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width * 0.55, 0)
        ..lineTo(size.width * 0.78, 0)
        ..lineTo(0, size.height * 0.62)
        ..close(),
      Paint()..color = Colors.white.withOpacity(0.055),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Large faint rings behind the header.
class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.15, size.height * 0.1);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 1.4;
    for (double r = 40; r < size.width; r += 34) {
      canvas.drawCircle(center, r, ring);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom sheet used for success / declined / timeout outcomes.
class _ResultSheet extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final double? amount;
  final String? reference;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _ResultSheet({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.amount,
    required this.reference,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final surface = isDark ? const Color(0xFF1A1618) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 26),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: labelColor, fontSize: 13.5, height: 1.5),
            ),
            if (amount != null) ...[
              const SizedBox(height: 18),
              Text(
                'BWP ${amount!.toStringAsFixed(2)}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (reference != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFERENCE',
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SelectableText(
                      reference!,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (secondaryLabel != null) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: onSecondary,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          secondaryLabel!,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: onPrimary,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        primaryLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input formatters ─────────────────────────────────────────────────────────

/// Groups the card number into blocks of four as it is typed.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Renders the expiry as MM / YYYY while the user types six digits.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)} / ${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ── Entry point used on the deposit screens ──────────────────────────────────

/// The red "Pay with an ABSA bank card" banner that opens [AbsaDepositScreen].
///
/// [brokers] may be empty — the screen then loads the active brokers from
/// prefs itself. [onCompleted] fires when a deposit went through, so the host
/// screen can refresh the balance.
class AbsaDepositButton extends StatelessWidget {
  final bool isDark;
  final List<Map<String, String>> brokers;
  final int initialBrokerIndex;
  final VoidCallback? onCompleted;

  const AbsaDepositButton({
    super.key,
    required this.isDark,
    this.brokers = const [],
    this.initialBrokerIndex = 0,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 320),
            pageBuilder: (_, __, ___) => AbsaDepositScreen(
              brokers: brokers,
              initialBrokerIndex: initialBrokerIndex,
            ),
            transitionsBuilder: (_, animation, __, child) => SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: FadeTransition(opacity: animation, child: child),
            ),
          ),
        );
        if (result == true) onCompleted?.call();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AbsaColors.redDeep, AbsaColors.red, AbsaColors.redBright],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AbsaColors.red.withOpacity(isDark ? 0.35 : 0.3),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/absa.png', width: 32, height: 32),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay with an ABSA bank card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Instant deposit by debit or credit card',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "or deposit with mobile money" rule, matching the web dialog.
class AbsaOrDivider extends StatelessWidget {
  final bool isDark;
  final String label;

  const AbsaOrDivider({
    super.key,
    required this.isDark,
    this.label = 'or deposit with mobile money',
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? Colors.white12 : Colors.black12;
    final text = isDark ? Colors.white38 : Colors.black38;
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: line)),
      ],
    );
  }
}
