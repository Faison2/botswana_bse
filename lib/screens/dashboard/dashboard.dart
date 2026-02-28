import 'package:bse/contants/constants.dart';
import 'package:bse/screens/buy_sell/buy_sell.dart';
import 'package:bse/screens/dashboard/widgets/portifolio_widget.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../market_watch/market_watch.dart';
import '../portifolio/portifolio.dart';
import '../drawer/drawer.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import '../transactions /transactions.dart';
import 'widgets/market_watch_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isBalanceVisible = true;

  // ── Chart state (live tickers) ──
  List<List<FlSpot>> _holdingChartData = [];
  Timer? _timer;
  double _currentX = 0;

  // ── User / profile ──
  String _fullName = 'Loading...';
  String _email = 'Loading...';
  String _username = '';
  String _token = '';
  String _cdsNumber = '';
  bool _isLoadingProfile = true;

  // ── Portfolio (from API) ──
  List<Map<String, dynamic>> _portfolioHoldings = [];
  double _totalPortfolioValue = 0.0;
  double _totalShares = 0.0;
  bool _isLoadingPortfolio = false;
  String? _portfolioError;

  // ── Navigation debounce ──
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

    _startLiveDataUpdate();
    _loadUserData();
  }

  // ─────────────────────────────────────────────────────────────
  //  Navigation
  // ─────────────────────────────────────────────────────────────

  Future<void> _navigateWithDebounce(Widget destination) async {
    if (_isNavigating) return;
    final now = DateTime.now();
    if (_lastNavigationTime != null &&
        now.difference(_lastNavigationTime!).inMilliseconds <
            _navigationDebounceMs) {
      return;
    }
    setState(() => _isNavigating = true);
    _lastNavigationTime = now;
    try {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => destination));
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Load user + portfolio
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      setState(() {
        _fullName = prefs.getString('fullName') ?? 'User';
        _email = prefs.getString('email') ?? 'No email';
        _username = prefs.getString('username') ?? '';
        _token = token;
        _cdsNumber = prefs.getString('cdsNumber') ?? '';
      });
      if (token.isNotEmpty) {
        await _fetchProfileData(token);
      }
      // Load portfolio after we have the CDS number
      await _loadPortfolioFromApi();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _fetchProfileData(String token) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/Authentication/GetProfile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Token': token}),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseCode'] == 200) {
          setState(() {
            _fullName = data['fullName'] ?? 'User';
            _email = data['email'] ?? 'No email';
            _username = data['username'] ?? '';
            _cdsNumber = data['cdsNumber'] ?? '';
            _isLoadingProfile = false;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fullName', _fullName);
          await prefs.setString('email', _email);
          await prefs.setString('cdsNumber', _cdsNumber);
        } else {
          setState(() => _isLoadingProfile = false);
        }
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Portfolio API
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadPortfolioFromApi() async {
    if (_cdsNumber.isEmpty) return;

    setState(() {
      _isLoadingPortfolio = true;
      _portfolioError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .post(
        Uri.parse(
            'https://zamagm.escrowagm.com/MainAPI/Home/GetMyPortfolio'),
        headers: headers,
        body: jsonEncode({'CDSNumber': _cdsNumber}),
      )
          .timeout(const Duration(seconds: 30));

      debugPrint('=== Dashboard Portfolio API ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> raw = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List
            ? decoded['data']
            : [decoded]);

        double totalValue = 0.0;
        double totalShares = 0.0;

        final holdings = raw
            .where((item) => item is Map)
            .map((item) {
          final value =
              double.tryParse(item['CurrentValue']?.toString() ?? '0') ??
                  0.0;
          final shares =
              double.tryParse(item['Total_Shares']?.toString() ?? '0') ??
                  0.0;
          totalValue += value;
          totalShares += shares;
          return <String, dynamic>{
            'company': item['Company']?.toString() ?? '-',
            'cdsNumber': item['CDS_Number']?.toString() ?? '-',
            'totalShares': shares,
            'currentValue': value,
          };
        })
            .toList();

        // Build initial chart data for each holding
        final charts = List.generate(
          holdings.length,
              (_) => List.generate(
            20,
                (i) => FlSpot(
              i.toDouble(),
              50 + math.Random().nextDouble() * 20,
            ),
          ),
        );

        // Cache totals to SharedPreferences so they survive a restart
        final prefs2 = await SharedPreferences.getInstance();
        await prefs2.setDouble('cachedPortfolioValue', totalValue);
        await prefs2.setDouble('cachedTotalShares', totalShares);
        // Save full holdings list so PortfolioScreen can read the same data
        await prefs2.setString(
          'cachedPortfolioHoldings',
          jsonEncode(holdings),
        );

        setState(() {
          _portfolioHoldings = holdings;
          _totalPortfolioValue = totalValue;
          _totalShares = totalShares;
          _holdingChartData = charts;
          _currentX = 20;
          _isLoadingPortfolio = false;
        });
      } else {
        // Fall back to cached values if available
        final prefs2 = await SharedPreferences.getInstance();
        setState(() {
          _totalPortfolioValue =
              prefs2.getDouble('cachedPortfolioValue') ?? 0.0;
          _totalShares = prefs2.getDouble('cachedTotalShares') ?? 0.0;
          _portfolioError =
          'Could not refresh (${response.statusCode})';
          _isLoadingPortfolio = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard portfolio error: $e');
      final prefs2 = await SharedPreferences.getInstance();
      setState(() {
        _totalPortfolioValue =
            prefs2.getDouble('cachedPortfolioValue') ?? 0.0;
        _totalShares = prefs2.getDouble('cachedTotalShares') ?? 0.0;
        _isLoadingPortfolio = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Live chart updates
  // ─────────────────────────────────────────────────────────────

  void _startLiveDataUpdate() {
    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted || _holdingChartData.isEmpty) return;
      setState(() {
        for (int hi = 0; hi < _holdingChartData.length; hi++) {
          final data = _holdingChartData[hi];
          final isPositive = hi % 2 == 0;
          data.add(FlSpot(
            _currentX,
            50 +
                (isPositive ? 1 : -1) *
                    (math.Random().nextDouble() * 20 + _currentX * 0.15),
          ));
          if (data.length > 20) {
            data.removeAt(0);
            for (int i = 0; i < data.length; i++) {
              data[i] = FlSpot(i.toDouble(), data[i].y);
            }
          }
        }
        if (_holdingChartData.isNotEmpty &&
            _holdingChartData[0].length >= 20) {
          _currentX = 20;
        } else {
          _currentX++;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────

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
              _buildSectionHeader(
                'My Portfolio',
                _isLoadingPortfolio ? '' : 'View Details',
                isDark,
                null,
              ),
              const SizedBox(height: 15),
              // ── Holdings cards (horizontal scroll) ──
              if (_isLoadingPortfolio)
                const SizedBox(
                  height: 195,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_portfolioHoldings.isEmpty)
                const SizedBox(
                  height: 195,
                  child: Center(
                    child: Text('No holdings found',
                        style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                PortfolioWidget(
                  holdings: _portfolioHoldings,
                  chartDataList: _holdingChartData,
                ),
              const SizedBox(height: 30),
              _buildSectionHeader(
                'Market Watch',
                'See All',
                isDark,
                    () => _navigateWithDebounce(const MarketWatchScreen()),
              ),
              const SizedBox(height: 15),
              MarketWatchWidget(isDark: isDark, showLimited: true),
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
            onMenuItemTapped: (int index) =>
                setState(() => _selectedIndex = index),
            onMarketWatchTapped: () =>
                _navigateWithDebounce(const MarketWatchScreen()),
            onBuySellTapped: () =>
                _navigateWithDebounce(const TradingPage()),
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
          floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Icon(Icons.menu,
                color: isDark ? Colors.white : Colors.black87, size: 28),
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
                      fontSize: 12),
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
                child: Icon(Icons.notifications_outlined,
                    color: isDark ? Colors.white : Colors.black87, size: 24),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Portfolio balance card (real data)
  // ─────────────────────────────────────────────────────────────

  Widget _buildPortfolioCard(bool isDark) {
    final formattedTotal = _formatAmount(_totalPortfolioValue);
    final formattedShares = _formatAmount(_totalShares);
    final holdingsCount = _portfolioHoldings.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B6914), Color(0xFF6B5010)],
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
          // ── Title row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Portfolio Balance',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isBalanceVisible = !_isBalanceVisible),
                    child: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _loadPortfolioFromApi,
                    child: _isLoadingPortfolio
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.refresh,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ── Balance ──
          _isLoadingPortfolio
              ? const Text(
            '...',
            style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w300),
          )
              : Text(
            _isBalanceVisible ? formattedTotal : '••••••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 12),

          // ── Holdings count ──
          Row(
            children: [
              const Icon(Icons.pie_chart_outline,
                  color: Color(0xFF4CAF50), size: 14),
              const SizedBox(width: 4),
              Text(
                '$holdingsCount holding${holdingsCount == 1 ? '' : 's'}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Bottom row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CDS: ${_cdsNumber.isNotEmpty ? _cdsNumber : '—'}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 12),
              ),
              Text(
                'Total Shares: ${_isBalanceVisible ? formattedShares : '••••'}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Section header
  // ─────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
      String title,
      String action,
      bool isDark,
      VoidCallback? onActionTap,
      ) {
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
          if (action.isNotEmpty)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                action,
                style: TextStyle(
                  color: isDark ? Colors.amber : const Color(0xFFB8860B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Bottom nav + FAB
  // ─────────────────────────────────────────────────────────────

  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius:
        const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5)),
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
        if (index != 2) setState(() => _selectedIndex = index);
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
          colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.amber.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 5)),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () => _navigateWithDebounce(const MarketWatchScreen()),
        child: const Icon(Icons.trending_up, size: 30, color: Colors.white),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'),
          (m) => '${m[1]},',
    );
  }
}