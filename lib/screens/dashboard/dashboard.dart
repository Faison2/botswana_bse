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
  String _fullName = '';
  String _email = '';
  String _cdsNumber = '';
  bool _isLoadingProfile = true;

  // ── Portfolio ──
  List<Map<String, dynamic>> _portfolioHoldings = [];
  double _totalPortfolioValue = 0.0;
  double _totalShares = 0.0;
  bool _isLoadingPortfolio = false;
  String? _portfolioError;

  // ── Navigation debounce ──
  bool _isNavigating = false;
  DateTime? _lastNavigationTime;
  static const _navigationDebounceMs = 500;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // SharedPreferences cache keys
  static const _kHoldingsKey    = 'cachedPortfolioHoldings';
  static const _kTotalValueKey  = 'cachedPortfolioValue';
  static const _kTotalSharesKey = 'cachedTotalShares';

  @override
  void initState() {
    super.initState();
    _startLiveDataUpdate();
    _bootstrap();
  }

  /// 1. Load cached data instantly
  /// 2. Fetch fresh profile (gets latest CDS number)
  /// 3. Fetch portfolio with that CDS
  Future<void> _bootstrap() async {
    await _loadCachedUserData();
    await _fetchProfileData();
    await _loadPortfolioFromApi();
  }

  // ─────────────────────────────────────────────────────────────
  //  Load cached data (instant, no network)
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fullName  = prefs.getString('fullName')  ?? '';
      _email     = prefs.getString('email')     ?? '';
      _cdsNumber = prefs.getString('cdsNumber') ?? '';
      _totalPortfolioValue = prefs.getDouble(_kTotalValueKey)  ?? 0.0;
      _totalShares         = prefs.getDouble(_kTotalSharesKey) ?? 0.0;
    });

    final raw = prefs.getString(_kHoldingsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        final holdings = decoded.whereType<Map>().map((item) => <String, dynamic>{
          'company':      item['company']?.toString()  ?? '-',
          'cdsNumber':    item['cdsNumber']?.toString() ?? '-',
          'totalShares':  (item['totalShares']  as num?)?.toDouble() ?? 0.0,
          'currentValue': (item['currentValue'] as num?)?.toDouble() ?? 0.0,
        }).toList();

        if (!mounted) return;
        setState(() {
          _portfolioHoldings = holdings;
          _holdingChartData  = _buildInitialCharts(holdings.length);
        });
      } catch (e) {
        debugPrint('Cache restore error: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Fetch profile
  // ─────────────────────────────────────────────────────────────

  Future<void> _fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        if (mounted) setState(() => _isLoadingProfile = false);
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/Authentication/GetProfile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Token': token}),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseCode'] == 200) {
          final fullName  = (data['fullName']  as String?) ?? _fullName;
          final email     = (data['email']     as String?) ?? _email;
          final cdsNumber = (data['cdsNumber'] as String?) ?? _cdsNumber;

          setState(() {
            _fullName        = fullName;
            _email           = email;
            _cdsNumber       = cdsNumber;
            _isLoadingProfile = false;
          });

          await prefs.setString('fullName',  fullName);
          await prefs.setString('email',     email);
          await prefs.setString('cdsNumber', cdsNumber);
        } else {
          setState(() => _isLoadingProfile = false);
        }
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('Profile error: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Portfolio API – GetMyPortfolio
  //  Response: [ { "Company":"BIHL", "CDS_Number":"...",
  //               "Total_Shares":"300.50", "CurrentValue":"6917.51" } ]
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadPortfolioFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final cds   = _cdsNumber.isNotEmpty
        ? _cdsNumber
        : (prefs.getString('cdsNumber') ?? '');

    if (cds.isEmpty) {
      debugPrint('Portfolio: skipping – no CDS number');
      return;
    }

    final token = prefs.getString('token') ?? '';

    if (!mounted) return;
    setState(() {
      _isLoadingPortfolio = true;
      _portfolioError     = null;
    });

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept':       'application/json',
      };
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      debugPrint('▶ GetMyPortfolio  CDSNumber=$cds');

      final response = await http.post(
        Uri.parse('https://zamagm.escrowagm.com/MainAPI/Home/GetMyPortfolio'),
        headers: headers,
        body:    jsonEncode({'CDSNumber': cds}),
      ).timeout(const Duration(seconds: 30));

      debugPrint('◀ status: ${response.statusCode}');
      debugPrint('◀ body:   ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        // Handle both plain array and any envelope wrapper
        List<dynamic> raw;
        if (decoded is List) {
          raw = decoded;
        } else if (decoded is Map) {
          raw = decoded.values.firstWhere(
                (v) => v is List,
            orElse: () => [decoded],
          ) as List<dynamic>;
        } else {
          raw = [];
        }

        double totalValue  = 0.0;
        double totalShares = 0.0;

        final holdings = raw.whereType<Map>().map((item) {
          final value  = double.tryParse(item['CurrentValue']?.toString()  ?? '0') ?? 0.0;
          final shares = double.tryParse(item['Total_Shares']?.toString()  ?? '0') ?? 0.0;
          totalValue  += value;
          totalShares += shares;
          return <String, dynamic>{
            'company':      item['Company']?.toString()    ?? '-',
            'cdsNumber':    item['CDS_Number']?.toString() ?? cds,
            'totalShares':  shares,
            'currentValue': value,
          };
        }).toList();

        // ── Persist to SharedPreferences (shared with PortfolioScreen) ──
        await prefs.setDouble(_kTotalValueKey,  totalValue);
        await prefs.setDouble(_kTotalSharesKey, totalShares);
        await prefs.setString(_kHoldingsKey,    jsonEncode(holdings));

        // Preserve existing chart series if count unchanged
        final charts = holdings.length != _portfolioHoldings.length
            ? _buildInitialCharts(holdings.length)
            : _holdingChartData;

        setState(() {
          _portfolioHoldings   = holdings;
          _totalPortfolioValue = totalValue;
          _totalShares         = totalShares;
          _holdingChartData    = charts;
          _currentX            = 20;
          _isLoadingPortfolio  = false;
        });
      } else {
        setState(() {
          _portfolioError     = 'Server error ${response.statusCode}';
          _isLoadingPortfolio = false;
        });
      }
    } catch (e, st) {
      debugPrint('Portfolio fetch error: $e\n$st');
      if (mounted) {
        setState(() {
          _portfolioError     = 'Could not load portfolio';
          _isLoadingPortfolio = false;
        });
      }
    }
  }

  List<List<FlSpot>> _buildInitialCharts(int count) {
    return List.generate(
      count,
          (_) => List.generate(
        20,
            (i) => FlSpot(i.toDouble(), 50 + math.Random().nextDouble() * 20),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Live chart animation
  // ─────────────────────────────────────────────────────────────

  void _startLiveDataUpdate() {
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted || _holdingChartData.isEmpty) return;
      setState(() {
        for (int hi = 0; hi < _holdingChartData.length; hi++) {
          final data = _holdingChartData[hi];
          final dir  = hi % 2 == 0 ? 1.0 : -1.0;
          data.add(FlSpot(
            _currentX,
            (50 + dir * math.Random().nextDouble() * 20).clamp(5.0, 95.0),
          ));
          if (data.length > 20) {
            data.removeAt(0);
            for (int i = 0; i < data.length; i++) {
              data[i] = FlSpot(i.toDouble(), data[i].y);
            }
          }
        }
        _currentX = (_holdingChartData.isNotEmpty &&
            _holdingChartData[0].length >= 20)
            ? 20
            : _currentX + 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  Navigation
  // ─────────────────────────────────────────────────────────────

  Future<void> _navigateWithDebounce(Widget destination) async {
    if (_isNavigating) return;
    final now = DateTime.now();
    if (_lastNavigationTime != null &&
        now.difference(_lastNavigationTime!).inMilliseconds <
            _navigationDebounceMs) return;
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
  //  Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;

        final bgGradient = isDark
            ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C1810), Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
        )
            : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E7), Color(0xFFF5F5F5), Color(0xFFFFFFFF)],
        );

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          drawer: AppDrawer(
            onMenuItemTapped:    (i) => setState(() => _selectedIndex = i),
            onMarketWatchTapped: () => _navigateWithDebounce(const MarketWatchScreen()),
            onBuySellTapped:     () => _navigateWithDebounce(const TradingPage()),
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
                      children: [
                        _buildDashboardTab(isDark),   // 0 – home
                        const TradingPage(),           // 1
                        Container(),                   // 2 – FAB
                        const TransactionsScreen(),    // 3
                        const PortfolioScreen(),       // 4
                      ],
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

  // ─────────────────────────────────────────────────────────────
  //  Dashboard tab  (part of build() tree → always up-to-date)
  // ─────────────────────────────────────────────────────────────

  Widget _buildDashboardTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildPortfolioCard(isDark),
          const SizedBox(height: 30),
          _buildSectionHeader('My Portfolio', 'View Details', isDark, null),
          const SizedBox(height: 15),
          _buildHoldingsSection(),
          const SizedBox(height: 30),
          _buildSectionHeader(
            'Market Watch', 'See All', isDark,
                () => _navigateWithDebounce(const MarketWatchScreen()),
          ),
          const SizedBox(height: 15),
          MarketWatchWidget(isDark: isDark, showLimited: true),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHoldingsSection() {
    // Still loading and nothing cached yet
    if (_isLoadingPortfolio && _portfolioHoldings.isEmpty) {
      return const SizedBox(
        height: 195,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error and nothing to show
    if (_portfolioError != null && _portfolioHoldings.isEmpty) {
      return SizedBox(
        height: 195,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 36),
              const SizedBox(height: 8),
              Text(_portfolioError!,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadPortfolioFromApi,
                icon: const Icon(Icons.refresh, color: Colors.amber),
                label: const Text('Retry',
                    style: TextStyle(color: Colors.amber)),
              ),
            ],
          ),
        ),
      );
    }

    // Empty after load
    if (_portfolioHoldings.isEmpty) {
      return const SizedBox(
        height: 195,
        child: Center(
          child: Text('No holdings found',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ),
      );
    }

    return PortfolioWidget(
      holdings:      _portfolioHoldings,
      chartDataList: _holdingChartData,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    final displayName = _fullName.isNotEmpty ? _fullName.toUpperCase() : 'WELCOME';
    final displaySub  = _cdsNumber.isNotEmpty ? _cdsNumber : _email;

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
                Text(displayName,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(displaySub,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
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
                  width: 8, height: 8,
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
  //  Portfolio balance card
  // ─────────────────────────────────────────────────────────────

  Widget _buildPortfolioCard(bool isDark) {
    final formattedTotal  = _formatAmount(_totalPortfolioValue);
    final formattedShares = _formatAmount(_totalShares);
    final holdingsCount   = _portfolioHoldings.length;

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
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Portfolio Balance',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(
                            () => _isBalanceVisible = !_isBalanceVisible),
                    child: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white, size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _loadPortfolioFromApi,
                    child: _isLoadingPortfolio
                        ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            _isLoadingPortfolio && _totalPortfolioValue == 0
                ? '...'
                : (_isBalanceVisible ? formattedTotal : '••••••••'),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w300,
                letterSpacing: 1),
          ),

          const SizedBox(height: 12),

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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CDS: ${_cdsNumber.isNotEmpty ? _cdsNumber : '—'}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 12)),
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
      String title, String action, bool isDark, VoidCallback? onActionTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          if (action.isNotEmpty)
            GestureDetector(
              onTap: onActionTap,
              child: Text(action,
                  style: TextStyle(
                      color: isDark ? Colors.amber : const Color(0xFFB8860B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
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
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
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
            _buildNavItem(Icons.home_outlined,        0, isDark),
            _buildNavItem(Icons.bar_chart_outlined,   1, isDark),
            const SizedBox(width: 50),
            _buildNavItem(Icons.attach_money,         3, isDark),
            _buildNavItem(Icons.shopping_bag_outlined, 4, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () { if (index != 2) setState(() => _selectedIndex = index); },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(icon,
            color: isSelected
                ? Colors.amber
                : (isDark ? Colors.white54 : Colors.black45),
            size: 28),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 65, height: 65,
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
        RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  }
}