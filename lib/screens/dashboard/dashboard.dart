import 'package:bse/screens/buy_sell/buy_sell.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../market_watch/market_watch.dart';
import '../portifolio/portifolio.dart';
import '../transactions /transactions.dart';

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

  // 1. DEFINE THE LIST OF WIDGETS/SCREENS FOR THE BOTTOM NAVIGATION
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();

    // Initialize the list of screens
    // The screen at index 0 is your initial dashboard content,
    // which is the main scrollable view we'll keep.
    _widgetOptions = <Widget>[
      // Index 0: Dashboard (The existing scrollable content)
      _buildDashboardContent(),
      // Index 1: Charts/Analysis
      const TradingPage(),
      // Index 2 is reserved for the FAB (MarketWatch)
      Container(),
      // Index 3: Transactions/Money
      const TransactionsScreen(),
      // Index 4: Portfolio
      const PortfolioScreen(),
    ];

    _initializeChartData();
    _startLiveDataUpdate();
  }
// ... (The rest of your existing methods: _initializeChartData, _startLiveDataUpdate, dispose)
// ... (Your chart data methods remain the same)

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
      if (!mounted) return; // Safety check
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


  // Extracted the main dashboard content into a new method
  Widget _buildDashboardContent() {
    return Column(
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
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      // 2. USE IndexedStack OR _widgetOptions[_selectedIndex] IN THE BODY
      body: SafeArea(
        // Use IndexedStack to preserve the state of the screens
        child: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(),

      // Floating Action Button
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
// ... (The rest of your existing building methods)
// ... (All your existing _buildHeader, _buildPortfolioCard, etc. methods remain the same)

// The building methods need to be included in the final code.
// I'll skip re-pasting them here for brevity, assuming you'll keep them in your file.

  Widget _buildHeader() {
    // ... (Your existing _buildHeader code)
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
    // ... (Your existing _buildPortfolioCard code)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
            _isBalanceVisible ? 'BWP 120,300.50' : '••••••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          // Percentage Change
          Row(
            children: [
              const Icon(
                Icons.arrow_upward,
                color: Color(0xFF4CAF50),
                size: 14,
              ),
              const SizedBox(width: 4),
              const Text(
                '10.9%',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'in the past week',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Balance Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cleared Cash: BWP1,250.00',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
              Text(
                'Total Amount: BWP1,250.00',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    // ... (Your existing _buildSectionHeader code)
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
    // ... (Your existing _buildMyPortfolio code)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildPortfolioCard1(
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
            child: _buildPortfolioCard1(
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
    // ... (Your existing _buildPortfolioCard1 code)
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

  Widget _buildMarketWatch() {
    // ... (Your existing _buildMarketWatch code)
    return Column(
      children: [
        _buildStockCard(
          'Sechaba Brewery Holdings Ltd',
          'SECHAB',
          'BWP6.23',
          'BWP6.30',
          'BWP6.30',
          '2,000',
          '100',
          Icons.local_drink,
          const Color(0xFF3D2F1F),
        ),
        const SizedBox(height: 10),
        _buildStockCard(
          'First National Bank of Botswana Ltd',
          'FNBB',
          'BWP11.59',
          'BWP12.30',
          'BWP11.30',
          '2,000',
          '100',
          Icons.account_balance,
          const Color(0xFF2A3F2F),
        ),
        const SizedBox(height: 10),
        _buildStockCard(
          'BBS Limited',
          'BBS',
          'BWP19.69',
          'BWP19.30',
          'BWP19.30',
          '600',
          '800',
          Icons.business,
          const Color(0xFF2F3A4A),
        ),
        const SizedBox(height: 10),
        _buildStockCard(
          'PrimeTime Property Holdings Ltd',
          'PRIMET',
          'BWP29.39',
          'BWP29.66',
          'BWP29.88',
          '600',
          '900',
          Icons.home_work,
          const Color(0xFF4A2F2F),
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
      IconData iconData,
      Color iconBgColor,
      ) {
    // ... (Your existing _buildStockCard code)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Icon/Logo
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

          // Company Info
          // Expanded(
          //   child:
          // ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
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
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),

                    ],
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              Row(

                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Best Bid:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        bestBid,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Best Ask:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        bestAsk,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 2),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supply:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        supply,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 2),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demand:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        demand,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
          // Price
        ],
      ),
    );
  }


  Widget _buildBottomNavBar() {
    // ... (Your existing _buildBottomNavBar code)
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
            _buildNavItem(Icons.home_outlined, 0),          // Home / Dashboard
            _buildNavItem(Icons.bar_chart_outlined, 1),    // Charts / Analysis
            const SizedBox(width: 50),             // Space for FAB (Index 2)
            _buildNavItem(Icons.attach_money, 3),  // Transactions / Money
            _buildNavItem(Icons.shopping_bag_outlined, 4), // Portfolio
          ],
        ),
      ),
    );
  }

  // 3. UPDATED _buildNavItem to set index instead of pushing a new screen
  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        // Only change state if the new index is not the FAB placeholder (index 2)
        if (index != 2) {
          setState(() => _selectedIndex = index);
        }
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
    // ... (Your existing _buildFloatingActionButton code)
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
          // Keep this as a separate screen push, as it's a primary action
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MarketWatchScreen()),
          );
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