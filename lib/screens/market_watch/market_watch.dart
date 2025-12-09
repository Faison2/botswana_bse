import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MarketWatchScreen extends StatefulWidget {
  const MarketWatchScreen({super.key});

  @override
  State<MarketWatchScreen> createState() => _MarketWatchScreenState();
}

class _MarketWatchScreenState extends State<MarketWatchScreen> {
  Timer? _timer;
  List<Map<String, dynamic>> _marketData = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _token;

  final String _apiUrl = 'http://192.168.3.201/MainAPI/Home/getMarketData';

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    await _loadToken();
    if (_token != null) {
      await _fetchMarketData();
      _startAutoRefresh();
    } else {
      setState(() {
        _errorMessage = 'No authentication token found. Please login again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        setState(() {
          _token = token;
        });
      } else {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading token: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMarketData() async {
    if (_token == null) {
      setState(() {
        _errorMessage = 'No authentication token available';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        if (jsonData.isNotEmpty && jsonData[0]['MdataItem'] != null) {
          final List<dynamic> items = jsonData[0]['MdataItem'];

          setState(() {
            _marketData = items.map((item) {
              final Map<String, dynamic> raw = Map<String, dynamic>.from(item as Map);

              final closePrice = double.tryParse(raw['ClosingPrice']?.toString() ?? '0') ?? 0;

              return {
                ...raw,
                'priceHistory': _generatePriceHistory(closePrice),
                'currentPrice': closePrice,
                'iconData': _getIconForCompany(raw['Symbol'] ?? ''),
                'iconBg': _getColorForCompany(raw['Symbol'] ?? ''),
              };
            }).toList();
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
        // Optionally, navigate to login screen
        // Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _errorMessage = 'Failed to load data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<double> _generatePriceHistory(double basePrice) {
    final history = <double>[];
    for (int i = 0; i < 30; i++) {
      history.add(basePrice + (math.Random().nextDouble() - 0.5) * (basePrice * 0.05));
    }
    return history;
  }

  IconData _getIconForCompany(String symbol) {
    if (symbol.contains('BANK') || symbol.contains('CRDB') || symbol.contains('NMB') || symbol.contains('KCB') || symbol.contains('DCB') || symbol.contains('MKCB') || symbol.contains('MUCOBA') || symbol.contains('MCB') || symbol.contains('MBP')) {
      return Icons.account_balance;
    } else if (symbol.contains('BREW') || symbol.contains('TBL') || symbol.contains('EABL')) {
      return Icons.local_drink;
    } else if (symbol.contains('AIR') || symbol.contains('KA') || symbol.contains('PAL')) {
      return Icons.flight;
    } else if (symbol.contains('CEMENT') || symbol.contains('TCCL') || symbol.contains('TPCC')) {
      return Icons.construction;
    } else if (symbol.contains('VODA') || symbol.contains('TELECOM')) {
      return Icons.phone_android;
    } else if (symbol.contains('MEDIA') || symbol.contains('NMG')) {
      return Icons.newspaper;
    } else if (symbol.contains('INSURANCE') || symbol.contains('JHL')) {
      return Icons.security;
    } else if (symbol.contains('OIL') || symbol.contains('GAS') || symbol.contains('SWALA') || symbol.contains('TOL')) {
      return Icons.local_gas_station;
    }
    return Icons.business;
  }

  Color _getColorForCompany(String symbol) {
    final hash = symbol.hashCode;
    final colors = [
      const Color(0xFF3D2F1F),
      const Color(0xFF2A3F2F),
      const Color(0xFF2F3A4A),
      const Color(0xFF4A2F2F),
      const Color(0xFF2F4A3F),
      const Color(0xFF3F2F4A),
    ];
    return colors[hash.abs() % colors.length];
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchMarketData();
    });
  }

  void _showStockDetails(Map<String, dynamic> stock) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.5 * 255).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: stock['iconBg'],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).round()),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          stock['iconData'],
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stock['Company'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stock['Symbol'] ?? 'N/A',
                              style: TextStyle(
                                color: Colors.white.withAlpha((0.7 * 255).round()),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Container(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price Section
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Current Price',
                                style: TextStyle(
                                  color: Colors.white.withAlpha((0.6 * 255).round()),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'TZS ${stock['ClosingPrice']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: stock['status'] == 'GAIN'
                                      ? Colors.green.withAlpha((0.2 * 255).round())
                                      : stock['status'] == 'LOSE'
                                      ? Colors.red.withAlpha((0.2 * 255).round())
                                      : Colors.grey.withAlpha((0.2 * 255).round()),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  stock['status'] ?? 'NO CHANGE',
                                  style: TextStyle(
                                    color: stock['status'] == 'GAIN'
                                        ? Colors.green
                                        : stock['status'] == 'LOSE'
                                        ? Colors.red
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFF3A3A3A)),
                        const SizedBox(height: 16),

                        // Price Details
                        _buildDetailRow('Opening Price', 'TZS ${stock['OpeningPrice'] ?? 'N/A'}'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Closing Price', 'TZS ${stock['ClosingPrice'] ?? 'N/A'}'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Settlement Price', 'TZS ${stock['SettlementPrice'] ?? 'N/A'}'),
                        const SizedBox(height: 12),
                        _buildDetailRow('VWAP Price', 'TZS ${stock['VwapPrice'] ?? 'N/A'}'),

                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF3A3A3A)),
                        const SizedBox(height: 16),

                        // Range Details
                        _buildDetailRow('Maximum Price', 'TZS ${stock['MaxPrice'] ?? 'N/A'}'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Minimum Price', 'TZS ${stock['MinPrice'] ?? 'N/A'}'),

                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF3A3A3A)),
                        const SizedBox(height: 16),

                        // Additional Details
                        _buildDetailRow('ISIN', stock['ISIN'] ?? 'N/A'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Code', stock['Code'] ?? 'N/A'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Security Type', stock['securitytype'] ?? 'N/A'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Open Interest', stock['Openinterest'] ?? 'N/A'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha((0.6 * 255).round()),
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Market Watch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _fetchMarketData,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
                    : _errorMessage != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeAndFetch,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                    : _marketData.isEmpty
                    ? const Center(
                  child: Text(
                    'No market data available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _marketData.length,
                  itemBuilder: (context, index) {
                    final stock = _marketData[index];
                    return _buildStockCard(stock);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> stock) {
    final priceHistory = stock['priceHistory'] as List<double>;
    final closePrice = double.tryParse(stock['ClosingPrice']?.toString() ?? '0') ?? 0;
    final isPositive = closePrice >= closePrice;

    return GestureDetector(
      onTap: () => _showStockDetails(stock),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.2 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Company Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: stock['iconBg'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(stock['iconData'], color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),

                // Company Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock['Company'] ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stock['Symbol'] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.5 * 255).round()),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TZS ${stock['ClosingPrice'] ?? '0'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: stock['status'] == 'GAIN'
                            ? Colors.green.withAlpha((0.2 * 255).round())
                            : stock['status'] == 'LOSE'
                            ? Colors.red.withAlpha((0.2 * 255).round())
                            : Colors.grey.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        stock['status'] ?? 'N/A',
                        style: TextStyle(
                          color: stock['status'] == 'GAIN'
                              ? Colors.green
                              : stock['status'] == 'LOSE'
                              ? Colors.red
                              : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mini Graph
            SizedBox(
              height: 60,
              child: CustomPaint(
                painter: MiniGraphPainter(
                  priceHistory: priceHistory,
                  isPositive: isPositive,
                ),
                child: Container(),
              ),
            ),

            const SizedBox(height: 12),

            // Quick Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickStat('Open', 'TZS ${stock['OpeningPrice'] ?? 'N/A'}'),
                _buildQuickStat('High', 'TZS ${stock['MaxPrice'] ?? 'N/A'}'),
                _buildQuickStat('Low', 'TZS ${stock['MinPrice'] ?? 'N/A'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha((0.5 * 255).round()),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Custom painter for mini graph
class MiniGraphPainter extends CustomPainter {
  final List<double> priceHistory;
  final bool isPositive;

  MiniGraphPainter({required this.priceHistory, required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    if (priceHistory.isEmpty) return;

    final paint = Paint()
      ..color = isPositive ? const Color(0xFF4CAF50) : Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (isPositive ? const Color(0xFF4CAF50) : Colors.red).withAlpha((0.3 * 255).round()),
          (isPositive ? const Color(0xFF4CAF50) : Colors.red).withAlpha((0.0 * 255).round()),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final minPrice = priceHistory.reduce((a, b) => a < b ? a : b);
    final maxPrice = priceHistory.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < priceHistory.length; i++) {
      final x = (i / (priceHistory.length - 1)) * size.width;
      final normalizedPrice = (priceHistory[i] - minPrice) / priceRange;
      final y = size.height - (normalizedPrice * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}