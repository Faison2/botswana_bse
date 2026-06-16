import 'package:bse/contants/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import '../dashboard/dashboard.dart';

class TradingPage extends StatefulWidget {
  final Map<String, dynamic>? prefilledStockData;
  final List<Map<String, dynamic>>? allStocks;

  const TradingPage({
    Key? key,
    this.prefilledStockData,
    this.allStocks,
  }) : super(key: key);

  @override
  State<TradingPage> createState() => _TradingPageState();
}

class _TradingPageState extends State<TradingPage> {
  bool isBuy = true;
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
  List<Map<String, String>> _activeBrokers    = [];
  int                       _selectedBrokerIndex = 0;

  String? selectedCompany;
  String? selectedTimeInForce = 'Day Order';

  final quantityController  = TextEditingController(text: '');
  final priceController     = TextEditingController(text: '');
  final chargesController   = TextEditingController(text: '0.00');

  List<Map<String, dynamic>> _allStocks = [];

  final List<String> timeInForceOptions = ['Day Order', 'Good Till Cancelled'];

  static const String apiUrl        = '$baseUrl/Home/OrderPosting';
  static const String marketDataUrl = '$baseUrl/Home/getMarketData';

  @override
  void initState() {
    super.initState();
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
      final code   = stockData['code'] ?? '';

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
        _token               = token;
        _activeBrokers       = brokers;
        _selectedBrokerIndex = 0;
        _applyBroker(0);
      });

      // Fetch full profile
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
          final fullName    = responseData['fullName']    ?? 'N/A';
          final phoneNumber = responseData['phoneNumber'] ?? '';
          final cdsNumber   = responseData['cdsNumber']   ?? '';

          await prefs.setString('fullName',    fullName);
          await prefs.setString('phoneNumber', phoneNumber);
          await prefs.setString('cdsNumber',   cdsNumber);

          if (mounted) {
            setState(() {
              _userName    = fullName;
              _phoneNumber = phoneNumber;
              _cdsNumber   = cdsNumber;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _userName    = prefs.getString('fullName')    ?? 'N/A';
              _phoneNumber = prefs.getString('phoneNumber') ?? '';
              _cdsNumber   = prefs.getString('cdsNumber')   ?? '';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _userName    = prefs.getString('fullName')    ?? 'N/A';
            _phoneNumber = prefs.getString('phoneNumber') ?? '';
            _cdsNumber   = prefs.getString('cdsNumber')   ?? '';
          });
        }
      }
    } catch (e) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (mounted) {
          setState(() {
            _userName    = prefs.getString('fullName')    ?? 'N/A';
            _phoneNumber = prefs.getString('phoneNumber') ?? '';
            _cdsNumber   = prefs.getString('cdsNumber')   ?? '';
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

  void _onBrokerChanged(int? index) {
    if (index == null) return;
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
            final prefilledCode   = widget.prefilledStockData!['code'] ?? '';

            bool exists = stocks.any((stock) =>
            stock['ticker'] == prefilledTicker &&
                stock['code']   == prefilledCode);

            if (!exists) _allStocks.add(widget.prefilledStockData!);

            final index = _allStocks.indexWhere((stock) =>
            stock['ticker'] == prefilledTicker &&
                stock['code']   == prefilledCode);

            if (index != -1) {
              selectedCompany = '$prefilledTicker-$prefilledCode-$index';
            }

            priceController.text =
                widget.prefilledStockData!['closingPriceValue']?.toString() ??
                    '0.00';
          } else if (selectedCompany == null && _allStocks.isNotEmpty) {
            final firstStock = _allStocks[0];
            final ticker     = firstStock['ticker'] ?? '';
            final code       = firstStock['code']   ?? '';
            selectedCompany  = '$ticker-$code-0';
            priceController.text =
                _allStocks[0]['closingPriceValue']?.toString() ?? '0.00';
          }

          updateCalculations();
        });
      } else {
        if (widget.prefilledStockData != null) {
          setState(() {
            _allStocks     = [widget.prefilledStockData!];
            final ticker   = widget.prefilledStockData!['ticker'] ?? '';
            final code     = widget.prefilledStockData!['code']   ?? '';
            selectedCompany = '$ticker-$code-0';
          });
        }
      }
    } catch (e) {
      if (widget.prefilledStockData != null) {
        setState(() {
          _allStocks      = [widget.prefilledStockData!];
          final ticker    = widget.prefilledStockData!['ticker'] ?? '';
          final code      = widget.prefilledStockData!['code']   ?? '';
          selectedCompany = '$ticker-$code-0';
        });
      }
    } finally {
      setState(() => isFetchingStocks = false);
    }
  }

  Map<String, dynamic> _mapApiDataToStock(dynamic item) {
    final rawCode   = item['Code']?.toString()    ?? '';
    final rawName   = item['Company']?.toString() ?? 'Unknown';
    final rawSymbol = item['Symbol']?.toString()  ?? '';

    String name   = rawName.isNotEmpty   ? rawName   : rawCode;
    String ticker = rawCode.isNotEmpty   ? rawCode   : (rawSymbol.isNotEmpty ? rawSymbol : rawName);
    String code   = rawCode;

    String closingPrice = item['ClosingPrice']?.toString() ?? '0';
    String openingPrice = item['OpeningPrice']?.toString() ?? '0';
    String maxPrice     = item['MaxPrice']?.toString()     ?? '0';
    String minPrice     = item['MinPrice']?.toString()     ?? '0';

    String price        = 'BWP $closingPrice';
    String bestBid      = 'BWP $openingPrice';
    String bestAsk      = 'BWP $maxPrice';

    String openInterest = item['Openinterest']?.toString() ?? '0';
    String supply       = _formatVolume(openInterest);
    String status       = item['status']?.toString() ?? '';

    IconData icon  = _getIconForStock(ticker);
    Color    color = _getColorForStock(ticker);

    return {
      'name': name, 'ticker': ticker, 'price': price,
      'bestBid': bestBid, 'bestAsk': bestAsk,
      'supply': supply, 'demand': '-',
      'icon': icon, 'color': color,
      'status': status, 'code': code,
      'closingPriceValue': double.tryParse(closingPrice) ?? 0.0,
      'openingPriceValue': double.tryParse(openingPrice) ?? 0.0,
      'maxPriceValue':     double.tryParse(maxPrice)     ?? 0.0,
      'minPriceValue':     double.tryParse(minPrice)     ?? 0.0,
      'volumeValue':       double.tryParse(openInterest) ?? 0.0,
    };
  }

  String _formatVolume(String volume) {
    try {
      final num = double.parse(volume);
      if (num >= 1000000000) return '${(num / 1000000000).toStringAsFixed(2)}B';
      if (num >= 1000000)    return '${(num / 1000000).toStringAsFixed(2)}M';
      if (num >= 1000)       return '${(num / 1000).toStringAsFixed(2)}K';
      return num.toStringAsFixed(0);
    } catch (_) { return '0'; }
  }

  IconData _getIconForStock(String symbol) {
    final s = symbol.toUpperCase();
    if (s.contains('BANK') || s.contains('CRDB') || s.contains('NMB') ||
        s.contains('KCB')  || s.contains('DCB')  || s.contains('MKCB') ||
        s.contains('MUCOBA')|| s.contains('MCB')  || s.contains('MBP')) {
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
    super.dispose();
  }

  // ─── Calculations ─────────────────────────────────────────────────────────

  double get grossTotal  => (double.tryParse(quantityController.text) ?? 0) *
      (double.tryParse(priceController.text)    ?? 0);
  double get custodialFee => grossTotal * 0.01;
  double get charges      => double.tryParse(chargesController.text)  ?? 0;
  double get netTotal     => grossTotal + custodialFee + charges;

  void updateCalculations() => setState(() {});

  void _onCompanyChanged(String? uniqueId) {
    if (uniqueId == null) return;
    setState(() {
      selectedCompany = uniqueId;
      final parts = uniqueId.split('-');
      final index = int.tryParse(parts.last);
      if (index != null && index < _allStocks.length) {
        priceController.text =
            _allStocks[index]['closingPriceValue']?.toString() ?? '0.00';
        updateCalculations();
      }
    });
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
        final stock  = _allStocks[index];
        final code   = stock['code']?.toString()   ?? '';
        final ticker = stock['ticker']?.toString() ?? '';
        final name   = stock['name']?.toString()   ?? '';
        companyCode  = code.isNotEmpty ? code : (ticker.isNotEmpty ? ticker : name);
      }

      if (companyCode.isEmpty && parts.length >= 2) companyCode = parts[1];

      if (companyCode.isEmpty) {
        _showError('Could not determine company code. Please re-select the company.');
        setState(() => isLoading = false);
        return;
      }

      final now            = DateTime.now().toUtc();
      final settlementDate = now.add(const Duration(days: 2));
      final maturityDate   = now.add(const Duration(days: 365));

      final orderData = {
        "OrderType":        isBuy ? "BUY" : "SELL",
        "ReferenceNumber":  "ORD${now.millisecondsSinceEpoch}",
        "Company":          companyCode,
        "Quantity":         double.tryParse(quantityController.text) ?? 0,
        "BasePrice":        double.tryParse(priceController.text)    ?? 0,
        "TimeInForce":      selectedTimeInForce,
        "BrokerCode":       _brokerCode,
        "CdsAcNo":          _cdsAccount ?? '',
        "Shareholder":      _cdsAccount ?? '',
        "LiNumber":         _cdsAccount ?? '',
        "ClientName":       _userName   ?? 'N/A',
        "BrokerRef":        "BRREF${now.millisecondsSinceEpoch}",
        "SettlementDate":   settlementDate.toIso8601String(),
        "SettlementAmount": netTotal,
        "Charges":          charges,
        "Brokerage":        0.0,
        "MaturityDate":     maturityDate.toIso8601String().split('T')[0],
        "Currency":         "BWP",
        "Source":           "MOBILE",
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
        final responseCode    = responseData[0]['responseCode'];
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
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark        = themeProvider.isDarkMode;

    final bgGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF2C1810), Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
    )
        : const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFFFF8E7), Color(0xFFF5F5F5), Color(0xFFFFFFFF)],
    );

    final accentColor      = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
    final toggleBgColor    = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);
    final fieldBorderColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
    final textColor        = isDark ? Colors.white            : Colors.black87;
    final subtextColor     = isDark ? Colors.grey             : Colors.grey.shade600;
    final cardColor        = isDark ? const Color(0xFF3A3530) : Colors.white;
    final dropdownBgColor  = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final fieldBgColor     = isDark ? Colors.transparent      : Colors.grey.shade50;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // ── BUY / SELL Toggle ──────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: toggleBgColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: isDark
                                ? []
                                : [BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10, offset: const Offset(0, 2))],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isBuy = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: isBuy
                                        ? BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: [Colors.green, Colors.black]),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2))],
                                    )
                                        : null,
                                    child: Center(
                                      child: Text('BUY',
                                          style: TextStyle(
                                              color: isBuy ? Colors.white : subtextColor,
                                              fontSize: 18,
                                              fontWeight: isBuy
                                                  ? FontWeight.bold
                                                  : FontWeight.w400)),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isBuy = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: !isBuy
                                        ? BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: [Colors.black, Colors.red]),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2))],
                                    )
                                        : null,
                                    child: Center(
                                      child: Text('SELL',
                                          style: TextStyle(
                                              color: !isBuy ? Colors.white : subtextColor,
                                              fontSize: 18,
                                              fontWeight: !isBuy
                                                  ? FontWeight.bold
                                                  : FontWeight.w400)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Company Dropdown ───────────────────────────────
                        if (isFetchingStocks)
                          _buildLoadingField('Company',
                              textColor: textColor,
                              fieldBorderColor: fieldBorderColor,
                              fieldBgColor: fieldBgColor,
                              accentColor: accentColor)
                        else
                          _buildCompanyDropdown(
                            textColor: textColor,
                            fieldBorderColor: fieldBorderColor,
                            dropdownBgColor: dropdownBgColor,
                            accentColor: accentColor,
                            fieldBgColor: fieldBgColor,
                          ),
                        const SizedBox(height: 16),

                        // ── Time In Force ──────────────────────────────────
                        _buildDropdownField(
                          'Time In Force',
                          selectedTimeInForce,
                          timeInForceOptions,
                              (value) => setState(() => selectedTimeInForce = value),
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          dropdownBgColor: dropdownBgColor,
                          accentColor: accentColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 16),

                        // ── Broker Selector (only when multiple brokers) ───
                        if (_activeBrokers.length > 1) ...[
                          _buildBrokerDropdown(
                            textColor: textColor,
                            subtextColor: subtextColor,
                            fieldBorderColor: fieldBorderColor,
                            dropdownBgColor: dropdownBgColor,
                            accentColor: accentColor,
                            fieldBgColor: fieldBgColor,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── CDS Account (read-only, updates with broker) ───
                        _buildReadOnlyField(
                          'CDS Account',
                          _cdsAccount ?? 'N/A',
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 16),

                        // ── Broker Code (read-only, updates with broker) ───
                        _buildReadOnlyField(
                          'Broker Code',
                          _brokerCode ?? 'N/A',
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 16),

                        // ── Quantity ───────────────────────────────────────
                        _buildTextField(
                          'Quantity',
                          quantityController,
                          keyboardType: TextInputType.number,
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 16),

                        // ── Price ──────────────────────────────────────────
                        _buildTextField(
                          'Price',
                          priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 16),

                        // ── Phone Number ───────────────────────────────────
                        _buildReadOnlyField(
                          'Phone Number',
                          _phoneNumber ?? 'N/A',
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 16),

                        // ── Summary Card ───────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isDark
                                ? []
                                : [BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              _summaryRow('GROSS TOTAL:',
                                  'BWP ${grossTotal.toStringAsFixed(2)}',
                                  subtextColor),
                              const SizedBox(height: 8),
                              _summaryRow('CUSTODIAL FEE (1%):',
                                  'BWP ${custodialFee.toStringAsFixed(2)}',
                                  subtextColor),
                              const SizedBox(height: 8),
                              _summaryRow('CHARGES:',
                                  'BWP ${charges.toStringAsFixed(2)}',
                                  subtextColor),
                              const SizedBox(height: 12),
                              Divider(color: subtextColor),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('NET TOTAL:',
                                      style: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Text('BWP ${netTotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: accentColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Action Buttons ─────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(0xFF4A4540)
                                      : Colors.grey.shade300,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed:
                                isLoading ? null : () => Navigator.pop(context),
                                child: Text('CLOSE',
                                    style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: (isLoading ||
                                    isFetchingStocks ||
                                    _allStocks.isEmpty)
                                    ? null
                                    : placeOrder,
                                child: isLoading
                                    ? const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                    : const Text('PLACE ORDER',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
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

  // ─── Broker Dropdown ──────────────────────────────────────────────────────

  Widget _buildBrokerDropdown({
    required Color textColor,
    required Color subtextColor,
    required Color fieldBorderColor,
    required Color dropdownBgColor,
    required Color accentColor,
    required Color fieldBgColor,
    required bool  isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Broker',
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorderColor, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedBrokerIndex,
              isExpanded: true,
              dropdownColor: dropdownBgColor,
              icon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: accentColor),
              ),
              // What shows in the closed field
              selectedItemBuilder: (context) {
                return List.generate(_activeBrokers.length, (i) {
                  final b = _activeBrokers[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.business_rounded,
                            color: accentColor, size: 16),
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
                final b        = _activeBrokers[i];
                final isActive = i == _selectedBrokerIndex;
                return DropdownMenuItem<int>(
                  value: i,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentColor
                                .withOpacity(isActive ? 0.2 : 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.business_rounded,
                              color: accentColor,
                              size: 14),
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
                                style: TextStyle(
                                    color: subtextColor, fontSize: 11),
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
              onChanged: _onBrokerChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helper Widgets ───────────────────────────────────────────────────────

  Row _summaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 14)),
        Text(value, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }

  Widget _buildLoadingField(String label, {
    required Color textColor,
    required Color fieldBorderColor,
    required Color fieldBgColor,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorderColor, width: 1),
          ),
          child: Center(
            child: CircularProgressIndicator(
                color: accentColor, strokeWidth: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyDropdown({
    required Color textColor,
    required Color fieldBorderColor,
    required Color dropdownBgColor,
    required Color accentColor,
    required Color fieldBgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Company',
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorderColor, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCompany,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select Company',
                    style: TextStyle(
                        color: textColor.withOpacity(0.5))),
              ),
              isExpanded: true,
              dropdownColor: dropdownBgColor,
              icon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: accentColor),
              ),
              style: TextStyle(color: textColor, fontSize: 14),
              items: _allStocks.asMap().entries.map((entry) {
                final index       = entry.key;
                final stock       = entry.value;
                final companyName = stock['name']   ?? 'Unknown Company';
                final code        = stock['code']   ?? '';
                final ticker      = stock['ticker'] ?? code;
                final uniqueId    = '$ticker-$code-$index';
                final priceValue  = stock['closingPriceValue'] ?? 0.0;
                final priceString = priceValue is double
                    ? priceValue.toStringAsFixed(2)
                    : priceValue.toString();

                return DropdownMenuItem<String>(
                  value: uniqueId,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            code.isNotEmpty
                                ? '$companyName ($code)'
                                : companyName,
                            style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('BWP $priceString',
                            style: TextStyle(
                                color: accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: _allStocks.isEmpty ? null : _onCompanyChanged,
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
      ],
    );
  }

  Widget _buildDropdownField(
      String label,
      String? value,
      List<String> options,
      ValueChanged<String?> onChanged, {
        required Color textColor,
        required Color fieldBorderColor,
        required Color dropdownBgColor,
        required Color accentColor,
        required Color fieldBgColor,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorderColor, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: dropdownBgColor,
              icon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: accentColor),
              ),
              style: TextStyle(color: textColor, fontSize: 14),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(option,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        required Color textColor,
        required Color fieldBorderColor,
        required Color fieldBgColor,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: textColor),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldBgColor,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: fieldBorderColor, width: 1)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: fieldBorderColor, width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: fieldBorderColor, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
      String label,
      String value, {
        required Color textColor,
        required Color fieldBorderColor,
        required Color fieldBgColor,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorderColor, width: 1),
          ),
          child: Text(value, style: TextStyle(color: textColor, fontSize: 14)),
        ),
      ],
    );
  }
}