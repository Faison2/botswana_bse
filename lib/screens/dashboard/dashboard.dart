import 'package:bse/screens/buy_sell/buy_sell.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../market_watch/market_watch.dart';
import '../portifolio/portifolio.dart';
import '../transactions /transactions.dart';
import '../drawer/drawer.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isBalanceVisible = true;

  List<FlSpot> bolataData = [];
  List<FlSpot> minergyData = [];
  Timer? _timer;
  double currentX = 0;

  String _fullName = 'Loading...';
  String _email = 'Loading...';
  String _username = '';
  String _token = '';
  String _cdsNumber = '';
  bool _isLoadingProfile = true;

  bool _isNavigating = false;
  DateTime? _lastNavigationTime;
  static const _navigationDebounceMs = 500;

  late final List<Widget> _widgetOptions;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    _widgetOptions = <Widget>[
      _buildDashboardContent(),
      const TradingPage(),
      Container(),
      const TransactionsScreen(),
      const PortfolioScreen(),
    ];

    _initializeChartData();
    _startLiveDataUpdate();
    _loadUserData();
  }

  Future<void> _navigateWithDebounce(Widget destination) async {
    if (_isNavigating) {
      debugPrint('Navigation blocked: Already navigating');
      return;
    }

    final now = DateTime.now();
    if (_lastNavigationTime != null) {
      final difference = now.difference(_lastNavigationTime!).inMilliseconds;
      if (difference < _navigationDebounceMs) {
        debugPrint('Navigation blocked: Too soon (${difference}ms)');
        return;
      }
    }

    setState(() => _isNavigating = true);
    _lastNavigationTime = now;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      setState(() {
        _fullName = prefs.getString('fullName') ?? 'User';
        _email = prefs.getString('email') ?? 'No email';
        _username = prefs.getString('username') ?? '';
        _token = token;
      });

      if (token.isNotEmpty) {
        await _fetchProfileData(token);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _fetchProfileData(String token) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.3.201/MainAPI/Authentication/GetProfile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Token': token}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['responseCode'] == 200) {
          setState(() {
            _fullName = responseData['fullName'] ?? 'User';
            _email = responseData['email'] ?? 'No email';
            _username = responseData['username'] ?? '';
            _cdsNumber = responseData['cdsNumber'] ?? '';
            _isLoadingProfile = false;
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fullName', _fullName);
          await prefs.setString('email', _email);
          await prefs.setString('cdsNumber', _cdsNumber);
        } else {
          print('Profile fetch failed: ${responseData['responseMessage']}');
          setState(() => _isLoadingProfile = false);
        }
      } else {
        print('Profile fetch error: ${response.statusCode}');
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      print('Error fetching profile: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  void _initializeChartData() {
    for (int i = 0; i < 20; i++) {
      bolataData.add(FlSpot(i.toDouble(), 50 + math.Random().nextDouble() * 20));
      minergyData.add(FlSpot(i.toDouble(), 50 - math.Random().nextDouble() * 20));
    }
    currentX = 20;
  }

  void _startLiveDataUpdate() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      setState(() {
        bolataData.add(FlSpot(currentX, 50 + math.Random().nextDouble() * 20 + (currentX * 0.2)));
        minergyData.add(FlSpot(currentX, 50 - math.Random().nextDouble() * 20 - (currentX * 0.1)));

        if (bolataData.length > 20) {
          bolataData.removeAt(0);
          minergyData.removeAt(0);

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

  Widget _buildDashboardContent() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildPortfolioCard(isDark),
              const SizedBox(height: 30),
              _buildSectionHeader('My Portfolio', 'View Details', isDark),
              const SizedBox(height: 15),
              _buildMyPortfolio(),
              const SizedBox(height: 30),
              _buildSectionHeader('Market Watch', 'Sell All', isDark),
              const SizedBox(height: 15),
              _buildMarketWatch(isDark),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        final bgGradient = isDark
            ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C1810),
            Color(0xFF1A1A1A),
            Color(0xFF0D0D0D),
          ],
        )
            : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8E7),
            Color(0xFFF5F5F5),
            Color(0xFFFFFFFF),
          ],
        );

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          drawer: AppDrawer(
            onMenuItemTapped: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            onMarketWatchTapped: () {
              _navigateWithDebounce(const MarketWatchScreen());
            },
            onBuySellTapped: () {
              _navigateWithDebounce(const TradingPage());
            },
          ),
          body: Container(
            decoration: BoxDecoration(gradient: bgGradient),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(isDark),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _widgetOptions,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavBar(isDark),
          floatingActionButton: _buildFloatingActionButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Icon(
              Icons.menu,
              color: isDark ? Colors.white : Colors.black87,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName.toUpperCase(),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _cdsNumber.isNotEmpty ? _cdsNumber : _email,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 24,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            const Color(0xFF8B6914),
            const Color(0xFF6B5010),
          ]
              : [
            const Color(0xFFFFD700),
            const Color(0xFFDAA520),
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
          Text(
            _isBalanceVisible ? 'BWP 12,300.50' : '••••••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cash Balance: BWP1,250.00',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
              Text(
                'Total Amount: BWP1,250.00',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            action,
            style: TextStyle(
              color: isDark ? Colors.amber : const Color(0xFFB8860B),
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

  Widget _buildMarketWatch(bool isDark) {
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
          isDark,
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
          isDark,
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
          isDark,
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
          isDark,
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
                    _buildInfoColumn('Best Bid:', bestBid, isDark),
                    const SizedBox(width: 12),
                    _buildInfoColumn('Best Ask:', bestAsk, isDark),
                    const SizedBox(width: 12),
                    _buildInfoColumn('Supply:', supply, isDark),
                    const SizedBox(width: 12),
                    _buildInfoColumn('Demand:', demand, isDark),
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

  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
            _buildNavItem(Icons.home_outlined, 0, isDark),
            _buildNavItem(Icons.bar_chart_outlined, 1, isDark),
            const SizedBox(width: 50),
            _buildNavItem(Icons.attach_money, 3, isDark),
            _buildNavItem(Icons.shopping_bag_outlined, 4, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index != 2) {
          setState(() => _selectedIndex = index);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: isSelected
              ? Colors.amber
              : (isDark ? Colors.white54 : Colors.black45),
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
          _navigateWithDebounce(const MarketWatchScreen());
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