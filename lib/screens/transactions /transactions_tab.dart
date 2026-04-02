import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionsTab extends StatefulWidget {
  final bool isDark;

  const TransactionsTab({Key? key, required this.isDark}) : super(key: key);

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _cdsNumber;
  String? _token;

  static const String _apiUrl =
      'https://zamagm.escrowagm.com/MainAPI/Home/Transactions';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _cdsNumber = prefs.getString('cdsNumber');
      _token = prefs.getString('token');

      if (_cdsNumber == null || _cdsNumber!.isEmpty) {
        setState(() {
          _errorMessage = 'CDS Number not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http
          .post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode({'CDSNumber': _cdsNumber}),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
        throw TimeoutException('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Map<String, dynamic>> transactions = [];

        if (data is List) {
          transactions = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          transactions = List<Map<String, dynamic>>.from(data['data']);
        }

        // Sort by date descending (most recent first)
        transactions.sort((a, b) {
          final dateA = _parseDate(a['DateCreated']);
          final dateB = _parseDate(b['DateCreated']);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });

        setState(() {
          _transactions = transactions;
          _isLoading = false;
          if (transactions.isEmpty) {
            _errorMessage = null; // show empty state
          }
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'No transactions found.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
          'Failed to load transactions. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMessage =
        'Connection timeout. Please check your internet connection.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Error loading transactions: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Parses a date string into a DateTime, returning null on failure.
  /// Handles both ISO 8601 ("2026-02-28T...") and "M/d/yyyy h:mm:ss a" formats.
  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    // Try ISO 8601 first
    final iso = DateTime.tryParse(dateString);
    if (iso != null) return iso;
    // Try "2/28/2026 4:03:20 PM"
    try {
      final parts = dateString.split(' ');
      final dateParts = parts[0].split('/');
      if (dateParts.length == 3) {
        final month = int.parse(dateParts[0]);
        final day = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);
        int hour = 0, minute = 0, second = 0;
        if (parts.length >= 2) {
          final timeParts = parts[1].split(':');
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
          second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
          if (parts.length >= 3 && parts[2].toUpperCase() == 'PM' && hour != 12) {
            hour += 12;
          } else if (parts.length >= 3 && parts[2].toUpperCase() == 'AM' && hour == 12) {
            hour = 0;
          }
        }
        return DateTime(year, month, day, hour, minute, second);
      }
    } catch (_) {}
    return null;
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    final date = _parseDate(dateString);
    if (date != null) {
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }
    return dateString;
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return 'BWP 0.00';
    try {
      double value;
      if (amount is String) {
        value = double.parse(amount);
      } else if (amount is int) {
        value = amount.toDouble();
      } else if (amount is double) {
        value = amount;
      } else {
        value = double.parse(amount.toString());
      }
      return 'BWP ${value.toStringAsFixed(2)}';
    } catch (_) {
      return 'BWP $amount';
    }
  }

  /// Determine credit/debit from Amount sign and Description
  bool _isCredit(Map<String, dynamic> tx) {
    final raw = tx['Amount'];
    if (raw != null) {
      double? n;
      if (raw is String) {
        n = double.tryParse(raw);
      } else if (raw is int) {
        n = raw.toDouble();
      } else if (raw is double) {
        n = raw;
      } else {
        n = double.tryParse(raw.toString());
      }
      if (n != null) return n >= 0;
    }
    final desc = (tx['Description'] ?? '').toString().toLowerCase();
    return desc.contains('deposit') || desc.contains('credit');
  }

  String _typeLabel(Map<String, dynamic> tx) {
    final desc = (tx['Description'] ?? '').toString().toLowerCase();
    if (desc.contains('deposit')) return 'Deposit';
    if (desc.contains('withdrawal')) return 'Withdrawal';
    if (desc.contains('buy')) return 'Buy';
    if (desc.contains('sell')) return 'Sell';
    return _isCredit(tx) ? 'Credit' : 'Debit';
  }

  Color _typeColor(Map<String, dynamic> tx) {
    if (_isCredit(tx)) return Colors.green;
    return Colors.red;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDark
        ? const Color(0xFF8B6914)
        : const Color(0xFFB8860B);
    final textColor =
    widget.isDark ? Colors.white : Colors.black87;
    final subColor =
    widget.isDark ? Colors.white70 : Colors.black54;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
            const SizedBox(height: 16),
            Text('Loading transactions...',
                style: TextStyle(color: subColor)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64,
                color: widget.isDark ? Colors.white30 : Colors.black26),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subColor, fontSize: 15)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long,
                size: 64,
                color: widget.isDark ? Colors.white30 : Colors.black26),
            const SizedBox(height: 16),
            Text('No transactions yet',
                style: TextStyle(color: subColor, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      color: accentColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                _headerCell('Date', flex: 2),
                _headerCell('Description', flex: 3),
                _headerCell('Type', flex: 2),
                _headerCell('Amount', flex: 2, align: TextAlign.right),
              ],
            ),
          ),

          Divider(
              color: widget.isDark
                  ? Colors.white12
                  : Colors.black12),

          // ── Transaction rows ─────────────────────────────────────────
          ..._transactions.map((tx) {
            final color = _typeColor(tx);
            final label = _typeLabel(tx);
            final amount = tx['Amount'];
            final isNegative = () {
              try {
                double n;
                if (amount is String) {
                  n = double.parse(amount);
                } else if (amount is int) {
                  n = amount.toDouble();
                } else if (amount is double) {
                  n = amount;
                } else {
                  n = double.parse(amount.toString());
                }
                return n < 0;
              } catch (_) {
                return false;
              }
            }();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatDate(tx['DateCreated']),
                          style:
                          TextStyle(color: textColor, fontSize: 12),
                        ),
                      ),
                      // Description + Reference
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['Description'] ?? '-',
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (tx['Reference'] != null &&
                                tx['Reference'].toString().isNotEmpty)
                              Text(
                                tx['Reference'],
                                style: TextStyle(
                                    color: subColor, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Type badge
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      // Amount
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatAmount(amount),
                          style: TextStyle(
                            color: isNegative ? Colors.red : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    color: widget.isDark
                        ? Colors.white10
                        : Colors.black38),
              ],
            );
          }).toList(),

          const SizedBox(height: 24),
          Center(
            child: Text(
              '${_transactions.length} transaction${_transactions.length == 1 ? '' : 's'}',
              style: TextStyle(color: subColor, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _headerCell(String text,
      {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}