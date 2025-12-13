import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMoreTransactions();
      }
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _cdsNumber = prefs.getString('cdsNumber');

      if (_cdsNumber == null) {
        setState(() {
          _errorMessage = 'CDS Number not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.3.201:5000/api/Clients/$_cdsNumber/transactions?page=$_currentPage&pageSize=$_pageSize'),
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('data')) {
          final transactions = List<Map<String, dynamic>>.from(data['data']);
          setState(() {
            _transactions = transactions;
            _hasMore = data['hasNextPage'] ?? false;
            _isLoading = false;
          });
        } else if (data is List) {
          setState(() {
            _transactions = List<Map<String, dynamic>>.from(data);
            _hasMore = data.length >= _pageSize;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Unexpected response format';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'No transactions found';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load transactions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await http.get(
        Uri.parse('http://192.168.3.201:5000/api/Clients/$_cdsNumber/transactions?page=$nextPage&pageSize=$_pageSize'),
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> newTransactions = [];
        bool hasNext = false;

        if (data is Map && data.containsKey('data')) {
          newTransactions = List<Map<String, dynamic>>.from(data['data']);
          hasNext = data['hasNextPage'] ?? false;
        } else if (data is List) {
          newTransactions = List<Map<String, dynamic>>.from(data);
          hasNext = newTransactions.length >= _pageSize;
        }

        setState(() {
          _transactions.addAll(newTransactions);
          _currentPage = nextPage;
          _hasMore = hasNext;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return 'BWP 0.00';
    try {
      final numAmount = amount is String ? double.parse(amount) : amount.toDouble();
      return 'BWP ${numAmount.toStringAsFixed(2)}';
    } catch (e) {
      return 'BWP ${amount.toString()}';
    }
  }

  String _getTransactionType(Map<String, dynamic> transaction) {
    // Use transType field from API
    if (transaction.containsKey('transType')) {
      final transType = transaction['transType'].toString();
      // Simplify the display
      if (transType.toLowerCase().contains('deposit')) {
        return 'Deposit';
      } else if (transType.toLowerCase().contains('withdrawal')) {
        return 'Withdrawal';
      }
      return transType;
    }
    if (transaction.containsKey('type')) {
      return transaction['type'].toString();
    }
    if (transaction.containsKey('transactionType')) {
      return transaction['transactionType'].toString();
    }
    // Check if amount is positive or negative
    final amount = transaction['amount'];
    if (amount != null) {
      final numAmount = amount is String ? double.tryParse(amount) : amount;
      if (numAmount != null && numAmount < 0) {
        return 'Withdrawal';
      }
    }
    return 'Deposit';
  }

  Color _getTypeColor(String type) {
    if (type.toLowerCase().contains('withdrawal') || type.toLowerCase().contains('debit')) {
      return Colors.red;
    }
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _currentPage = 1;
        await _loadTransactions();
      },
      color: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
      child: _isLoading && _transactions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading transactions...',
              style: TextStyle(
                color: widget.isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: widget.isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.isDark ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      )
          : _transactions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: widget.isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                color: widget.isDark ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader('Date'),
                  _buildTableHeader('Description'),
                  _buildTableHeader('Type'),
                  _buildTableHeader('Amount'),
                ],
              ),
              ..._transactions.map((transaction) {
                final type = _getTransactionType(transaction);
                return _buildTableRow(
                  _formatDate(transaction['date'] ?? transaction['transactionDate'] ?? transaction['createdAt']),
                  transaction['description'] ?? transaction['narration'] ?? 'Transaction',
                  type,
                  _formatAmount(transaction['amount']),
                  _getTypeColor(type),
                );
              }).toList(),
            ],
          ),
          if (_isLoading && _transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFB8860B),
                    ),
                  ),
                ),
              ),
            ),
          if (!_hasMore && _transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No more transactions',
                  style: TextStyle(
                    color: widget.isDark ? Colors.white54 : Colors.black38,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
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

  TableRow _buildTableRow(String date, String description, String type, String amount, Color typeColor) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            date,
            style: TextStyle(
              color: widget.isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            description,
            style: TextStyle(
              color: widget.isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: typeColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            amount,
            style: TextStyle(
              color: widget.isDark ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}