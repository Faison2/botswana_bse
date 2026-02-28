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
  bool isFetchingBrokers = false;
  String? _token;
  String? _userName;
  String? _cdsNumber;
  String? _phoneNumber;

  String? selectedCompany;
  String? selectedTimeInForce = 'Day Order';

  String? selectedBroker;
  String? selectedBrokerName;

  final quantityController = TextEditingController(text: '');
  final priceController = TextEditingController(text: '');
  final chargesController = TextEditingController(text: '0.00');

  List<Map<String, dynamic>> _allStocks = [];
  List<Map<String, dynamic>> _brokers = [];

  final List<String> timeInForceOptions = ['Day Order', 'Good Till Cancelled'];

  static const String apiUrl = '$baseUrl/Home/OrderPosting';
  static const String marketDataUrl = '$baseUrl/Home/getMarketData';
  static const String brokersUrl =
      'https://zamagm.escrowagm.com/MainAPI/Home/getAllBrokers';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeWithPrefilledData();
    _fetchStocksIfNeeded();
    _fetchBrokers();

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

      if (token == null || token.isEmpty) {
        print('No token available');
        return;
      }

      setState(() => _token = token);

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

          setState(() {
            _userName = fullName;
            _phoneNumber = phoneNumber;
            _cdsNumber = cdsNumber;
          });
        } else {
          setState(() {
            _userName = prefs.getString('fullName') ?? 'N/A';
            _phoneNumber = prefs.getString('phoneNumber') ?? '';
            _cdsNumber = prefs.getString('cdsNumber') ?? '';
          });
        }
      } else {
        setState(() {
          _userName = prefs.getString('fullName') ?? 'N/A';
          _phoneNumber = prefs.getString('phoneNumber') ?? '';
          _cdsNumber = prefs.getString('cdsNumber') ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _userName = prefs.getString('fullName') ?? 'N/A';
          _phoneNumber = prefs.getString('phoneNumber') ?? '';
          _cdsNumber = prefs.getString('cdsNumber') ?? '';
        });
      } catch (e) {
        print('Error loading cached user data: $e');
      }
    }
  }

  // ─── Fetch Brokers ────────────────────────────────────────────────────────

  Future<void> _fetchBrokers() async {
    setState(() => isFetchingBrokers = true);

    try {
      final response = await http.get(
        Uri.parse(brokersUrl),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _brokers = data
              .map((e) => {
            'broker_code': e['broker_code']?.toString() ?? '',
            'fnam': e['fnam']?.toString() ?? '',
          })
              .toList();

          if (_brokers.isNotEmpty && selectedBroker == null) {
            selectedBroker = _brokers[0]['broker_code'];
            selectedBrokerName = _brokers[0]['fnam'];
          }
        });
      } else {
        print('Failed to fetch brokers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching brokers: $e');
    } finally {
      setState(() => isFetchingBrokers = false);
    }
  }

  // ─── Fetch Stocks ─────────────────────────────────────────────────────────

  Future<void> _fetchStocksIfNeeded() async {
    if (widget.allStocks != null && widget.allStocks!.isNotEmpty) return;

    if (_token == null) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (_token == null) {
      print('No token available for fetching stocks');
      return;
    }

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

            if (!exists) {
              _allStocks.add(widget.prefilledStockData!);
            }

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
        print('Failed to fetch stocks: ${response.statusCode}');
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
      print('Error fetching stocks: $e');
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
    // ── FIX 1: Guard empty string for ticker/symbol ──────────────────────────
    final rawSymbol = item['Symbol']?.toString() ?? '';
    final rawName = item['Company']?.toString() ?? 'Unknown';

    // Use Symbol if non-empty, otherwise derive from Company name
    String ticker = rawSymbol.isNotEmpty ? rawSymbol : rawName;
    String name = rawName.isNotEmpty ? rawName : rawSymbol;
    String code = item['Code']?.toString() ?? '';

    String closingPrice = item['ClosingPrice']?.toString() ?? '0';
    String openingPrice = item['OpeningPrice']?.toString() ?? '0';
    String maxPrice = item['MaxPrice']?.toString() ?? '0';
    String minPrice = item['MinPrice']?.toString() ?? '0';

    String price = 'BWP $closingPrice';
    String bestBid = 'BWP $openingPrice';
    String bestAsk = 'BWP $maxPrice';

    String openInterest = item['Openinterest']?.toString() ?? '0';
    String supply = _formatVolume(openInterest);
    String demand = '-';
    String status = item['status']?.toString() ?? '';

    IconData icon = _getIconForStock(ticker);
    Color color = _getColorForStock(ticker);

    return {
      'name': name,
      'ticker': ticker,
      'price': price,
      'bestBid': bestBid,
      'bestAsk': bestAsk,
      'supply': supply,
      'demand': demand,
      'icon': icon,
      'color': color,
      'status': status,
      'code': code,
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
    } catch (e) {
      return '0';
    }
  }

  IconData _getIconForStock(String symbol) {
    final s = symbol.toUpperCase();
    if (s.contains('BANK') ||
        s.contains('CRDB') ||
        s.contains('NMB') ||
        s.contains('KCB') ||
        s.contains('DCB') ||
        s.contains('MKCB') ||
        s.contains('MUCOBA') ||
        s.contains('MCB') ||
        s.contains('MBP')) {
      return Icons.account_balance;
    } else if (s.contains('BREW') || s.contains('TBL') || s.contains('EABL')) {
      return Icons.local_drink;
    } else if (s.contains('AIR') || s.contains('KA') || s.contains('PAL')) {
      return Icons.flight;
    } else if (s.contains('CEMENT') ||
        s.contains('TCCL') ||
        s.contains('TPCC')) {
      return Icons.construction;
    } else if (s.contains('VODA') || s.contains('TELECOM')) {
      return Icons.phone_android;
    } else if (s.contains('MEDIA') || s.contains('NMG')) {
      return Icons.newspaper;
    } else if (s.contains('INSURANCE') || s.contains('JHL')) {
      return Icons.security;
    } else if (s.contains('OIL') ||
        s.contains('GAS') ||
        s.contains('SWALA') ||
        s.contains('TOL')) {
      return Icons.local_gas_station;
    }
    return Icons.business;
  }

  Color _getColorForStock(String symbol) {
    final colors = [
      const Color(0xFF3D2F1F),
      const Color(0xFF2A3F2F),
      const Color(0xFF2F3A4A),
      const Color(0xFF4A2F2F),
      const Color(0xFF2F4A3F),
      const Color(0xFF3F2F4A),
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

  double get grossTotal {
    final quantity = double.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    return quantity * price;
  }

  double get custodialFee => grossTotal * 0.01;

  double get charges => double.tryParse(chargesController.text) ?? 0;

  double get netTotal => grossTotal + custodialFee + charges;

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
    if (selectedBroker == null || selectedBroker!.isEmpty) {
      _showError('Please select a broker');
      return;
    }

    setState(() => isLoading = true);

    try {
      final parts = selectedCompany!.split('-');
      final index = int.tryParse(parts.last);

      // ── FIX 2: Robust company name resolution ────────────────────────────
      String companyName = '';

      if (index != null && index < _allStocks.length) {
        final stock = _allStocks[index];
        final ticker = stock['ticker']?.toString() ?? '';
        final name = stock['name']?.toString() ?? '';

        // Prefer ticker (Symbol); fall back to name
        companyName = ticker.isNotEmpty ? ticker : name;
      }

      // Final fallback: pull ticker straight from composite key
      // e.g. "FNBB-BW0001-3" → first segment is always the ticker
      if (companyName.isEmpty && parts.length >= 2) {
        companyName = parts[0];
      }

      // Hard guard — should never reach here, but be safe
      if (companyName.isEmpty) {
        _showError(
            'Could not determine company symbol. Please re-select the company.');
        setState(() => isLoading = false);
        return;
      }
      // ─────────────────────────────────────────────────────────────────────

      // ── FIX 3: Use UTC so toIso8601String() includes the Z suffix ────────
      final now = DateTime.now().toUtc();
      final settlementDate = now.add(const Duration(days: 2));
      final maturityDate = now.add(const Duration(days: 365));

      final orderData = {
        "OrderType": isBuy ? "BUY" : "SELL",
        "ReferenceNumber": "ORD${now.millisecondsSinceEpoch}",
        "Company": companyName,
        "Quantity": double.tryParse(quantityController.text) ?? 0,
        "BasePrice": double.tryParse(priceController.text) ?? 0,
        "TimeInForce": selectedTimeInForce,
        "BrokerCode": selectedBroker,
        "CdsAcNo": _cdsNumber ?? '',
        "Shareholder": "SHR7891011",
        "LiNumber": "LI998877",
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

      final requestBody = json.encode(orderData);
      print('=== ORDER REQUEST BODY ===');
      print(requestBody);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: requestBody,
      );

      print('=== ORDER RESPONSE STATUS: ${response.statusCode} ===');
      print('=== ORDER RESPONSE BODY: ${response.body} ===');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        // ── FIX 4: Check business-level responseCode ──────────────────────
        final responseCode = responseData[0]['responseCode'];
        final responseMessage =
            responseData[0]['responseMessage'] ?? 'Unknown error';

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
              MaterialPageRoute(
                  builder: (context) => const DashboardScreen()),
            );
          }
        } else {
          throw Exception(
              'Order rejected: $responseMessage (code $responseCode)');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
            'Failed to place order: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print('=== ORDER ERROR: $e ===');
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
    final isDark = themeProvider.isDarkMode;

    final bgGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2C1810), Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF8E7), Color(0xFFF5F5F5), Color(0xFFFFFFFF)],
    );

    final accentColor =
    isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
    final toggleBgColor =
    isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);
    final fieldBorderColor =
    isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey : Colors.grey.shade600;
    final cardColor = isDark ? const Color(0xFF3A3530) : Colors.white;
    final dropdownBgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final fieldBgColor = isDark ? Colors.transparent : Colors.grey.shade50;

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
                                : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isBuy = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: isBuy
                                        ? BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.green,
                                          Colors.black
                                        ],
                                      ),
                                      borderRadius:
                                      BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    )
                                        : null,
                                    child: Center(
                                      child: Text(
                                        'BUY',
                                        style: TextStyle(
                                          color: isBuy
                                              ? Colors.white
                                              : subtextColor,
                                          fontSize: 18,
                                          fontWeight: isBuy
                                              ? FontWeight.bold
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isBuy = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: !isBuy
                                        ? BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.black,
                                          Colors.red
                                        ],
                                      ),
                                      borderRadius:
                                      BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                          Colors.red.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    )
                                        : null,
                                    child: Center(
                                      child: Text(
                                        'SELL',
                                        style: TextStyle(
                                          color: !isBuy
                                              ? Colors.white
                                              : subtextColor,
                                          fontSize: 18,
                                          fontWeight: !isBuy
                                              ? FontWeight.bold
                                              : FontWeight.w400,
                                        ),
                                      ),
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

                        // ── Time In Force Dropdown ─────────────────────────
                        _buildDropdownField(
                          'Time In Force',
                          selectedTimeInForce,
                          timeInForceOptions,
                              (value) =>
                              setState(() => selectedTimeInForce = value),
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          dropdownBgColor: dropdownBgColor,
                          accentColor: accentColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 16),

                        // ── Broker Dropdown ────────────────────────────────
                        if (isFetchingBrokers)
                          _buildLoadingField('Broker',
                              textColor: textColor,
                              fieldBorderColor: fieldBorderColor,
                              fieldBgColor: fieldBgColor,
                              accentColor: accentColor)
                        else
                          _buildBrokerDropdown(
                            textColor: textColor,
                            fieldBorderColor: fieldBorderColor,
                            dropdownBgColor: dropdownBgColor,
                            accentColor: accentColor,
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

                        // ── Phone Number (read-only) ───────────────────────
                        _buildReadOnlyField(
                          'Phone Number',
                          _phoneNumber ?? 'N/A',
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 16),

                        // ── CDS Number (read-only) ─────────────────────────
                        _buildReadOnlyField(
                          'ACC Number',
                          _cdsNumber ?? 'N/A',
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 24),

                        // ── Order Summary ──────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isDark
                                ? []
                                : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              _summaryRow(
                                  'GROSS TOTAL:',
                                  'BWP ${grossTotal.toStringAsFixed(2)}',
                                  subtextColor),
                              const SizedBox(height: 8),
                              _summaryRow(
                                  'CUSTODIAL FEE (1%):',
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
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : () => Navigator.pop(context),
                                child: Text(
                                  'CLOSE',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                ),
                                onPressed: (isLoading ||
                                    isFetchingStocks ||
                                    isFetchingBrokers ||
                                    _allStocks.isEmpty ||
                                    _brokers.isEmpty)
                                    ? null
                                    : placeOrder,
                                child: isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2),
                                )
                                    : const Text(
                                  'PLACE ORDER',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
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

  Widget _buildLoadingField(
      String label, {
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
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorderColor, width: 1),
          ),
          child: Center(
            child:
            CircularProgressIndicator(color: accentColor, strokeWidth: 2),
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
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
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
                    style:
                    TextStyle(color: textColor.withOpacity(0.5))),
              ),
              isExpanded: true,
              dropdownColor: dropdownBgColor,
              icon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: accentColor),
              ),
              style: TextStyle(color: textColor, fontSize: 14),
              items: _allStocks.asMap().entries.map((entry) {
                final index = entry.key;
                final stock = entry.value;
                final companyName = stock['name'] ?? 'Unknown Company';
                final ticker = stock['ticker'] ?? companyName;
                final code = stock['code'] ?? '';
                final uniqueId = '$ticker-$code-$index';
                final priceValue = stock['closingPriceValue'] ?? 0.0;
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
                          child: Text(companyName,
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('(BWP $priceString)',
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

  Widget _buildBrokerDropdown({
    required Color textColor,
    required Color fieldBorderColor,
    required Color dropdownBgColor,
    required Color accentColor,
    required Color fieldBgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Broker',
            style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorderColor, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedBroker,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select Broker',
                    style:
                    TextStyle(color: textColor.withOpacity(0.5))),
              ),
              isExpanded: true,
              dropdownColor: dropdownBgColor,
              icon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: accentColor),
              ),
              style: TextStyle(color: textColor, fontSize: 14),
              items: _brokers.map((broker) {
                return DropdownMenuItem<String>(
                  value: broker['broker_code'],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      broker['fnam']!,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }).toList(),
              onChanged: _brokers.isEmpty
                  ? null
                  : (value) {
                setState(() {
                  selectedBroker = value;
                  selectedBrokerName = _brokers.firstWhere(
                        (b) => b['broker_code'] == value,
                    orElse: () => {'fnam': ''},
                  )['fnam'];
                });
              },
            ),
          ),
        ),
        if (_brokers.isEmpty && !isFetchingBrokers)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'No brokers available. Please check your connection.',
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
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
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
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
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
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorderColor, width: 1),
          ),
          child: Text(value,
              style: TextStyle(color: textColor, fontSize: 14)),
        ),
      ],
    );
  }
}