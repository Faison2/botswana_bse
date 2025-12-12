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

  // Controllers
  String? selectedCompany;
  String? selectedTimeInForce = 'Day Order';
  String? selectedBroker = 'INVESTOR IQ';
  final quantityController = TextEditingController(text: '200');
  final priceController = TextEditingController(text: '6.20');

  // For calculations
  final chargesController = TextEditingController(text: '0.00');

  List<Map<String, dynamic>> _allStocks = [];

  // Dropdown options
  final List<String> timeInForceOptions = ['Day Order', 'Good Till Cancelled'];
  final List<String> brokerOptions = ['INVESTOR IQ', 'Other'];

  static const String apiUrl = 'http://192.168.3.201/MainAPI/Home/OrderPosting';
  static const String marketDataUrl = 'http://192.168.3.201/MainAPI/Home/getMarketData';

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

      // Set selected company
      selectedCompany = stockData['ticker'] ?? stockData['name'];

      // Pre-fill price
      priceController.text = stockData['closingPriceValue']?.toString() ?? '0.00';

      updateCalculations();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final fullName = prefs.getString('fullName');

      if (token != null && token.isNotEmpty) {
        setState(() {
          _token = token;
          _userName = fullName ?? 'N/A';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _fetchStocksIfNeeded() async {
    // If stocks were passed from previous screen, don't fetch again
    if (widget.allStocks != null && widget.allStocks!.isNotEmpty) {
      return;
    }

    // Wait for token to load
    if (_token == null) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (_token == null) {
      print('No token available for fetching stocks');
      return;
    }

    // Fetch stocks from API
    await _fetchStocksFromApi();
  }

  Future<void> _fetchStocksFromApi() async {
    setState(() {
      isFetchingStocks = true;
    });

    try {
      final response = await http.post(
        Uri.parse(marketDataUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      print('Stocks API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        List<Map<String, dynamic>> stocks = [];

        if (jsonData.isNotEmpty && jsonData[0]['MdataItem'] != null) {
          final List<dynamic> items = jsonData[0]['MdataItem'];

          for (var item in items) {
            stocks.add(_mapApiDataToStock(item));
          }
        }

        print('Parsed ${stocks.length} stocks in TradingPage');

        setState(() {
          _allStocks = stocks;

          // If we have prefilled data but it's not in our fetched list,
          // add it to ensure we can select it
          if (widget.prefilledStockData != null && stocks.isNotEmpty) {
            final prefilledTicker = widget.prefilledStockData!['ticker'];
            final prefilledName = widget.prefilledStockData!['name'];

            // Check if prefilled stock exists in fetched list
            bool exists = stocks.any((stock) =>
            stock['ticker'] == prefilledTicker || stock['name'] == prefilledName);

            if (!exists) {
              // Add the prefilled stock to the list
              _allStocks.add(widget.prefilledStockData!);
            }

            // Set selected company from prefilled data
            selectedCompany = prefilledTicker ?? prefilledName;

            // Update price from prefilled data
            priceController.text = widget.prefilledStockData!['closingPriceValue']?.toString() ?? '0.00';
          } else if (selectedCompany == null && _allStocks.isNotEmpty) {
            // If no company is selected yet, select the first one
            selectedCompany = _allStocks[0]['ticker'] ?? _allStocks[0]['name'];
            // Also update price for the selected company
            priceController.text = _allStocks[0]['closingPriceValue']?.toString() ?? '0.00';
          }

          updateCalculations();
        });
      } else {
        print('Failed to fetch stocks in TradingPage: ${response.statusCode}');
        // If we have prefilled data, use it as the only option
        if (widget.prefilledStockData != null) {
          setState(() {
            _allStocks = [widget.prefilledStockData!];
            selectedCompany = widget.prefilledStockData!['ticker'] ?? widget.prefilledStockData!['name'];
          });
        }
      }
    } catch (e) {
      print('Error fetching stocks in TradingPage: $e');
      // If we have prefilled data, use it as the only option
      if (widget.prefilledStockData != null) {
        setState(() {
          _allStocks = [widget.prefilledStockData!];
          selectedCompany = widget.prefilledStockData!['ticker'] ?? widget.prefilledStockData!['name'];
        });
      }
    } finally {
      setState(() {
        isFetchingStocks = false;
      });
    }
  }

  // Same mapping function as in MarketWatchWidget
  Map<String, dynamic> _mapApiDataToStock(dynamic item) {
    String name = item['Company']?.toString() ?? 'Unknown';
    String ticker = item['Symbol']?.toString() ?? 'N/A';
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

    // Get icon and color (optional, you can remove if not needed)
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
      // Add raw numeric values for trading page
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
      if (num >= 1000000000) {
        return '${(num / 1000000000).toStringAsFixed(2)}B';
      } else if (num >= 1000000) {
        return '${(num / 1000000).toStringAsFixed(2)}M';
      } else if (num >= 1000) {
        return '${(num / 1000).toStringAsFixed(2)}K';
      }
      return num.toStringAsFixed(0);
    } catch (e) {
      return '0';
    }
  }

  IconData _getIconForStock(String symbol) {
    final upperSymbol = symbol.toUpperCase();

    if (upperSymbol.contains('BANK') ||
        upperSymbol.contains('CRDB') ||
        upperSymbol.contains('NMB') ||
        upperSymbol.contains('KCB') ||
        upperSymbol.contains('DCB') ||
        upperSymbol.contains('MKCB') ||
        upperSymbol.contains('MUCOBA') ||
        upperSymbol.contains('MCB') ||
        upperSymbol.contains('MBP')) {
      return Icons.account_balance;
    } else if (upperSymbol.contains('BREW') ||
        upperSymbol.contains('TBL') ||
        upperSymbol.contains('EABL')) {
      return Icons.local_drink;
    } else if (upperSymbol.contains('AIR') ||
        upperSymbol.contains('KA') ||
        upperSymbol.contains('PAL')) {
      return Icons.flight;
    } else if (upperSymbol.contains('CEMENT') ||
        upperSymbol.contains('TCCL') ||
        upperSymbol.contains('TPCC')) {
      return Icons.construction;
    } else if (upperSymbol.contains('VODA') ||
        upperSymbol.contains('TELECOM')) {
      return Icons.phone_android;
    } else if (upperSymbol.contains('MEDIA') ||
        upperSymbol.contains('NMG')) {
      return Icons.newspaper;
    } else if (upperSymbol.contains('INSURANCE') ||
        upperSymbol.contains('JHL')) {
      return Icons.security;
    } else if (upperSymbol.contains('OIL') ||
        upperSymbol.contains('GAS') ||
        upperSymbol.contains('SWALA') ||
        upperSymbol.contains('TOL')) {
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

    final index = symbol.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    chargesController.dispose();
    super.dispose();
  }

  double get grossTotal {
    final quantity = double.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    return quantity * price;
  }

  double get custodialFee {
    return grossTotal * 0.01; // 1%
  }

  double get charges {
    return double.tryParse(chargesController.text) ?? 0;
  }

  double get netTotal {
    return grossTotal + custodialFee + charges;
  }

  void updateCalculations() {
    setState(() {});
  }

  void _onCompanyChanged(String? newCompany) {
    if (newCompany == null) return;

    setState(() {
      selectedCompany = newCompany;

      // Find the stock data for the selected company
      final stockData = _allStocks.firstWhere(
            (stock) => stock['ticker'] == newCompany || stock['name'] == newCompany,
        orElse: () => {},
      );

      if (stockData.isNotEmpty) {
        // Update price
        priceController.text = stockData['closingPriceValue']?.toString() ?? '0.00';
        updateCalculations();
      }
    });
  }

  Future<void> placeOrder() async {
    if (_token == null) {
      _showError('No authentication token available');
      return;
    }

    if (selectedCompany == null || selectedCompany!.isEmpty) {
      _showError('Please select a company');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final settlementDate = DateTime.now().add(const Duration(days: 2));
      final maturityDate = DateTime.now().add(const Duration(days: 365));

      final orderData = {
        "OrderType": isBuy ? "BUY" : "SELL",
        "ReferenceNumber": "ORD${DateTime.now().millisecondsSinceEpoch}",
        "Company": selectedCompany,
        "Quantity": double.tryParse(quantityController.text) ?? 0,
        "BasePrice": double.tryParse(priceController.text) ?? 0,
        "TimeInForce": selectedTimeInForce,
        "BrokerCode": selectedBroker,
        "CdsAcNo": "CDS123456",
        "Shareholder": "SHR7891011",
        "LiNumber": "LI998877",
        "ClientName": _userName ?? 'N/A',
        "BrokerRef": "BRREF${DateTime.now().millisecondsSinceEpoch}",
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
        final responseData = json.decode(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Order #${responseData[0]['ordernumber']} placed successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to place order: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2C1810),
        Color(0xFF1A1A1A),
        Color(0xFF0D0D0D),
      ],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFF8E7),
        Color(0xFFF5F5F5),
        Color(0xFFFFFFFF),
      ],
    );

    final accentColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
    final toggleBgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);
    final fieldBorderColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
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
                        // BUY/SELL Toggle
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
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isBuy = true;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: isBuy
                                        ? BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.green,
                                          Colors.black,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    )
                                        : null,
                                    child: Center(
                                      child: Text(
                                        'BUY',
                                        style: TextStyle(
                                          color: isBuy ? Colors.white : subtextColor,
                                          fontSize: 18,
                                          fontWeight: isBuy ? FontWeight.bold : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isBuy = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: !isBuy
                                        ? BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                         Colors.black,
                                          Colors.red,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    )
                                        : null,
                                    child: Center(
                                      child: Text(
                                        'SELL',
                                        style: TextStyle(
                                          color: !isBuy ? Colors.white : subtextColor,
                                          fontSize: 18,
                                          fontWeight: !isBuy ? FontWeight.bold : FontWeight.w400,
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

                        // Company Dropdown with loading state
                        if (isFetchingStocks)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Company',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: fieldBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: fieldBorderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: accentColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          _buildCompanyDropdown(
                            textColor: textColor,
                            fieldBorderColor: fieldBorderColor,
                            dropdownBgColor: dropdownBgColor,
                            accentColor: accentColor,
                            fieldBgColor: fieldBgColor,
                          ),
                        const SizedBox(height: 16),

                        // Time In Force Dropdown
                        _buildDropdownField(
                          'Time In Force',
                          selectedTimeInForce,
                          timeInForceOptions,
                              (value) {
                            setState(() {
                              selectedTimeInForce = value;
                            });
                          },
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          dropdownBgColor: dropdownBgColor,
                          accentColor: accentColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 16),

                        // Broker Dropdown
                        _buildDropdownField(
                          'Broker',
                          selectedBroker,
                          brokerOptions,
                              (value) {
                            setState(() {
                              selectedBroker = value;
                            });
                          },
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          dropdownBgColor: dropdownBgColor,
                          accentColor: accentColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 16),

                        // Quantity Field
                        _buildTextField(
                          'Quantity',
                          quantityController,
                          keyboardType: TextInputType.number,
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 16),

                        // Price Field
                        _buildTextField(
                          'Price',
                          priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textColor: textColor,
                          fieldBorderColor: fieldBorderColor,
                          fieldBgColor: fieldBgColor,
                        ),
                        const SizedBox(height: 24),

                        // Order Summary
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
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'GROSS TOTAL:',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'BWP ${grossTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'CUSTODIAL FEE (1%):',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'BWP ${custodialFee.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'CHARGES:',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'BWP ${charges.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: subtextColor),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'NET TOTAL:',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'BWP ${netTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isLoading ? null : () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'CLOSE',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: (isLoading || isFetchingStocks || _allStocks.isEmpty) ? null : placeOrder,
                                child: isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  'PLACE ORDER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
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
        Text(
          'Company',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: fieldBorderColor,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCompany,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select Company',
                  style: TextStyle(color: textColor.withOpacity(0.5)),
                ),
              ),
              isExpanded: true,
              dropdownColor: dropdownBgColor,
              icon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: accentColor),
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              items: _allStocks.map((stock) {
                final companyName = stock['name'] ?? 'Unknown Company';
                final ticker = stock['ticker'] ?? companyName;

                // Get the current price
                final priceValue = stock['closingPriceValue'] ?? 0.0;
                final priceString = priceValue is double
                    ? priceValue.toStringAsFixed(2)
                    : priceValue.toString();

                return DropdownMenuItem<String>(
                  value: ticker,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            companyName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '(BWP $priceString)',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
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
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fieldBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: fieldBorderColor,
              width: 1,
            ),
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
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: textColor),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldBgColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: fieldBorderColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: fieldBorderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: fieldBorderColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}