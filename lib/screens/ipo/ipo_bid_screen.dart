import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme_provider.dart';
import '../../widgets/app_message_dialog.dart';
import 'ipo_models.dart';

/// IPO application / bid screen — same ticket-style layout and colour
/// language as [QuickTradeScreen] (BUY/SELL order entry) so clients feel
/// at home moving between regular trading and IPO subscriptions.
class IpoBidScreen extends StatefulWidget {
  final IpoListing ipo;

  const IpoBidScreen({super.key, required this.ipo});

  @override
  State<IpoBidScreen> createState() => _IpoBidScreenState();
}

class _IpoBidScreenState extends State<IpoBidScreen> {
  final quantityController = TextEditingController();
  bool _agreedToDeclaration = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    quantityController.text = widget.ipo.minShares.toString();
    quantityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(quantityController.text) ?? 0;
  double get _considerationTotal => _quantity * widget.ipo.pricePerShare;

  void _stepQuantity(int delta) {
    final step = widget.ipo.minShares > 0 ? widget.ipo.minShares : 100;
    final next = (_quantity + delta * step)
        .clamp(widget.ipo.minShares, widget.ipo.maxShares);
    setState(() => quantityController.text = next.toString());
  }

  bool get _isValidQuantity =>
      _quantity >= widget.ipo.minShares && _quantity <= widget.ipo.maxShares;

  Future<void> _submitBid() async {
    if (!_isValidQuantity) {
      _showError(
          'Enter between ${widget.ipo.minShares} and ${widget.ipo.maxShares} shares');
      return;
    }
    if (!_agreedToDeclaration) {
      _showError('Please confirm the Application Declaration');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Mock submission — persisted locally so the client can see their
      // standing application. Swap for a real `Home/SubmitIpoBid` POST
      // once the backend endpoint exists.
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('ipo_bids') ?? [];
      raw.add(jsonEncode({
        'ipoId': widget.ipo.id,
        'company': widget.ipo.companyName,
        'ticker': widget.ipo.ticker,
        'quantity': _quantity,
        'pricePerShare': widget.ipo.pricePerShare,
        'total': _considerationTotal,
        'submittedAt': DateTime.now().toIso8601String(),
      }));
      await prefs.setStringList('ipo_bids', raw);

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
      showAppMessageDialog(
        context,
        isDark: isDark,
        type: AppMessageType.success,
        title: 'Application Submitted',
        message:
            'Your application for $_quantity shares of ${widget.ipo.companyName} '
            '(BWP ${_considerationTotal.toStringAsFixed(2)}) has been received. '
            'Allotment results will be communicated before the listing date.',
        buttonLabel: 'Done',
        onButtonPressed: () => Navigator.pop(context),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Could not submit application: $e');
    }
  }

  void _showError(String message) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showAppMessageDialog(
      context,
      isDark: isDark,
      type: AppMessageType.error,
      title: 'Could Not Submit',
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final ipo = widget.ipo;

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF2C1810), Color(0xFF1A1A1A), Color(0xFF0D0D0D)])
        : const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E7), Color(0xFFF5F5F5), Color(0xFFFFFFFF)]);

    final accentColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey : Colors.grey.shade600;
    final cardColor = isDark ? const Color(0xFF23201C) : Colors.white;
    final fieldBorderColor = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text('IPO Application',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── IPO summary tile ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [ipo.accentColor, ipo.accentColor.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 6)),
                          ],
                        ),
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
                                      Text(ipo.companyName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text('${ipo.ticker}  ·  ${ipo.sector}',
                                          style: const TextStyle(
                                              color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(ipo.statusLabel,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text('BWP ${ipo.pricePerShare.toStringAsFixed(2)} / share',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              'Closes in ${ipo.daysRemaining} day${ipo.daysRemaining == 1 ? '' : 's'} · '
                              'Lists ${_formatDate(ipo.listingDate)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Quantity stepper ──
                      Text(
                        'Shares applied for  (min ${ipo.minShares}, max ${ipo.maxShares})',
                        style: TextStyle(
                            color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isValidQuantity ? fieldBorderColor : Colors.red,
                          ),
                        ),
                        child: Row(
                          children: [
                            _stepperButton(Icons.remove, accentColor,
                                () => _stepQuantity(-1)),
                            Expanded(
                              child: TextField(
                                controller: quantityController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                    border: InputBorder.none, hintText: '0'),
                              ),
                            ),
                            _stepperButton(Icons.add, accentColor,
                                () => _stepQuantity(1)),
                          ],
                        ),
                      ),
                      if (!_isValidQuantity)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Quantity must be between ${ipo.minShares} and ${ipo.maxShares} shares',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // ── Subscription progress ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: fieldBorderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subscription level',
                                    style: TextStyle(color: subtextColor, fontSize: 12)),
                                Text('${ipo.subscriptionPercent.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        color: accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (ipo.subscriptionPercent / 100).clamp(0, 1),
                                minHeight: 8,
                                backgroundColor:
                                    isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Summary card ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accentColor.withOpacity(0.15), cardColor],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentColor.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            _summaryRow('Price per share',
                                'BWP ${ipo.pricePerShare.toStringAsFixed(2)}', subtextColor),
                            const SizedBox(height: 8),
                            _summaryRow('Shares applied for', '$_quantity', subtextColor),
                            const SizedBox(height: 4),
                            Divider(color: subtextColor.withOpacity(0.3)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('TOTAL CONSIDERATION',
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Text('BWP ${_considerationTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        color: accentColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Declaration checkbox ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _agreedToDeclaration
                                ? accentColor.withOpacity(0.6)
                                : fieldBorderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _agreedToDeclaration,
                              activeColor: accentColor,
                              onChanged: (value) =>
                                  setState(() => _agreedToDeclaration = value ?? false),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'I confirm the funds for this application are available and '
                                  'I accept the terms of the IPO prospectus.',
                                  style: TextStyle(color: textColor, fontSize: 12.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Sticky bottom action bar ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, -4)),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSubmitting ? null : _submitBid,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'SUBMIT APPLICATION',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepperButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(16), child: Icon(icon, color: color)),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
