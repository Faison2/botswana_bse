import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WithdrawalsTab extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onTransactionComplete;

  const WithdrawalsTab({Key? key, required this.isDark, this.onTransactionComplete}) : super(key: key);

  @override
  State<WithdrawalsTab> createState() => _WithdrawalsTabState();
}

class _WithdrawalsTabState extends State<WithdrawalsTab> {
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

  Future<void> _initiateWithdrawal() async {
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
        Uri.parse('http://192.168.3.201:5000/api/Payments/withdraw'),
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
          _showSuccessDialog(
            data['message'] ?? 'Withdrawal completed successfully',
            data['amount'] ?? 0.0,
            data['transactionReference'] ?? '',
          );
        } else {
          _showErrorDialog(data['message'] ?? 'Withdrawal failed');
        }
      } else {
        _showErrorDialog('Failed to process withdrawal. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Network error: ${e.toString()}');
    }
  }

  void _showSuccessDialog(String message, dynamic amount, String transactionRef) {
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
                'Withdrawal Successful!',
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.green.withOpacity(0.1) : Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white70 : Colors.black87,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount:',
                    style: TextStyle(
                      color: widget.isDark ? Colors.white60 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'BWP ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: widget.isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Transaction Reference:',
                style: TextStyle(
                  color: widget.isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                transactionRef,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontFamily: 'monospace',
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
                // Refresh balance after successful transaction
                widget.onTransactionComplete?.call();
              },
              style: TextButton.styleFrom(
                backgroundColor: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'DONE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
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
              const Icon(Icons.error_outline, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Text(
                'Error',
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: widget.isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
                hintText: 'e.g., 100',
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
                    onPressed: _isLoading ? null : _initiateWithdrawal,
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
                      'WITHDRAW',
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
              {'date': '2023-01-15', 'description': 'Withdrawal', 'amount': 'BWP 1,500.00'},
              {'date': '2023-02-20', 'description': 'Emergency funds', 'amount': 'BWP 375.00'},
              {'date': '2023-03-10', 'description': 'Withdrawal', 'amount': 'BWP 360.00'},
              {'date': '2023-04-05', 'description': 'Withdrawal', 'amount': 'BWP 1,650.00'},
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