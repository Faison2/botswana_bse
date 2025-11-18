import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isBalanceVisible = true;

  // Live data for charts
  List<FlSpot> bolataData = [];
  List<FlSpot> minergyData = [];
  Timer? _timer;
  double currentX = 0;

  @override
  void initState() {
    super.initState();
    _initializeChartData();
    _startLiveDataUpdate();
  }

  void _initializeChartData() {
    // Initialize with some data points
    for (int i = 0; i < 20; i++) {
      bolataData.add(FlSpot(i.toDouble(), 50 + math.Random().nextDouble() * 20));
      minergyData.add(FlSpot(i.toDouble(), 50 - math.Random().nextDouble() * 20));
    }
    currentX = 20;
  }

  void _startLiveDataUpdate() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        // Add new data point
        bolataData.add(FlSpot(currentX, 50 + math.Random().nextDouble() * 20 + (currentX * 0.2)));
        minergyData.add(FlSpot(currentX, 50 - math.Random().nextDouble() * 20 - (currentX * 0.1)));

        // Keep only last 20 points
        if (bolataData.length > 20) {
          bolataData.removeAt(0);
          minergyData.removeAt(0);

          // Shift x values
          for (int i = 0; i < bolataData.length; i++) {
            bolataData[i] = FlSpot(i.toDouble(), bolataData[i].y);
            minergyData[i] = FlSpot(i.toDouble(), minergyData[i].y);
          }
          currentX = 20;
        } else {
          currentX++;
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
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Portfolio Balance Card
                    _buildPortfolioCard(),

                    const SizedBox(height: 30),

                    // My Portfolio Section
                    _buildSectionHeader('My Portfolio', 'View Details'),
                    const SizedBox(height: 15),
                    _buildMyPortfolio(),

                    const SizedBox(height: 30),

                    // Market Watch Section
                    _buildSectionHeader('Market Watch', 'Sell All'),
                    const SizedBox(height: 15),
                    _buildMarketWatch(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(),

      // Floating Action Button
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.amber,
            child: Image.asset(
              'assets/avatar.png',
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.person, color: Colors.white, size: 30);
              },
            ),
          ),
          const SizedBox(width: 12),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Hi, Good Morning',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Victor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Notification Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B6914),
            const Color(0xFF6B5010),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Portfolio Balance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _isBalanceVisible = !_isBalanceVisible);
                    },
                    child: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Balance
          Text(
            _isBalanceVisible ? '\$120,300.50' : '••••••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Percentage Change
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1), // Adjust opacity as needed
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(8), // Add some padding
            child: Row(
              mainAxisSize: MainAxisSize.min, // Makes the container fit the content
              children: [
                const Icon(
                  Icons.arrow_upward,
                  color: Color(0xFF4CAF50),
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text(
                  '10.9%',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'in the past week',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Balance Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cleared Cash: \$1,250.00',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uncleared Cash\$1,250.00',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount: \$1,250.00',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cash Balance: \$1,250.00',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            action,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPortfolio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildPortfolioCard1(
              'Bolata Energy Ltd',
              'BOTALA',
              '\$12,300.00',
              '+4.5%',
              true,
              const Color(0xFF2D4A2B),
              'B',
              bolataData,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildPortfolioCard1(
              'Minergy Limited',
              'MINERGY',
              '\$4,500.00',
              '-2.3%',
              false,
              const Color(0xFF4A2B2B),
              'H',
              minergyData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard1(
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
      height: 170,
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
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live Chart
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
                          (isPositive ? const Color(0xFF4CAF50) : Colors.red).withOpacity(0.3),
                          (isPositive ? const Color(0xFF4CAF50) : Colors.red).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Amount and Change
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
                    size: 14,
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

  Widget _buildMarketWatch() {
    return Column(
      children: [
        _buildStockCard(
          'Access Bank Botswana Limited',
          'ACCESS',
          '\$6.23',
          '\$0.30',
          '\$6.30',
          '2,000',
          '100',
        ),
        const SizedBox(height: 10),
        _buildStockCard(
          'ABSA Bank of Botswana Limited',
          'ABSA',
          '\$11.59',
          '\$12.30',
          '\$11.30',
          '2,000',
          '100',
        ),
        const SizedBox(height: 10),
        _buildStockCard(
          'g',
          'BIHL',
          '\$19.69',
          '\$19.30',
          '\$19.30',
          '600',
          '800',
        ),
        const SizedBox(height: 10),
        _buildStockCard(
          'Chobe Holdings Limited',
          'CHOBE',
          '\$29.39',
          '\$29.66',
          '\$29.88',
          '600',
          '900',
        ),
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
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticker,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stock Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Best Bid: $bestBid  Best Ask: $bestAsk',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                'Market: $supply  Market: $demand',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.show_chart, 1),
            const SizedBox(width: 50), // Space for FAB
            _buildNavItem(Icons.attach_money, 3),
            _buildNavItem(Icons.shopping_bag_outlined, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: isSelected ? Colors.amber : Colors.white54,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFB300),
            Color(0xFFFF8F00),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          // TODO: Implement trade action
        },
        child: const Icon(
          Icons.trending_up,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Custom painter for mini chart
class MiniChartPainter extends CustomPainter {
  final bool isPositive;

  MiniChartPainter({required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isPositive ? const Color(0xFF4CAF50) : Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Generate curved line data
    final points = 20;
    for (int i = 0; i < points; i++) {
      final x = (size.width / points) * i;
      final baseY = size.height * 0.5;
      final amplitude = size.height * 0.3;

      double y;
      if (isPositive) {
        // Positive trend - ends higher
        y = baseY - (math.sin(i * 0.5) * amplitude * 0.5) - (i / points * amplitude);
      } else {
        // Negative trend - ends lower
        y = baseY - (math.sin(i * 0.5) * amplitude * 0.5) + (i / points * amplitude);
      }

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}