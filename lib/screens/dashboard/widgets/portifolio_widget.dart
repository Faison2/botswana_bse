import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class PortfolioWidget extends StatelessWidget {
  /// Real holdings from the GetMyPortfolio API.
  /// Each map must contain: company, totalShares, currentValue
  final List<Map<String, dynamic>> holdings;

  /// Fallback chart data per holding index (generated in Dashboard).
  /// If fewer entries than holdings, random data is used.
  final List<List<FlSpot>> chartDataList;

  const PortfolioWidget({
    Key? key,
    required this.holdings,
    required this.chartDataList,
  }) : super(key: key);

  // ── colour palette for cards ──
  static const _cardColors = [
    Color(0xFF2D4A2B), // green-dark
    Color(0xFF4A2B2B), // red-dark
    Color(0xFF2B3A4A), // blue-dark
    Color(0xFF3A2B4A), // purple-dark
    Color(0xFF4A3B2B), // orange-dark
    Color(0xFF2B4A44), // teal-dark
  ];

  static const _lineColors = [
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFF00BCD4),
  ];

  @override
  Widget build(BuildContext context) {
    if (holdings.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No holdings', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return SizedBox(
      height: 195,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: holdings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final h = holdings[index];
          final company = h['company'] as String? ?? '-';
          final shares = h['totalShares'] as double? ?? 0.0;
          final value = h['currentValue'] as double? ?? 0.0;

          // Chart data – use provided list or fallback to flat line
          final chartData = (index < chartDataList.length && chartDataList[index].isNotEmpty)
              ? chartDataList[index]
              : List.generate(
            20,
                (i) => FlSpot(i.toDouble(), 50 + math.Random().nextDouble() * 10),
          );

          final cardColor = _cardColors[index % _cardColors.length];
          final lineColor = _lineColors[index % _lineColors.length];
          final isPositive = lineColor == const Color(0xFF4CAF50) ||
              lineColor == const Color(0xFF00BCD4) ||
              lineColor == const Color(0xFF2196F3);

          final initial =
          company.isNotEmpty ? company[0].toUpperCase() : '?';
          final formattedValue = _formatAmount(value);
          final formattedShares = _formatAmount(shares);

          return _PortfolioCard(
            company: company,
            initial: initial,
            formattedValue: formattedValue,
            formattedShares: formattedShares,
            cardColor: cardColor,
            lineColor: lineColor,
            isPositive: isPositive,
            chartData: chartData,
          );
        },
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'),
          (m) => '${m[1]},',
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Individual card – extracted for clarity
// ─────────────────────────────────────────────────────────────

class _PortfolioCard extends StatelessWidget {
  final String company;
  final String initial;
  final String formattedValue;
  final String formattedShares;
  final Color cardColor;
  final Color lineColor;
  final bool isPositive;
  final List<FlSpot> chartData;

  const _PortfolioCard({
    required this.company,
    required this.initial,
    required this.formattedValue,
    required this.formattedShares,
    required this.cardColor,
    required this.lineColor,
    required this.isPositive,
    required this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  company,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Mini chart ──
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 19,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withOpacity(0.35),
                          lineColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Value ──
          Text(
            formattedValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          // ── Shares row ──
          Row(
            children: [
              Icon(
                Icons.layers_outlined,
                color: Colors.white.withOpacity(0.6),
                size: 11,
              ),
              const SizedBox(width: 3),
              Text(
                '$formattedShares shares',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}