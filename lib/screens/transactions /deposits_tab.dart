import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class DepositsTab extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onTransactionComplete;

  const DepositsTab({Key? key, required this.isDark, this.onTransactionComplete}) : super(key: key);

  @override
  State<DepositsTab> createState() => _DepositsTabState();
}

class _DepositsTabState extends State<DepositsTab> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedProvider = 'BTC';
  String? _cdsNumber;
  bool _isLoading = false;

  final List<Map<String, String>> _providers = [
    {'name': 'Botswana Telecommunications', 'code': 'BTC'},
    {'name': 'Orange Botswana', 'code': 'ORANGE'},
    {'name': 'Mascom', 'code': 'MASCOM'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCdsNumber();
  }

  Future<void> _loadCdsNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cdsNumber = prefs.getString('cdsNumber') ?? 'CSDsd723'; // Fallback if not found
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initiateDeposit() async {
    if (_amountController.text.isEmpty || _phoneController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    if (_cdsNumber == null) {
      _showErrorDialog('CDS Number not found. Please login again.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.3.201:5000/api/Payments/deposit'),
        headers: {
          'accept': 'application/octet-stream',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'provider': _selectedProvider,
          'cdsNumber': _cdsNumber,
          'amount': double.parse(_amountController.text),
          'subscriberMsisdn': _phoneController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          _showCountdownDialog(
            data['transactionReference'],
            data['message'] ?? 'Transaction initiated',
          );
        } else {
          _showErrorDialog(data['message'] ?? 'Transaction failed');
        }
      } else {
        _showErrorDialog('Failed to initiate deposit. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Network error: ${e.toString()}');
    }
  }

  void _showCountdownDialog(String transactionRef, String message) {
    int countdown = 30;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              if (timer == null || !timer!.isActive) {
                timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
                  if (!mounted) {
                    t.cancel();
                    return;
                  }

                  setDialogState(() {
                    countdown--;
                  });

                  if (countdown <= 0) {
                    t.cancel();
                    // Use Navigator.of with root context to ensure proper cleanup
                    Navigator.of(dialogContext, rootNavigator: false).pop();
                    // Check transaction status after dialog is closed
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        _checkTransactionStatus(transactionRef);
                      }
                    });
                  }
                });
              }

              return AlertDialog(
                backgroundColor: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Waiting for Confirmation',
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB8860B)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please complete the payment on your phone',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                      ),
                      child: Center(
                        child: Text(
                          '$countdown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      timer?.cancel();
    });
  }

  Future<void> _checkTransactionStatus(String transactionRef) async {
    // Add a small delay before showing the checking dialog
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Checking transaction status...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final response = await http.post(
        Uri.parse('http://192.168.3.201:5000/api/Payments/status'),
        headers: {
          'accept': 'application/octet-stream',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'provider': _selectedProvider,
          'transactionReference': transactionRef,
          'useOriginalReference': false,
        }),
      );

      if (!mounted) return;

      // Close checking dialog
      Navigator.of(context).pop();

      // Add a small delay before showing result dialog
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['status'] == 'SUCCESS') {
          _showSuccessDialog(data['amount'], transactionRef);
        } else if (data['status'] == 'PAUSED' || data['status'] == 'PENDING') {
          _showErrorDialog('Transaction is still pending. Please check back later.');
        } else {
          _showErrorDialog(data['message'] ?? 'Transaction failed');
        }
      } else {
        _showErrorDialog('Failed to check transaction status');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close checking dialog
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      _showErrorDialog('Network error: ${e.toString()}');
    }
  }

  void _showSuccessDialog(double amount, String transactionRef) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Deposit Successful!',
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Amount: BWP ${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reference: $transactionRef',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _amountController.clear();
                _phoneController.clear();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: widget.isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Provider',
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.isDark ? Colors.white30 : Colors.black26,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProvider,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  dropdownColor: widget.isDark ? const Color(0xFF2E2E2E) : Colors.white,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                  ),
                  items: _providers.map((provider) {
                    return DropdownMenuItem<String>(
                      value: provider['code'],
                      child: Text(provider['name']!),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedProvider = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Phone Number',
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 20,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., 73001762',
                hintStyle: TextStyle(
                  color: widget.isDark ? Colors.white30 : Colors.black26,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Enter Amount (BWP)',
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 20,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., 200',
                hintStyle: TextStyle(
                  color: widget.isDark ? Colors.white30 : Colors.black26,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            if (_cdsNumber != null) ...[
              const SizedBox(height: 12),
              Text(
                'CDS Number: $_cdsNumber',
                style: TextStyle(
                  color: widget.isDark ? Colors.white60 : Colors.black45,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDark ? Colors.black45 : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        color: widget.isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _initiateDeposit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'DEPOSIT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildTransactionTable([
              {'date': '2023-01-15', 'description': 'Initial funding', 'amount': 'BWP 1,500.00'},
              {'date': '2023-02-20', 'description': 'Bonus Received', 'amount': 'BWP 375.00'},
              {'date': '2023-03-10', 'description': 'Freelance income', 'amount': 'BWP 360.00'},
              {'date': '2023-04-05', 'description': 'Deposit', 'amount': 'BWP 1,650.00'},
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTable(List<Map<String, String>> transactions) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          children: [
            _buildTableHeader('Date'),
            _buildTableHeader('Description'),
            _buildTableHeader('Amount'),
          ],
        ),
        for (var transaction in transactions)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  transaction['date']!,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  transaction['description']!,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  transaction['amount']!,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}