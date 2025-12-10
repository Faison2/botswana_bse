import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MarketWatchWidget extends StatefulWidget {
  final bool isDark;
  final bool showLimited;

  const MarketWatchWidget({
    Key? key,
    required this.isDark,
    this.showLimited = true,
  }) : super(key: key);

  @override
  State<MarketWatchWidget> createState() => _MarketWatchWidgetState();
}

class _MarketWatchWidgetState extends State<MarketWatchWidget> {
  List<Map<String, dynamic>> _stocks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMarketData();
  }

  Future<void> _fetchMarketData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'No authentication token found';
          _isLoading = false;
        });
        return;
      }

      // Make API call
      final response = await http.post(
        Uri.parse('http://192.168.3.201/MainAPI/Home/getMarketData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        List<Map<String, dynamic>> stocks = [];

        // Parse the API response structure
        if (jsonData.isNotEmpty && jsonData[0]['MdataItem'] != null) {
          final List<dynamic> items = jsonData[0]['MdataItem'];

          for (var item in items) {
            stocks.add(_mapApiDataToStock(item));
          }
        }

        print('Parsed ${stocks.length} stocks');

        setState(() {
          _stocks = stocks;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching market data: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _mapApiDataToStock(dynamic item) {
    // Extract data from API response
    String name = item['Company']?.toString() ?? 'Unknown';
    String ticker = item['Symbol']?.toString() ?? 'N/A';
    String code = item['Code']?.toString() ?? '';

    // Prices
    String closingPrice = item['ClosingPrice']?.toString() ?? '0';
    String openingPrice = item['OpeningPrice']?.toString() ?? '0';
    String maxPrice = item['MaxPrice']?.toString() ?? '0';
    String minPrice = item['MinPrice']?.toString() ?? '0';

    // Format for display
    String price = 'TZS $closingPrice';
    String bestBid = 'TZS $openingPrice';
    String bestAsk = 'TZS $maxPrice';

    // For supply/demand, use formatted volume or placeholder
    String openInterest = item['Openinterest']?.toString() ?? '0';
    String supply = _formatVolume(openInterest);
    String demand = '-';

    // Status
    String status = item['status']?.toString() ?? '';

    return {
      'name': name,
      'ticker': ticker,
      'price': price,
      'bestBid': bestBid,
      'bestAsk': bestAsk,
      'supply': supply,
      'demand': demand,
      'icon': _getIconForStock(ticker),
      'color': _getColorForStock(ticker),
      'status': status,
      'code': code,
    };
  }

  // Helper method to format large volume numbers
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            color: widget.isDark ? Colors.amber : Colors.blue,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: widget.isDark ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMarketData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_stocks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            'No market data available',
            style: TextStyle(
              color: widget.isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Display only first 4 stocks if showLimited is true
    final displayStocks = widget.showLimited
        ? _stocks.take(4).toList()
        : _stocks;

    return Column(
      children: [
        for (int i = 0; i < displayStocks.length; i++) ...[
          _buildStockCard(
            displayStocks[i]['name']!,
            displayStocks[i]['ticker']!,
            displayStocks[i]['price']!,
            displayStocks[i]['bestBid']!,
            displayStocks[i]['bestAsk']!,
            displayStocks[i]['supply']!,
            displayStocks[i]['demand']!,
            displayStocks[i]['icon'] as IconData,
            displayStocks[i]['color'] as Color,
            widget.isDark,
          ),
          if (i < displayStocks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildStockCard(
      String name,
      String ticker,
      String price,
      String bestBid,
      String bestAsk,
      String supply,
      String demand,
      IconData iconData,
      Color iconBgColor,
      bool isDark,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A33) : Colors.white,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              iconData,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticker,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildInfoColumn('Open:', bestBid, isDark),
                    const SizedBox(width: 12),
                    _buildInfoColumn('High:', bestAsk, isDark),
                    const SizedBox(width: 12),
                    _buildInfoColumn('Volume:', supply, isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.5)
                : Colors.black.withOpacity(0.5),
            fontSize: 9,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : Colors.black.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}