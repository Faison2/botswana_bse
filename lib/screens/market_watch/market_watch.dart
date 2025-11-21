import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class MarketWatchScreen extends StatefulWidget {
  const MarketWatchScreen({super.key});

  @override
  State<MarketWatchScreen> createState() => _MarketWatchScreenState();
}

class _MarketWatchScreenState extends State<MarketWatchScreen> {
 // final int _selectedIndex = 2; // Center button is selected
  Timer? _timer;

  // Market data with live price updates
  final List<Map<String, dynamic>> _marketData = [
    {
      'name': 'Sechaba Brewery Holdings Ltd',
      'ticker': 'SECHAB',
      'price': 6.23,
      'bestBid': 6.30,
      'bestAsk': 6.30,
      'supply': '2,000',
      'demand': '100',
      'icon': Icons.local_drink,
      'iconBg': const Color(0xFF3D2F1F),
      'priceHistory': <double>[],
    },
    {
      'name': 'First National Bank of Botswana Ltd',
      'ticker': 'FNBB',
      'price': 11.59,
      'bestBid': 12.30,
      'bestAsk': 11.30,
      'supply': '2,000',
      'demand': '100',
      'icon': Icons.account_balance,
      'iconBg': const Color(0xFF2A3F2F),
      'priceHistory': <double>[],
    },
    {
      'name': 'BBS Limited',
      'ticker': 'BBS',
      'price': 19.69,
      'bestBid': 19.30,
      'bestAsk': 19.30,
      'supply': '600',
      'demand': '800',
      'icon': Icons.business,
      'iconBg': const Color(0xFF2F3A4A),
      'priceHistory': <double>[],
    },
    {
      'name': 'PrimeTime Property Holdings Ltd',
      'ticker': 'PRIMET',
      'price': 29.39,
      'bestBid': 29.66,
      'bestAsk': 29.88,
      'supply': '600',
      'demand': '900',
      'icon': Icons.home_work,
      'iconBg': const Color(0xFF4A2F2F),
      'priceHistory': <double>[],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializePriceHistory();
    _startLivePriceUpdate();
  }

  void _initializePriceHistory() {
    for (var stock in _marketData) {
      final basePrice = stock['price'] as double;
      final history = <double>[];
      for (int i = 0; i < 30; i++) {
        history.add(basePrice + (math.Random().nextDouble() - 0.5) * 2);
      }
      stock['priceHistory'] = history;
    }
  }

  void _startLivePriceUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        for (var stock in _marketData) {
          final history = stock['priceHistory'] as List<double>;
          final currentPrice = stock['price'] as double;
          final newPrice =
              currentPrice + (math.Random().nextDouble() - 0.5) * 0.5;

          history.add(newPrice);
          if (history.length > 30) {
            history.removeAt(0);
          }

          stock['price'] = newPrice;
        }
      });
    });
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
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Market List
              Expanded(
                child: ListView.builder(
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
    final currentPrice = stock['price'] as double;
    final isPositive =
        priceHistory.isNotEmpty && priceHistory.last > priceHistory.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                child: Icon(stock['icon'], color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),

              // Company Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock['name'],
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
                      stock['ticker'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Text(
                'BWP${currentPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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

          // Stock Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Best Bid', 'BWP${stock['bestBid']}'),
              _buildDetailItem('Best Ask', 'BWP${stock['bestAsk']}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Market Supply', stock['supply']),
              _buildDetailItem('Demand', stock['demand']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
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
          (isPositive ? const Color(0xFF4CAF50) : Colors.red).withOpacity(0.3),
          (isPositive ? const Color(0xFF4CAF50) : Colors.red).withOpacity(0.0),
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