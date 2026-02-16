import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../theme_provider.dart';

class ComparisonAnalysisScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedStocks;

  const ComparisonAnalysisScreen({
    Key? key,
    required this.selectedStocks,
  }) : super(key: key);

  @override
  State<ComparisonAnalysisScreen> createState() => _ComparisonAnalysisScreenState();
}

class _ComparisonAnalysisScreenState extends State<ComparisonAnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF2C1810),
        Color(0xFF1A1A1A),
        Color(0xFF0D0D0D),
      ],
    )
        : const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF8E7),
        Color(0xFFF5F5F5),
        Color(0xFFFFFFFF),
      ],
    );

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.6) : Colors.black54;
    final accentColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);
    final cardBgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back,
                          color: textColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comparison Analysis',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.selectedStocks.length} Companies',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: subtextColor,
                  indicator: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Performance'),
                    Tab(text: 'Details'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(isDark, textColor, subtextColor, accentColor, cardBgColor),
                    _buildPerformanceTab(isDark, textColor, subtextColor, accentColor, cardBgColor),
                    _buildDetailsTab(isDark, textColor, subtextColor, cardBgColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
      bool isDark,
      Color textColor,
      Color subtextColor,
      Color accentColor,
      Color cardBgColor,
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price Comparison Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Comparison',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: CustomPaint(
                    painter: ComparisonChartPainter(
                      stocks: widget.selectedStocks,
                      isDark: isDark,
                    ),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Company Cards
          ...widget.selectedStocks.asMap().entries.map((entry) {
            final index = entry.key;
            final stock = entry.value;
            return _buildCompanyOverviewCard(
              stock,
              index,
              isDark,
              textColor,
              subtextColor,
              cardBgColor,
            );
          }).toList(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(
      bool isDark,
      Color textColor,
      Color subtextColor,
      Color accentColor,
      Color cardBgColor,
      ) {
    // Calculate performance metrics
    final performances = widget.selectedStocks.map((stock) {
      final closePrice = double.tryParse(stock['ClosingPrice']?.toString() ?? '0') ?? 0;
      final openPrice = double.tryParse(stock['OpeningPrice']?.toString() ?? '0') ?? 0;
      final priceChange = closePrice - openPrice;
      final priceChangePercent = openPrice != 0 ? (priceChange / openPrice) * 100 : 0;

      return {
        'stock': stock,
        'change': priceChangePercent,
      };
    }).toList();

    // Sort by performance
    performances.sort((a, b) => (b['change'] as double).compareTo(a['change'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Ranking
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Ranking',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...performances.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final data = entry.value;
                  final stock = data['stock'] as Map<String, dynamic>;
                  final change = data['change'] as double;
                  final isPositive = change >= 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A3A3A)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Rank
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: rank == 1
                                ? Colors.amber
                                : rank == 2
                                ? Colors.grey
                                : rank == 3
                                ? Colors.brown
                                : subtextColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                color: rank <= 3 ? Colors.white : textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Company Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stock['Company'] ?? 'N/A',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stock['Symbol'] ?? 'N/A',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Performance
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: isPositive ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${change.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: isPositive ? Colors.green : Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Gain/Loss Distribution
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gain/Loss Distribution',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: PerformanceBarChartPainter(
                      stocks: widget.selectedStocks,
                      isDark: isDark,
                    ),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(
      bool isDark,
      Color textColor,
      Color subtextColor,
      Color cardBgColor,
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: widget.selectedStocks.map((stock) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  stock['Company'] ?? 'N/A',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stock['Symbol'] ?? 'N/A',
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: subtextColor.withOpacity(0.3)),
                const SizedBox(height: 16),

                // Details
                _buildDetailRow('Opening Price', 'TZS ${stock['OpeningPrice'] ?? 'N/A'}', textColor, subtextColor),
                const SizedBox(height: 12),
                _buildDetailRow('Closing Price', 'TZS ${stock['ClosingPrice'] ?? 'N/A'}', textColor, subtextColor),
                const SizedBox(height: 12),
                _buildDetailRow('High', 'TZS ${stock['MaxPrice'] ?? 'N/A'}', textColor, subtextColor),
                const SizedBox(height: 12),
                _buildDetailRow('Low', 'TZS ${stock['MinPrice'] ?? 'N/A'}', textColor, subtextColor),
                const SizedBox(height: 12),
                _buildDetailRow('Settlement', 'TZS ${stock['SettlementPrice'] ?? 'N/A'}', textColor, subtextColor),
                const SizedBox(height: 12),
                _buildDetailRow('VWAP', 'TZS ${stock['VwapPrice'] ?? 'N/A'}', textColor, subtextColor),
                const SizedBox(height: 12),
                _buildDetailRow('Market Cap', stock['marketCap'] ?? 'N/A', textColor, subtextColor),
                const SizedBox(height: 12),
                _buildDetailRow('P/E Ratio', stock['peRatio']?.toStringAsFixed(2) ?? 'N/A', textColor, subtextColor),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompanyOverviewCard(
      Map<String, dynamic> stock,
      int index,
      bool isDark,
      Color textColor,
      Color subtextColor,
      Color cardBgColor,
      ) {
    final closePrice = double.tryParse(stock['ClosingPrice']?.toString() ?? '0') ?? 0;
    final openPrice = double.tryParse(stock['OpeningPrice']?.toString() ?? '0') ?? 0;
    final maxPrice = double.tryParse(stock['MaxPrice']?.toString() ?? '0') ?? 0;
    final minPrice = double.tryParse(stock['MinPrice']?.toString() ?? '0') ?? 0;
    final priceChange = closePrice - openPrice;
    final priceChangePercent = openPrice != 0 ? (priceChange / openPrice) * 100 : 0;
    final isPositive = priceChange >= 0;

    final companyColors = [
      const Color(0xFF26A69A),
      const Color(0xFF5C6BC0),
      const Color(0xFFFF7043),
      const Color(0xFF9C27B0),
      const Color(0xFFFFA726),
    ];
    final color = companyColors[index % companyColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stock['Company'] ?? 'N/A',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Price',
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TZS ${closePrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${priceChangePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat('Open', 'TZS ${openPrice.toStringAsFixed(2)}', textColor, subtextColor),
              _buildQuickStat('High', 'TZS ${maxPrice.toStringAsFixed(2)}', textColor, subtextColor),
              _buildQuickStat('Low', 'TZS ${minPrice.toStringAsFixed(2)}', textColor, subtextColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subtextColor,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, Color textColor, Color subtextColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: subtextColor,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Comparison Chart Painter
class ComparisonChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> stocks;
  final bool isDark;

  ComparisonChartPainter({
    required this.stocks,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stocks.isEmpty) return;

    final companyColors = [
      const Color(0xFF26A69A),
      const Color(0xFF5C6BC0),
      const Color(0xFFFF7043),
      const Color(0xFF9C27B0),
      const Color(0xFFFFA726),
    ];

    // Get all prices to find min/max
    final allPrices = <double>[];
    for (var stock in stocks) {
      final priceHistory = stock['priceHistory'] as List<double>?;
      if (priceHistory != null) {
        allPrices.addAll(priceHistory);
      }
    }

    if (allPrices.isEmpty) return;

    final minPrice = allPrices.reduce((a, b) => a < b ? a : b);
    final maxPrice = allPrices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    // Draw grid
    _drawGrid(canvas, size, isDark);

    // Draw each company's line
    for (int i = 0; i < stocks.length; i++) {
      final stock = stocks[i];
      final priceHistory = stock['priceHistory'] as List<double>?;
      if (priceHistory == null || priceHistory.isEmpty) continue;

      final color = companyColors[i % companyColors.length];

      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      final points = <Offset>[];

      for (int j = 0; j < priceHistory.length; j++) {
        final x = (j / (priceHistory.length - 1)) * size.width;
        final normalizedPrice = (priceHistory[j] - minPrice) / priceRange;
        final y = size.height - (normalizedPrice * size.height * 0.9) - (size.height * 0.05);
        points.add(Offset(x, y));
      }

      if (points.isNotEmpty) {
        path.moveTo(points[0].dx, points[0].dy);

        for (int j = 0; j < points.length - 1; j++) {
          final p0 = points[j];
          final p1 = points[j + 1];

          final controlPoint1 = Offset(
            p0.dx + (p1.dx - p0.dx) / 3,
            p0.dy,
          );
          final controlPoint2 = Offset(
            p0.dx + 2 * (p1.dx - p0.dx) / 3,
            p1.dy,
          );

          path.cubicTo(
            controlPoint1.dx, controlPoint1.dy,
            controlPoint2.dx, controlPoint2.dy,
            p1.dx, p1.dy,
          );
        }

        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size, bool isDark) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Performance Bar Chart Painter
class PerformanceBarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> stocks;
  final bool isDark;

  PerformanceBarChartPainter({
    required this.stocks,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stocks.isEmpty) return;

    final barWidth = (size.width / stocks.length) * 0.7;
    final spacing = size.width / stocks.length;

    // Calculate changes
    final changes = stocks.map((stock) {
      final closePrice = double.tryParse(stock['ClosingPrice']?.toString() ?? '0') ?? 0;
      final openPrice = double.tryParse(stock['OpeningPrice']?.toString() ?? '0') ?? 0;
      final priceChange = closePrice - openPrice;
      final priceChangePercent = openPrice != 0 ? (priceChange / openPrice) * 100 : 0;
      return priceChangePercent;
    }).toList();

    final maxChange = changes.map((c) => c.abs()).reduce((a, b) => a > b ? a : b);
    if (maxChange == 0) return;

    // Draw zero line
    final zeroY = size.height / 2;
    final zeroPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);

    // Draw bars
    for (int i = 0; i < stocks.length; i++) {
      final change = changes[i];
      final x = i * spacing + spacing / 2;
      final isPositive = change >= 0;

      final normalizedHeight = (change.abs() / maxChange) * (size.height / 2);
      final barTop = isPositive ? zeroY - normalizedHeight : zeroY;
      final barBottom = isPositive ? zeroY : zeroY + normalizedHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - barWidth / 2,
          barTop,
          x + barWidth / 2,
          barBottom,
        ),
        const Radius.circular(4),
      );

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isPositive
            ? [Colors.green.withOpacity(0.8), Colors.green.withOpacity(0.5)]
            : [Colors.red.withOpacity(0.5), Colors.red.withOpacity(0.8)],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect.outerRect);

      canvas.drawRRect(rect, paint);

      // Draw percentage label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${change.toStringAsFixed(1)}%',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textY = isPositive ? barTop - textPainter.height - 4 : barBottom + 4;
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, textY),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}