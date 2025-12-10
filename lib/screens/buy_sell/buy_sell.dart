import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeWithPrefilledData();

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C1810),
              Color(0xFF1A1A1A),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
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
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(30),
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
                                          Colors.black12,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                    )
                                        : BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'BUY',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
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
                                          Colors.black26,
                                          Colors.red,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                    )
                                        : BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'SELL',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
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

                        // Company Dropdown
                        _buildCompanyDropdown(),
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
                        ),
                        const SizedBox(height: 16),

                        // Quantity Field
                        _buildTextField(
                          'Quantity',
                          quantityController,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        // Price Field
                        _buildTextField(
                          'Price',
                          priceController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 24),

                        // Order Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A3530),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'GROSS TOTAL:',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'BWP ${grossTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'CUSTODIAL FEE (1%):',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'BWP ${custodialFee.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'CHARGES:',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'BWP ${charges.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.grey),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'NET TOTAL:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'BWP ${netTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF8B6914),
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
                                  backgroundColor: const Color(0xFF4A4540),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isLoading ? null : () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'CLOSE',
                                  style: TextStyle(
                                    color: Colors.white,
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
                                  backgroundColor: const Color(0xFF8B6914),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isLoading ? null : placeOrder,
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

  Widget _buildCompanyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF8B6914),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCompany,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select Company',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              isExpanded: true,
              dropdownColor: const Color(0xFF2A2A2A),
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: Color(0xFF8B6914)),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              items: _allStocks.map((stock) {
                return DropdownMenuItem<String>(
                  value: stock['ticker'] ?? stock['name'],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      stock['name'] ?? 'Unknown Company',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _onCompanyChanged,
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
      ValueChanged<String?> onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF8B6914),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF2A2A2A),
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: Color(0xFF8B6914)),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      option,
                      style: const TextStyle(
                        color: Colors.white,
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
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF8B6914),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF8B6914),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF8B6914),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}