import 'package:bse/contants/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import '../dashboard/dashboard.dart';

/// A redesigned order-entry screen (ticket style) that reuses the exact
/// same data/broker/order logic as [TradingPage], but with a different look:
/// a big BUY/SELL tile switch, a searchable company picker (bottom sheet),
/// a quantity stepper, and a sticky bottom action bar.
class QuickTradeScreen extends StatefulWidget {
  final bool initialIsBuy;
  final Map<String, dynamic>? prefilledStockData;
  final List<Map<String, dynamic>>? allStocks;

  const QuickTradeScreen({
    Key? key,
    this.initialIsBuy = true,
    this.prefilledStockData,
    this.allStocks,
  }) : super(key: key);

  @override
  State<QuickTradeScreen> createState() => _QuickTradeScreenState();
}

class _QuickTradeScreenState extends State<QuickTradeScreen> {
  late bool isBuy;
  bool isLoading = false;
  bool isFetchingStocks = false;
  String? _token;
  String? _userName;
  String? _cdsNumber;
  String? _phoneNumber;
  String? _cdsAccount;
  String? _brokerCode;
  String? _brokerName;

  // ── Multi-broker ──
  List<Map<String, String>> _activeBrokers = [];
  int _selectedBrokerIndex = 0;

  String? selectedCompany; // '<ticker>-<code>-<index>'
  String? selectedTimeInForce = 'Day Order';

  final quantityController = TextEditingController(text: '');
  final priceController = TextEditingController(text: '');
  final chargesController = TextEditingController(text: '0.00');
  final _companySearchController = TextEditingController();

  List<Map<String, dynamic>> _allStocks = [];

  final List<String> timeInForceOptions = ['Day Order', 'Good Till Cancelled'];

  static const String apiUrl = '$baseUrl/Home/OrderPosting';
  static const String marketDataUrl = '$baseUrl/Home/getMarketData';

  @override
  void initState() {
    super.initState();
    isBuy = widget.initialIsBuy;
    _loadUserData();
    _initializeWithPrefilledData();
    _fetchStocksIfNeeded();

    quantityController.addListener(updateCalculations);
    priceController.addListener(updateCalculations);
  }

  void _initializeWithPrefilledData() {
    if (widget.allStocks != null) {
      _allStocks = widget.allStocks!;
    }

    if (widget.prefilledStockData != null) {
      final stockData = widget.prefilledStockData!;
      final ticker = stockData['ticker'];
      final code = stockData['code'] ?? '';

      final index = _allStocks.indexWhere(
              (stock) => stock['ticker'] == ticker && stock['code'] == code);

      if (index != -1) {
        selectedCompany = '$ticker-$code-$index';
      } else {
        _allStocks.add(stockData);
        selectedCompany = '$ticker-$code-${_allStocks.length - 1}';
      }

      priceController.text =
          stockData['closingPriceValue']?.toString() ?? '0.00';

      updateCalculations();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) return;

      final int count = prefs.getInt('activeBrokersCount') ?? 0;
      final List<Map<String, String>> brokers = [];

      if (count > 0) {
        for (int i = 0; i < count; i++) {
          brokers.add({
            'brokerCode': prefs.getString('broker_${i}_BrokerCode') ?? '',
            'cdsAccount': prefs.getString('broker_${i}_CDSAccount') ?? '',
            'brokerName': prefs.getString('broker_${i}_BrokerName') ?? '',
            'status': prefs.getString('broker_${i}_Status') ?? '',
          });
        }
      } else {
        final code = prefs.getString('BrokerCode') ?? '';
        final cds = prefs.getString('CDSAccount') ?? '';
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
        _token = token;
        _activeBrokers = brokers;
        _selectedBrokerIndex = 0;
        _applyBroker(0);
      });

      final response = await http.post(
        Uri.parse(
            'https://zamagm.escrowagm.com/MainAPI/Authentication/GetProfile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'Token': token}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['responseCode'] == 200) {
          final fullName = responseData['fullName'] ?? 'N/A';
          final phoneNumber = responseData['phoneNumber'] ?? '';
          final cdsNumber = responseData['cdsNumber'] ?? '';

          await prefs.setString('fullName', fullName);
          await prefs.setString('phoneNumber', phoneNumber);
          await prefs.setString('cdsNumber', cdsNumber);

          if (mounted) {
            setState(() {
              _userName = fullName;
              _phoneNumber = phoneNumber;
              _cdsNumber = cdsNumber;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _userName = prefs.getString('fullName') ?? 'N/A';
              _phoneNumber = prefs.getString('phoneNumber') ?? '';
              _cdsNumber = prefs.getString('cdsNumber') ?? '';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _userName = prefs.getString('fullName') ?? 'N/A';
            _phoneNumber = prefs.getString('phoneNumber') ?? '';
            _cdsNumber = prefs.getString('cdsNumber') ?? '';
          });
        }
      }
    } catch (e) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (mounted) {
          setState(() {
            _userName = prefs.getString('fullName') ?? 'N/A';
            _phoneNumber = prefs.getString('phoneNumber') ?? '';
            _cdsNumber = prefs.getString('cdsNumber') ?? '';
          });
        }
      } catch (_) {}
    }
  }

  void _applyBroker(int index) {
    if (_activeBrokers.isEmpty) return;
    final b = _activeBrokers[index];
    _brokerCode = b['brokerCode'] ?? '';
    _brokerName = b['brokerName'] ?? '';
    _cdsAccount = b['cdsAccount'] ?? '';
  }

  void _onBrokerChanged(int index) {
    setState(() {
      _selectedBrokerIndex = index;
      _applyBroker(index);
    });
  }

  // ─── Fetch Stocks ─────────────────────────────────────────────────────────

  Future<void> _fetchStocksIfNeeded() async {
    if (widget.allStocks != null && widget.allStocks!.isNotEmpty) return;

    if (_token == null) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (_token == null) return;

    await _fetchStocksFromApi();
  }

  Future<void> _fetchStocksFromApi() async {
    setState(() => isFetchingStocks = true);

    try {
      final response = await http.post(
        Uri.parse(marketDataUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        List<Map<String, dynamic>> stocks = [];

        if (jsonData.isNotEmpty && jsonData[0]['MdataItem'] != null) {
          final List<dynamic> items = jsonData[0]['MdataItem'];
          for (var item in items) {
            stocks.add(_mapApiDataToStock(item));
          }
        }

        setState(() {
          _allStocks = stocks;

          if (widget.prefilledStockData != null && stocks.isNotEmpty) {
            final prefilledTicker = widget.prefilledStockData!['ticker'];
            final prefilledCode = widget.prefilledStockData!['code'] ?? '';

            bool exists = stocks.any((stock) =>
            stock['ticker'] == prefilledTicker &&
                stock['code'] == prefilledCode);

            if (!exists) _allStocks.add(widget.prefilledStockData!);

            final index = _allStocks.indexWhere((stock) =>
            stock['ticker'] == prefilledTicker &&
                stock['code'] == prefilledCode);

            if (index != -1) {
              selectedCompany = '$prefilledTicker-$prefilledCode-$index';
            }

            priceController.text =
                widget.prefilledStockData!['closingPriceValue']?.toString() ??
                    '0.00';
          } else if (selectedCompany == null && _allStocks.isNotEmpty) {
            final firstStock = _allStocks[0];
            final ticker = firstStock['ticker'] ?? '';
            final code = firstStock['code'] ?? '';
            selectedCompany = '$ticker-$code-0';
            priceController.text =
                _allStocks[0]['closingPriceValue']?.toString() ?? '0.00';
          }

          updateCalculations();
        });
      } else {
        if (widget.prefilledStockData != null) {
          setState(() {
            _allStocks = [widget.prefilledStockData!];
            final ticker = widget.prefilledStockData!['ticker'] ?? '';
            final code = widget.prefilledStockData!['code'] ?? '';
            selectedCompany = '$ticker-$code-0';
          });
        }
      }
    } catch (e) {
      if (widget.prefilledStockData != null) {
        setState(() {
          _allStocks = [widget.prefilledStockData!];
          final ticker = widget.prefilledStockData!['ticker'] ?? '';
          final code = widget.prefilledStockData!['code'] ?? '';
          selectedCompany = '$ticker-$code-0';
        });
      }
    } finally {
      setState(() => isFetchingStocks = false);
    }
  }

  Map<String, dynamic> _mapApiDataToStock(dynamic item) {
    final rawCode = item['Code']?.toString() ?? '';
    final rawName = item['Company']?.toString() ?? 'Unknown';
    final rawSymbol = item['Symbol']?.toString() ?? '';

    String name = rawName.isNotEmpty ? rawName : rawCode;
    String ticker =
    rawCode.isNotEmpty ? rawCode : (rawSymbol.isNotEmpty ? rawSymbol : rawName);
    String code = rawCode;

    String closingPrice = item['ClosingPrice']?.toString() ?? '0';
    String openingPrice = item['OpeningPrice']?.toString() ?? '0';
    String maxPrice = item['MaxPrice']?.toString() ?? '0';
    String minPrice = item['MinPrice']?.toString() ?? '0';

    String price = 'BWP $closingPrice';
    String bestBid = 'BWP $openingPrice';
    String bestAsk = 'BWP $maxPrice';

    String openInterest = item['Openinterest']?.toString() ?? '0';
    String supply = _formatVolume(openInterest);
    String status = item['status']?.toString() ?? '';

    IconData icon = _getIconForStock(ticker);
    Color color = _getColorForStock(ticker);

    return {
      'name': name, 'ticker': ticker, 'price': price,
      'bestBid': bestBid, 'bestAsk': bestAsk,
      'supply': supply, 'demand': '-',
      'icon': icon, 'color': color,
      'status': status, 'code': code,
      'closingPriceValue': double.tryParse(closingPrice) ?? 0.0,
      'openingPriceValue': double.tryParse(openingPrice) ?? 0.0,
      'maxPriceValue': double.tryParse(maxPrice) ?? 0.0,
      'minPriceValue': double.tryParse(minPrice) ?? 0.0,
      'volumeValue': double.tryParse(openInterest) ?? 0.0,
    };
  }

  String _formatVolume(String volume) {
    try {
      final num = double.parse(volume);
      if (num >= 1000000000) return '${(num / 1000000000).toStringAsFixed(2)}B';
      if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(2)}M';
      if (num >= 1000) return '${(num / 1000).toStringAsFixed(2)}K';
      return num.toStringAsFixed(0);
    } catch (_) {
      return '0';
    }
  }

  IconData _getIconForStock(String symbol) {
    final s = symbol.toUpperCase();
    if (s.contains('BANK') || s.contains('CRDB') || s.contains('NMB') ||
        s.contains('KCB') || s.contains('DCB') || s.contains('MKCB') ||
        s.contains('MUCOBA') || s.contains('MCB') || s.contains('MBP')) {
      return Icons.account_balance;
    } else if (s.contains('BREW') || s.contains('TBL') || s.contains('EABL')) {
      return Icons.local_drink;
    } else if (s.contains('AIR') || s.contains('KA') || s.contains('PAL')) {
      return Icons.flight;
    } else if (s.contains('CEMENT') || s.contains('TCCL') || s.contains('TPCC')) {
      return Icons.construction;
    } else if (s.contains('VODA') || s.contains('TELECOM')) {
      return Icons.phone_android;
    } else if (s.contains('MEDIA') || s.contains('NMG')) {
      return Icons.newspaper;
    } else if (s.contains('INSURANCE') || s.contains('JHL')) {
      return Icons.security;
    } else if (s.contains('OIL') || s.contains('GAS') ||
        s.contains('SWALA') || s.contains('TOL')) {
      return Icons.local_gas_station;
    }
    return Icons.business;
  }

  Color _getColorForStock(String symbol) {
    final colors = [
      const Color(0xFF3D2F1F), const Color(0xFF2A3F2F),
      const Color(0xFF2F3A4A), const Color(0xFF4A2F2F),
      const Color(0xFF2F4A3F), const Color(0xFF3F2F4A),
    ];
    return colors[symbol.hashCode.abs() % colors.length];
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    chargesController.dispose();
    _companySearchController.dispose();
    super.dispose();
  }

  // ─── Calculations ─────────────────────────────────────────────────────────

  double get grossTotal =>
      (double.tryParse(quantityController.text) ?? 0) *
          (double.tryParse(priceController.text) ?? 0);
  double get custodialFee => grossTotal * 0.01;
  double get charges => double.tryParse(chargesController.text) ?? 0;
  double get netTotal => grossTotal + custodialFee + charges;

  void updateCalculations() => setState(() {});

  Map<String, dynamic>? get _selectedStock {
    if (selectedCompany == null) return null;
    final parts = selectedCompany!.split('-');
    final index = int.tryParse(parts.last);
    if (index != null && index < _allStocks.length) return _allStocks[index];
    return null;
  }

  void _onCompanySelected(int index) {
    setState(() {
      final stock = _allStocks[index];
      final ticker = stock['ticker'] ?? '';
      final code = stock['code'] ?? '';
      selectedCompany = '$ticker-$code-$index';
      priceController.text = stock['closingPriceValue']?.toString() ?? '0.00';
      updateCalculations();
    });
  }

  void _stepQuantity(int delta) {
    final current = int.tryParse(quantityController.text) ?? 0;
    final next = (current + delta).clamp(0, 1000000000);
    setState(() => quantityController.text = next.toString());
  }

  // ─── Place Order ──────────────────────────────────────────────────────────

  Future<void> placeOrder() async {
    if (_token == null) {
      _showError('No authentication token available');
      return;
    }
    if (selectedCompany == null || selectedCompany!.isEmpty) {
      _showError('Please select a company');
      return;
    }
    if (_brokerCode == null || _brokerCode!.isEmpty) {
      _showError('Broker code not available. Please log in again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final parts = selectedCompany!.split('-');
      final index = int.tryParse(parts.last);

      String companyCode = '';

      if (index != null && index < _allStocks.length) {
        final stock = _allStocks[index];
        final code = stock['code']?.toString() ?? '';
        final ticker = stock['ticker']?.toString() ?? '';
        final name = stock['name']?.toString() ?? '';
        companyCode = code.isNotEmpty ? code : (ticker.isNotEmpty ? ticker : name);
      }

      if (companyCode.isEmpty && parts.length >= 2) companyCode = parts[1];

      if (companyCode.isEmpty) {
        _showError('Could not determine company code. Please re-select the company.');
        setState(() => isLoading = false);
        return;
      }

      final now = DateTime.now().toUtc();
      final settlementDate = now.add(const Duration(days: 2));
      final maturityDate = now.add(const Duration(days: 365));

      final orderData = {
        "OrderType": isBuy ? "BUY" : "SELL",
        "ReferenceNumber": "ORD${now.millisecondsSinceEpoch}",
        "Company": companyCode,
        "Quantity": double.tryParse(quantityController.text) ?? 0,
        "BasePrice": double.tryParse(priceController.text) ?? 0,
        "TimeInForce": selectedTimeInForce,
        "BrokerCode": _brokerCode,
        "CdsAcNo": _cdsAccount ?? '',
        "Shareholder": _cdsAccount ?? '',
        "LiNumber": _cdsAccount ?? '',
        "ClientName": _userName ?? 'N/A',
        "BrokerRef": "BRREF${now.millisecondsSinceEpoch}",
        "SettlementDate": settlementDate.toIso8601String(),
        "SettlementAmount": netTotal,
        "Charges": charges,
        "Brokerage": 0.0,
        "MaturityDate": maturityDate.toIso8601String().split('T')[0],
        "Currency": "BWP",
        "Source": "MOBILE",
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final responseCode = responseData[0]['responseCode'];
        final responseMessage = responseData[0]['responseMessage'] ?? 'Unknown error';

        if (responseCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Order #${responseData[0]['ordernumber']} placed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        } else {
          throw Exception('Order rejected: $responseMessage (code $responseCode)');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to place order: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ─── Company picker bottom sheet ────────────────────────────────────────

  void _openCompanyPicker({
    required bool isDark,
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    _companySearchController.clear();
    List<Map<String, dynamic>> filtered = List.of(_allStocks);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.92,
              builder: (ctx, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: subtextColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text('Select Company',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: _companySearchController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Search by name or code',
                            hintStyle: TextStyle(color: subtextColor),
                            prefixIcon: Icon(Icons.search, color: accentColor),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (query) {
                            setModalState(() {
                              filtered = _allStocks.where((s) {
                                final name = (s['name'] ?? '').toString().toLowerCase();
                                final code = (s['code'] ?? '').toString().toLowerCase();
                                final q = query.toLowerCase();
                                return name.contains(q) || code.contains(q);
                              }).toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                            child: Text('No matches',
                                style: TextStyle(color: subtextColor)))
                            : ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final stock = filtered[i];
                            final realIndex = _allStocks.indexOf(stock);
                            final price = stock['closingPriceValue'] ?? 0.0;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                (stock['color'] as Color?)?.withOpacity(0.3) ??
                                    accentColor.withOpacity(0.2),
                                child: Icon(
                                    stock['icon'] as IconData? ?? Icons.business,
                                    color: accentColor, size: 18),
                              ),
                              title: Text(stock['name'] ?? 'Unknown',
                                  style: TextStyle(color: textColor, fontSize: 14)),
                              subtitle: Text(stock['code'] ?? '',
                                  style: TextStyle(color: subtextColor, fontSize: 12)),
                              trailing: Text(
                                  'BWP ${price is double ? price.toStringAsFixed(2) : price}',
                                  style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w600)),
                              onTap: () {
                                _onCompanySelected(realIndex);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgGradient = isDark
        ? const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF2C1810), Color(0xFF1A1A1A), Color(0xFF0D0D0D)])
        : const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFFFFF8E7), Color(0xFFF5F5F5), Color(0xFFFFFFFF)]);

    final buySellColor = isBuy ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final accentColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey : Colors.grey.shade600;
    final cardColor = isDark ? const Color(0xFF23201C) : Colors.white;
    final fieldBgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;
    final fieldBorderColor = isDark ? Colors.white12 : Colors.black12;

    final stock = _selectedStock;
    final companyLabel = stock != null
        ? '${stock['name']}${(stock['code'] ?? '').toString().isNotEmpty ? ' (${stock['code']})' : ''}'
        : null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text('New Order',
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
                      // ── BUY / SELL tile switch ──
                      Row(
                        children: [
                          Expanded(
                            child: _orderTypeTile(
                              label: 'BUY',
                              icon: Icons.trending_up_rounded,
                              color: const Color(0xFF2E7D32),
                              selected: isBuy,
                              cardColor: cardColor,
                              textColor: textColor,
                              onTap: () => setState(() => isBuy = true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _orderTypeTile(
                              label: 'SELL',
                              icon: Icons.trending_down_rounded,
                              color: const Color(0xFFC62828),
                              selected: !isBuy,
                              cardColor: cardColor,
                              textColor: textColor,
                              onTap: () => setState(() => isBuy = false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Company picker card ──
                      Text('Company',
                          style: TextStyle(
                              color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: isFetchingStocks
                            ? null
                            : () => _openCompanyPicker(
                          isDark: isDark,
                          accentColor: accentColor,
                          cardColor: cardColor,
                          textColor: textColor,
                          subtextColor: subtextColor,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: fieldBorderColor),
                          ),
                          child: isFetchingStocks
                              ? Row(
                            children: [
                              SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: accentColor)),
                              const SizedBox(width: 12),
                              Text('Loading companies…',
                                  style: TextStyle(color: subtextColor)),
                            ],
                          )
                              : Row(
                            children: [
                              Icon(stock != null
                                  ? (stock['icon'] as IconData? ?? Icons.business)
                                  : Icons.search,
                                  color: accentColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  companyLabel ?? 'Tap to choose a company',
                                  style: TextStyle(
                                      color: companyLabel != null ? textColor : subtextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.chevron_right, color: subtextColor),
                            ],
                          ),
                        ),
                      ),
                      if (_allStocks.isEmpty && !isFetchingStocks)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'No companies available. Please check your connection or contact support.',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // ── Quantity stepper ──
                      Text('Quantity',
                          style: TextStyle(
                              color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: fieldBorderColor),
                        ),
                        child: Row(
                          children: [
                            _stepperButton(Icons.remove, accentColor, () => _stepQuantity(-100)),
                            Expanded(
                              child: TextField(
                                controller: quantityController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                    color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                    border: InputBorder.none, hintText: '0'),
                              ),
                            ),
                            _stepperButton(Icons.add, accentColor, () => _stepQuantity(100)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Price ──
                      Text('Price (BWP)',
                          style: TextStyle(
                              color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: fieldBorderColor),
                        ),
                        child: TextField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Time in force dropdown ──
                      Text('Time In Force',
                          style: TextStyle(
                              color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: fieldBorderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTimeInForce,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            dropdownColor: cardColor,
                            icon: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(Icons.arrow_drop_down, color: accentColor),
                            ),
                            style: TextStyle(color: textColor, fontSize: 14),
                            items: timeInForceOptions.map((option) {
                              return DropdownMenuItem<String>(
                                value: option,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Text(option,
                                      style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500)),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => selectedTimeInForce = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Broker dropdown (only when multiple) ──
                      if (_activeBrokers.length > 1) ...[
                        Text('Broker',
                            style: TextStyle(
                                color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: fieldBorderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedBrokerIndex,
                              isExpanded: true,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              dropdownColor: cardColor,
                              icon: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(Icons.arrow_drop_down, color: accentColor),
                              ),
                              // What's shown when the dropdown is closed
                              selectedItemBuilder: (context) {
                                return List.generate(_activeBrokers.length, (i) {
                                  final b = _activeBrokers[i];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Row(
                                      children: [
                                        Icon(Icons.business_rounded, color: accentColor, size: 16),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${b['brokerName']} (${b['brokerCode']})',
                                            style: TextStyle(
                                                color: textColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                });
                              },
                              // Dropdown menu items
                              items: List.generate(_activeBrokers.length, (i) {
                                final b = _activeBrokers[i];
                                final isActive = i == _selectedBrokerIndex;
                                return DropdownMenuItem<int>(
                                  value: i,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: accentColor.withOpacity(isActive ? 0.2 : 0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.business_rounded,
                                              color: accentColor, size: 14),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                b['brokerName'] ?? '',
                                                style: TextStyle(
                                                    color: isActive ? accentColor : textColor,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${b['brokerCode']}  ·  ${b['cdsAccount']}',
                                                style: TextStyle(color: subtextColor, fontSize: 11),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: accentColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text('SELECTED',
                                                style: TextStyle(
                                                    color: accentColor,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.8)),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) _onBrokerChanged(value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Account details ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: fieldBorderColor),
                        ),
                        child: Column(
                          children: [
                            _detailRow('CDS Account', _cdsAccount ?? 'N/A', textColor, subtextColor),
                            const SizedBox(height: 10),
                            _detailRow('Broker Code', _brokerCode ?? 'N/A', textColor, subtextColor),
                            const SizedBox(height: 10),
                            _detailRow('Phone Number', _phoneNumber ?? 'N/A', textColor, subtextColor),
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
                            colors: [buySellColor.withOpacity(0.15), cardColor],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: buySellColor.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            _summaryRow('Gross Total', 'BWP ${grossTotal.toStringAsFixed(2)}', subtextColor),
                            const SizedBox(height: 8),
                            _summaryRow('Custodial Fee (1%)', 'BWP ${custodialFee.toStringAsFixed(2)}', subtextColor),
                            const SizedBox(height: 8),
                            _summaryRow('Charges', 'BWP ${charges.toStringAsFixed(2)}', subtextColor),
                            const SizedBox(height: 12),
                            Divider(color: subtextColor.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('NET TOTAL',
                                    style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                                Text('BWP ${netTotal.toStringAsFixed(2)}',
                                    style: TextStyle(color: buySellColor, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
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
                      backgroundColor: buySellColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: (isLoading || isFetchingStocks || _allStocks.isEmpty)
                        ? null
                        : placeOrder,
                    child: isLoading
                        ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                      isBuy ? 'PLACE BUY ORDER' : 'PLACE SELL ORDER',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  // ─── Small helper widgets ─────────────────────────────────────────────────

  Widget _orderTypeTile({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required Color cardColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : Colors.transparent, width: 2),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : textColor.withOpacity(0.4), size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? color : textColor.withOpacity(0.4),
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _stepperButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Icon(icon, color: color),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color textColor, Color subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subtextColor, fontSize: 13)),
        Text(value, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}