import 'package:bse/contants/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../../buy_sell/buy_sell.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'No authentication token found';
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/Home/getMarketData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        List<Map<String, dynamic>> stocks = [];

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
    String name = item['Company']?.toString() ?? 'Unknown';
    String ticker = item['Symbol']?.toString() ?? 'N/A';
    String code = item['Code']?.toString() ?? '';
    String logoUrl = item['LogoUrl']?.toString() ?? '';

    String closingPrice = item['ClosingPrice']?.toString() ?? '0';
    String openingPrice = item['OpeningPrice']?.toString() ?? '0';
    String maxPrice = item['MaxPrice']?.toString() ?? '0';
    String minPrice = item['MinPrice']?.toString() ?? '0';

    String price = 'BWP $closingPrice';
    String bestBid = 'BWP $openingPrice';
    String bestAsk = 'bwp $maxPrice';

    String openInterest = item['Openinterest']?.toString() ?? '0';
    String supply = _formatVolume(openInterest);
    String demand = '-';

    String status = item['status']?.toString() ?? '';

    final closingValue = double.tryParse(closingPrice) ?? 0.0;
    final openingValue = double.tryParse(openingPrice) ?? 0.0;

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
      'logoUrl': logoUrl,
      'status': status,
      'code': code,
      // Add raw numeric values for trading page
      'closingPriceValue': closingValue,
      'openingPriceValue': openingValue,
      'maxPriceValue': double.tryParse(maxPrice) ?? 0.0,
      'minPriceValue': double.tryParse(minPrice) ?? 0.0,
      'volumeValue': double.tryParse(openInterest) ?? 0.0,
      // ✅ Sparkline data (same generator used on Market Watch screen)
      'priceHistory': _generateRealisticPriceHistory(closingValue, openingValue),
    };
  }

  // ✅ Same realistic price-history generator used in the full Market Watch screen,
  // so the sparkline trend matches what users see when they tap into a stock.
  List<double> _generateRealisticPriceHistory(double closePrice, double openPrice) {
    final history = <double>[];
    final random = math.Random();

    final base = closePrice > 0 ? closePrice : (openPrice > 0 ? openPrice : 1.0);
    double currentPrice = base * (0.9 + random.nextDouble() * 0.2);

    const points = 20;
    for (int i = 0; i < points; i++) {
      final trend = (base - currentPrice) / (points - i);
      final volatility = base * 0.02;
      final change = trend + (random.nextDouble() - 0.5) * volatility;

      currentPrice += change;
      history.add(currentPrice);
    }

    return history;
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

    final displayStocks = widget.showLimited
        ? _stocks.take(4).toList()
        : _stocks;

    return Column(
      children: [
        for (int i = 0; i < displayStocks.length; i++) ...[
          _buildStockCard(
            displayStocks[i],
            widget.isDark,
          ),
          if (i < displayStocks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildStockLogo(Map<String, dynamic> stockData) {
    final String logoUrl = stockData['logoUrl']?.toString() ?? '';

    return Container(
      width: 50,
      height: 50,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: stockData['color'] as Color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: logoUrl.isNotEmpty
          ? Image.network(
        logoUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Icon(
          stockData['icon'] as IconData,
          color: Colors.white,
          size: 28,
        ),
      )
          : Icon(
        stockData['icon'] as IconData,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildStockCard(
      Map<String, dynamic> stockData,
      bool isDark,
      ) {
    final priceHistory = stockData['priceHistory'] as List<double>? ?? const <double>[];
    final status = stockData['status']?.toString().toUpperCase() ?? '';

    return GestureDetector(
      onTap: () {
        // Navigate to trading page with stock data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TradingPage(
              prefilledStockData: stockData,
              allStocks: _stocks,
            ),
          ),
        );
      },
      child: Container(
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
            // Company Logo (from LogoUrl, falls back to generated icon)
            _buildStockLogo(stockData),
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
                              stockData['name']!,
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
                              stockData['ticker']!,
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
                        stockData['price']!,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // ✅ Sparkline graph (same painter as the full Market Watch screen)
                  if (priceHistory.length > 1) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: CustomPaint(
                        painter: MiniGraphPainter(
                          priceHistory: priceHistory,
                          status: status,
                        ),
                        child: Container(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildInfoColumn('Open:', stockData['bestBid']!, isDark),
                      const SizedBox(width: 12),
                      _buildInfoColumn('High:', stockData['bestAsk']!, isDark),
                      const SizedBox(width: 12),
                      _buildInfoColumn('Volume:', stockData['supply']!, isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

// ✅ Same mini-graph painter used on the Market Watch screen, ported here so the
// dashboard cards and the full screen render identical sparklines.
class MiniGraphPainter extends CustomPainter {
  final List<double> priceHistory;
  final String status;

  MiniGraphPainter({required this.priceHistory, required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    if (priceHistory.isEmpty) return;

    Color graphColor;
    if (status == 'GAIN') {
      graphColor = const Color(0xFF26A69A);
    } else if (status == 'LOSE') {
      graphColor = const Color(0xFFEF5350);
    } else {
      graphColor = Colors.grey;
    }

    final paint = Paint()
      ..color = graphColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          graphColor.withOpacity(0.35),
          graphColor.withOpacity(0.08),
          graphColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final minPrice = priceHistory.reduce((a, b) => a < b ? a : b);
    final maxPrice = priceHistory.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < priceHistory.length; i++) {
      final x = (i / (priceHistory.length - 1)) * size.width;
      final normalizedPrice = (priceHistory[i] - minPrice) / priceRange;
      final y = size.height - (normalizedPrice * size.height * 0.9) - (size.height * 0.05);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];

        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 3, p0.dy);
        final controlPoint2 = Offset(p0.dx + 2 * (p1.dx - p0.dx) / 3, p1.dy);

        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p1.dx, p1.dy,
        );

        fillPath.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p1.dx, p1.dy,
        );
      }

      fillPath.lineTo(size.width, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}