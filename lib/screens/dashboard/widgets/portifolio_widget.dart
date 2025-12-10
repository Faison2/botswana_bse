import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PortfolioWidget extends StatelessWidget {
  final List<FlSpot> bolataData;
  final List<FlSpot> minergyData;

  const PortfolioWidget({
    Key? key,
    required this.bolataData,
    required this.minergyData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildPortfolioCard(
              'Bolata Energy Ltd',
              'BOTALA',
              'BWP12,300.00',
              '+4.5%',
              true,
              const Color(0xFF2D4A2B),
              'B',
              bolataData,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildPortfolioCard(
              'Minergy Limited',
              'MINERGY',
              'BWP4,500.00',
              '-2.3%',
              false,
              const Color(0xFF4A2B2B),
              'M',
              minergyData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(
      String name,
      String ticker,
      String amount,
      String change,
      bool isPositive,
      Color bgColor,
      String icon,
      List<FlSpot> chartData,
      ) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ticker,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  icon,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                    color: isPositive ? const Color(0xFF4CAF50) : Colors.red,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isPositive ? const Color(0xFF4CAF50) : Colors.red)
                              .withOpacity(0.3),
                          (isPositive ? const Color(0xFF4CAF50) : Colors.red)
                              .withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? const Color(0xFF4CAF50) : Colors.red,
                    size: 12,
                  ),
                  Text(
                    change,
                    style: TextStyle(
                      color: isPositive ? const Color(0xFF4CAF50) : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}