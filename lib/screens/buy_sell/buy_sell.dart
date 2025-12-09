import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard/dashboard.dart';

class TradingPage extends StatefulWidget {
  const TradingPage({Key? key}) : super(key: key);

  @override
  State<TradingPage> createState() => _TradingPageState();
}

class _TradingPageState extends State<TradingPage> {
  bool isBuy = true;
  bool isLoading = false;
  String? _token;
  String? _userName;

  final companyController = TextEditingController(text: 'LPPJ');
  final timeInForceController = TextEditingController(text: 'Day Order');
  final brokerController = TextEditingController(text: 'B20/C');
  final quantityController = TextEditingController(text: '1000');
  final priceController = TextEditingController(text: '12.50');

  // Additional fields
  final referenceNumberController = TextEditingController(text: 'ORD${DateTime.now().millisecondsSinceEpoch}');
  final cdsAcNoController = TextEditingController(text: 'CDS123456');
  final shareholderController = TextEditingController(text: 'SHR7891011');
  final liNumberController = TextEditingController(text: 'LI998877');
  final clientNameController = TextEditingController(); // Will be populated from SharedPreferences
  final brokerRefController = TextEditingController(text: 'BRREF${DateTime.now().millisecondsSinceEpoch}');
  final settlementAmountController = TextEditingController(text: '0.00');
  final chargesController = TextEditingController(text: '150.00');
  final brokerageController = TextEditingController(text: '1.20');
  final currencyController = TextEditingController(text: 'BWP');

  static const String apiUrl = 'http://192.168.3.201/MainAPI/Home/OrderPosting';

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Update calculations whenever controllers change
    quantityController.addListener(updateCalculations);
    priceController.addListener(updateCalculations);
    chargesController.addListener(updateCalculations);
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
          clientNameController.text = _userName!;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication token not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          // Optionally navigate to login
          // Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    companyController.dispose();
    timeInForceController.dispose();
    brokerController.dispose();
    quantityController.dispose();
    priceController.dispose();
    referenceNumberController.dispose();
    cdsAcNoController.dispose();
    shareholderController.dispose();
    liNumberController.dispose();
    clientNameController.dispose();
    brokerRefController.dispose();
    settlementAmountController.dispose();
    chargesController.dispose();
    brokerageController.dispose();
    currencyController.dispose();
    super.dispose();
  }

  // Calculate totals
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

  // Update settlement amount when values change
  void updateCalculations() {
    setState(() {
      settlementAmountController.text = netTotal.toStringAsFixed(2);
    });
  }

  Future<void> placeOrder() async {
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No authentication token available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Calculate settlement date (e.g., 2 days from now)
      final settlementDate = DateTime.now().add(const Duration(days: 2));
      final maturityDate = DateTime.now().add(const Duration(days: 365));

      final orderData = {
        "OrderType": isBuy ? "BUY" : "SELL",
        "ReferenceNumber": referenceNumberController.text,
        "Company": companyController.text,
        "Quantity": double.tryParse(quantityController.text) ?? 0,
        "BasePrice": double.tryParse(priceController.text) ?? 0,
        "TimeInForce": timeInForceController.text,
        "BrokerCode": brokerController.text,
        "CdsAcNo": cdsAcNoController.text,
        "Shareholder": shareholderController.text,
        "LiNumber": liNumberController.text,
        "ClientName": clientNameController.text,
        "BrokerRef": brokerRefController.text,
        "SettlementDate": settlementDate.toIso8601String(),
        "SettlementAmount": netTotal,
        "Charges": charges,
        "Brokerage": double.tryParse(brokerageController.text) ?? 0,
        "MaturityDate": maturityDate.toIso8601String().split('T')[0],
        "Currency": currencyController.text,
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

          // Navigate back to dashboard
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                        // Client Information Section
                        const Text(
                          'CLIENT INFORMATION',
                          style: TextStyle(
                            color: Color(0xFF8B6914),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildReadOnlyField('Client Name', clientNameController),
                        _buildTextField('CDS Account No', cdsAcNoController),
                        _buildTextField('Shareholder', shareholderController),
                        _buildTextField('LI Number', liNumberController),

                        const SizedBox(height: 24),
                        const Text(
                          'ORDER DETAILS',
                          style: TextStyle(
                            color: Color(0xFF8B6914),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField('Reference Number', referenceNumberController),
                        _buildTextField('Company', companyController),
                        _buildTextField('Quantity', quantityController, keyboardType: TextInputType.number),
                        _buildTextField('Base Price', priceController, keyboardType: TextInputType.numberWithOptions(decimal: true)),
                        _buildTextField('Time In Force', timeInForceController),
                        _buildTextField('Broker Code', brokerController),
                        _buildTextField('Broker Reference', brokerRefController),
                        _buildTextField('Currency', currencyController),

                        const SizedBox(height: 24),
                        const Text(
                          'CHARGES & FEES',
                          style: TextStyle(
                            color: Color(0xFF8B6914),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField('Charges', chargesController, keyboardType: TextInputType.numberWithOptions(decimal: true)),
                        _buildTextField('Brokerage (%)', brokerageController, keyboardType: TextInputType.numberWithOptions(decimal: true)),

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
                                    '${currencyController.text}${grossTotal.toStringAsFixed(2)}',
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
                                    '${currencyController.text}${custodialFee.toStringAsFixed(2)}',
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
                                    '${currencyController.text}${charges.toStringAsFixed(2)}',
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
                                    '${currencyController.text}${netTotal.toStringAsFixed(2)}',
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
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A4540),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isLoading ? null : () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'CANCEL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B6914),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
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
          enabled: false,
          style: const TextStyle(color: Colors.white70),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4A4540),
                width: 1,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4A4540),
                width: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
      ],
    );
  }
}