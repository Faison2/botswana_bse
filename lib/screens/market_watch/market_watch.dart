import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import '../buy_sell/buy_sell.dart';

class MarketWatchScreen extends StatefulWidget {
  const MarketWatchScreen({super.key});

  @override
  State<MarketWatchScreen> createState() => _MarketWatchScreenState();
}

class _MarketWatchScreenState extends State<MarketWatchScreen> {
  Timer? _timer;
  List<Map<String, dynamic>> _marketData = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _token;

  final String _apiUrl = 'http://192.168.3.201/MainAPI/Home/getMarketData';

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    await _loadToken();
    if (_token != null) {
      await _fetchMarketData();
      _startAutoRefresh();
    } else {
      setState(() {
        _errorMessage = 'No authentication token found. Please login again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        setState(() {
          _token = token;
        });
      } else {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading token: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMarketData() async {
    if (_token == null) {
      setState(() {
        _errorMessage = 'No authentication token available';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        if (jsonData.isNotEmpty && jsonData[0]['MdataItem'] != null) {
          final List<dynamic> items = jsonData[0]['MdataItem'];

          setState(() {
            _marketData = items.map((item) {
              final Map<String, dynamic> raw = Map<String, dynamic>.from(item as Map);

              final closePrice = double.tryParse(raw['ClosingPrice']?.toString() ?? '0') ?? 0;
              final openPrice = double.tryParse(raw['OpeningPrice']?.toString() ?? '0') ?? 0;
              final maxPrice = double.tryParse(raw['MaxPrice']?.toString() ?? '0') ?? 0;
              final minPrice = double.tryParse(raw['MinPrice']?.toString() ?? '0') ?? 0;

              return {
                ...raw,
                'priceHistory': _generateRealisticPriceHistory(closePrice, openPrice),
                'candlestickData': _generateCandlestickData(closePrice, openPrice, maxPrice, minPrice),
                'currentPrice': closePrice,
                'iconData': _getIconForCompany(raw['Symbol'] ?? ''),
                'iconBg': _getColorForCompany(raw['Symbol'] ?? ''),
                'volume': _generateVolumeData(),
                'marketCap': _calculateMarketCap(closePrice),
                'peRatio': _generatePERatio(),
                'dayHigh': maxPrice,
                'dayLow': minPrice,
                'weekHigh52': maxPrice * 1.15,
                'weekLow52': minPrice * 0.85,
              };
            }).toList();
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // Generate more realistic price history with trends
  List<double> _generateRealisticPriceHistory(double closePrice, double openPrice) {
    final history = <double>[];
    final random = math.Random();

    // Start from a base price 30 days ago
    double currentPrice = closePrice * (0.9 + random.nextDouble() * 0.2);

    for (int i = 0; i < 30; i++) {
      // Add trend with some randomness
      final trend = (closePrice - currentPrice) / (30 - i);
      final volatility = closePrice * 0.02; // 2% daily volatility
      final change = trend + (random.nextDouble() - 0.5) * volatility;

      currentPrice += change;
      history.add(currentPrice);
    }

    return history;
  }

  // Generate candlestick data for the last 30 days
  List<CandlestickData> _generateCandlestickData(
      double closePrice,
      double openPrice,
      double maxPrice,
      double minPrice
      ) {
    final data = <CandlestickData>[];
    final random = math.Random();

    double currentPrice = closePrice * 0.95;

    for (int i = 0; i < 30; i++) {
      final dayOpen = currentPrice;
      final volatility = closePrice * 0.03;

      final dayClose = dayOpen + (random.nextDouble() - 0.5) * volatility;
      final dayHigh = math.max(dayOpen, dayClose) + random.nextDouble() * volatility * 0.5;
      final dayLow = math.min(dayOpen, dayClose) - random.nextDouble() * volatility * 0.5;

      data.add(CandlestickData(
        open: dayOpen,
        close: dayClose,
        high: dayHigh,
        low: dayLow,
        date: DateTime.now().subtract(Duration(days: 30 - i)),
      ));

      currentPrice = dayClose;
    }

    return data;
  }

  List<double> _generateVolumeData() {
    final random = math.Random();
    return List.generate(30, (index) => 1000000 + random.nextDouble() * 5000000);
  }

  String _calculateMarketCap(double price) {
    final random = math.Random();
    final marketCap = price * (10000000 + random.nextInt(90000000));

    if (marketCap >= 1000000000) {
      return '${(marketCap / 1000000000).toStringAsFixed(2)}B';
    } else if (marketCap >= 1000000) {
      return '${(marketCap / 1000000).toStringAsFixed(2)}M';
    }
    return marketCap.toStringAsFixed(0);
  }

  double _generatePERatio() {
    final random = math.Random();
    return 10 + random.nextDouble() * 30;
  }

  IconData _getIconForCompany(String symbol) {
    if (symbol.contains('BANK') || symbol.contains('CRDB') || symbol.contains('NMB') || symbol.contains('KCB') || symbol.contains('DCB') || symbol.contains('MKCB') || symbol.contains('MUCOBA') || symbol.contains('MCB') || symbol.contains('MBP')) {
      return Icons.account_balance;
    } else if (symbol.contains('BREW') || symbol.contains('TBL') || symbol.contains('EABL')) {
      return Icons.local_drink;
    } else if (symbol.contains('AIR') || symbol.contains('KA') || symbol.contains('PAL')) {
      return Icons.flight;
    } else if (symbol.contains('CEMENT') || symbol.contains('TCCL') || symbol.contains('TPCC')) {
      return Icons.construction;
    } else if (symbol.contains('VODA') || symbol.contains('TELECOM')) {
      return Icons.phone_android;
    } else if (symbol.contains('MEDIA') || symbol.contains('NMG')) {
      return Icons.newspaper;
    } else if (symbol.contains('INSURANCE') || symbol.contains('JHL')) {
      return Icons.security;
    } else if (symbol.contains('OIL') || symbol.contains('GAS') || symbol.contains('SWALA') || symbol.contains('TOL')) {
      return Icons.local_gas_station;
    }
    return Icons.business;
  }

  Color _getColorForCompany(String symbol) {
    final hash = symbol.hashCode;
    final colors = [
      const Color(0xFF3D2F1F),
      const Color(0xFF2A3F2F),
      const Color(0xFF2F3A4A),
      const Color(0xFF4A2F2F),
      const Color(0xFF2F4A3F),
      const Color(0xFF3F2F4A),
    ];
    return colors[hash.abs() % colors.length];
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchMarketData();
    });
  }

  void _showFullScreenStockDetails(Map<String, dynamic> stock, bool isDark) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenStockDetails(
          stock: stock,
          isDark: isDark,
          allStocks: _marketData,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    final accentColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
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
                        child: Icon(
                          Icons.arrow_back,
                          color: textColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Market Watch',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _fetchMarketData,
                      icon: Icon(
                        Icons.refresh,
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: accentColor,
                  ),
                )
                    : _errorMessage != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeAndFetch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
                    : _marketData.isEmpty
                    ? Center(
                  child: Text(
                    'No market data available',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _marketData.length,
                  itemBuilder: (context, index) {
                    final stock = _marketData[index];
                    return _buildStockCard(stock, isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> stock, bool isDark) {
    final priceHistory = stock['priceHistory'] as List<double>;
    final closePrice = double.tryParse(stock['ClosingPrice']?.toString() ?? '0') ?? 0;
    final status = stock['status']?.toString().toUpperCase() ?? '';

    final cardBgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.5) : Colors.black54;

    return GestureDetector(
      onTap: () => _showFullScreenStockDetails(stock, isDark),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Company Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock['Company'] ?? 'N/A',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stock['Symbol'] ?? 'N/A',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TZS ${stock['ClosingPrice'] ?? '0'}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: stock['status'] == 'GAIN'
                            ? Colors.green.withOpacity(0.2)
                            : stock['status'] == 'LOSE'
                            ? Colors.red.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        stock['status'] ?? 'N/A',
                        style: TextStyle(
                          color: stock['status'] == 'GAIN'
                              ? Colors.green
                              : stock['status'] == 'LOSE'
                              ? Colors.red
                              : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
                  status: status,
                ),
                child: Container(),
              ),
            ),

            const SizedBox(height: 12),

            // Quick Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickStat('Open', 'TZS ${stock['OpeningPrice'] ?? 'N/A'}', subtextColor, textColor),
                _buildQuickStat('High', 'TZS ${stock['MaxPrice'] ?? 'N/A'}', subtextColor, textColor),
                _buildQuickStat('Low', 'TZS ${stock['MinPrice'] ?? 'N/A'}', subtextColor, textColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color subtextColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subtextColor,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Full Screen Stock Details Widget
class FullScreenStockDetails extends StatefulWidget {
  final Map<String, dynamic> stock;
  final bool isDark;
  final List<Map<String, dynamic>> allStocks;

  const FullScreenStockDetails({
    Key? key,
    required this.stock,
    required this.isDark,
    required this.allStocks,
  }) : super(key: key);

  @override
  State<FullScreenStockDetails> createState() => _FullScreenStockDetailsState();
}

class _FullScreenStockDetailsState extends State<FullScreenStockDetails> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedTimeframe = '1D';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToTrading(bool isBuy) {
    // Prepare stock data for trading page
    final stockData = {
      'name': widget.stock['Company'] ?? 'Unknown',
      'ticker': widget.stock['Symbol'] ?? 'N/A',
      'code': widget.stock['Code'] ?? '',
      'price': 'TZS ${widget.stock['ClosingPrice'] ?? '0'}',
      'closingPriceValue': double.tryParse(widget.stock['ClosingPrice']?.toString() ?? '0') ?? 0.0,
      'openingPriceValue': double.tryParse(widget.stock['OpeningPrice']?.toString() ?? '0') ?? 0.0,
      'maxPriceValue': double.tryParse(widget.stock['MaxPrice']?.toString() ?? '0') ?? 0.0,
      'minPriceValue': double.tryParse(widget.stock['MinPrice']?.toString() ?? '0') ?? 0.0,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TradingPage(
          prefilledStockData: stockData,
          allStocks: widget.allStocks.map((stock) {
            return {
              'name': stock['Company'] ?? 'Unknown',
              'ticker': stock['Symbol'] ?? 'N/A',
              'code': stock['Code'] ?? '',
              'price': 'TZS ${stock['ClosingPrice'] ?? '0'}',
              'closingPriceValue': double.tryParse(stock['ClosingPrice']?.toString() ?? '0') ?? 0.0,
              'openingPriceValue': double.tryParse(stock['OpeningPrice']?.toString() ?? '0') ?? 0.0,
              'maxPriceValue': double.tryParse(stock['MaxPrice']?.toString() ?? '0') ?? 0.0,
              'minPriceValue': double.tryParse(stock['MinPrice']?.toString() ?? '0') ?? 0.0,
            };
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final cardBgColor = widget.isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final subtextColor = widget.isDark ? Colors.white.withOpacity(0.6) : Colors.black54;
    final accentColor = widget.isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);

    final closePrice = double.tryParse(widget.stock['ClosingPrice']?.toString() ?? '0') ?? 0;
    final openPrice = double.tryParse(widget.stock['OpeningPrice']?.toString() ?? '0') ?? 0;
    final priceChange = closePrice - openPrice;
    final priceChangePercent = openPrice != 0 ? (priceChange / openPrice) * 100 : 0;
    final isPositive = priceChange >= 0;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: widget.stock['iconBg'],
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.stock['Company'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.stock['Symbol'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TZS ${closePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isPositive ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${priceChange.toStringAsFixed(2)} (${priceChangePercent.toStringAsFixed(2)}%)',
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              color: cardBgColor,
              child: TabBar(
                controller: _tabController,
                labelColor: accentColor,
                unselectedLabelColor: subtextColor,
                indicatorColor: accentColor,
                tabs: const [
                  Tab(text: 'Chart'),
                  Tab(text: 'Details'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Chart Tab
                  _buildChartTab(cardBgColor, textColor, subtextColor, accentColor),
                  // Details Tab
                  _buildDetailsTab(cardBgColor, textColor, subtextColor),
                ],
              ),
            ),

            // Buy/Sell Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToTrading(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black,
                              Colors.red,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'SELL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToTrading(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.green,
                              Colors.black,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'BUY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTab(Color cardBgColor, Color textColor, Color subtextColor, Color accentColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Timeframe Selector
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: ['1D', '1W', '1M', '3M', '1Y', 'ALL'].map((timeframe) {
                final isSelected = selectedTimeframe == timeframe;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTimeframe = timeframe;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          timeframe,
                          style: TextStyle(
                            color: isSelected ? Colors.white : subtextColor,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Candlestick Chart
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 300,
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CustomPaint(
                painter: CandlestickChartPainter(
                  candlestickData: widget.stock['candlestickData'] as List<CandlestickData>,
                  isDark: widget.isDark,
                ),
                child: Container(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Volume Chart
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 150,
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volume',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: CustomPaint(
                      painter: VolumeChartPainter(
                        volumeData: widget.stock['volume'] as List<double>,
                        isDark: widget.isDark,
                      ),
                      child: Container(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Key Stats
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Statistics',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('Day Range',
                    'TZS ${widget.stock['dayLow']?.toStringAsFixed(2)} - ${widget.stock['dayHigh']?.toStringAsFixed(2)}',
                    textColor, subtextColor),
                const SizedBox(height: 12),
                _buildStatRow('52 Week Range',
                    'TZS ${widget.stock['weekLow52']?.toStringAsFixed(2)} - ${widget.stock['weekHigh52']?.toStringAsFixed(2)}',
                    textColor, subtextColor),
                const SizedBox(height: 12),
                _buildStatRow('Market Cap', widget.stock['marketCap'] ?? 'N/A', textColor, subtextColor),
                const SizedBox(height: 12),
                _buildStatRow('P/E Ratio', widget.stock['peRatio']?.toStringAsFixed(2) ?? 'N/A', textColor, subtextColor),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(Color cardBgColor, Color textColor, Color subtextColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price Details
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
                    'Price Details',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Opening Price', 'TZS ${widget.stock['OpeningPrice'] ?? 'N/A'}', textColor, subtextColor),
                  const SizedBox(height: 12),
                  _buildDetailRow('Closing Price', 'TZS ${widget.stock['ClosingPrice'] ?? 'N/A'}', textColor, subtextColor),
                  const SizedBox(height: 12),
                  _buildDetailRow('Settlement Price', 'TZS ${widget.stock['SettlementPrice'] ?? 'N/A'}', textColor, subtextColor),
                  const SizedBox(height: 12),
                  _buildDetailRow('VWAP Price', 'TZS ${widget.stock['VwapPrice'] ?? 'N/A'}', textColor, subtextColor),
                  const SizedBox(height: 12),
                  _buildDetailRow('Maximum Price', 'TZS ${widget.stock['MaxPrice'] ?? 'N/A'}', textColor, subtextColor),
                  const SizedBox(height: 12),
                  _buildDetailRow('Minimum Price', 'TZS ${widget.stock['MinPrice'] ?? 'N/A'}', textColor, subtextColor),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Company Information
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
                    'Company Information',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('ISIN', widget.stock['ISIN'] ?? 'N/A', textColor, subtextColor),
                  const SizedBox(height: 12),
                  _buildDetailRow('Code', widget.stock['Code'] ?? 'N/A', textColor, subtextColor),
                  const SizedBox(height: 12),
                  _buildDetailRow('Security Type', widget.stock['securitytype'] ?? 'N/A', textColor, subtextColor),
                  const SizedBox(height: 12),
                  _buildDetailRow('Open Interest', widget.stock['Openinterest'] ?? 'N/A', textColor, subtextColor),
                ],
              ),
            ),
          ],
        ),
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
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color textColor, Color subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subtextColor,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Candlestick Data Model
class CandlestickData {
  final double open;
  final double close;
  final double high;
  final double low;
  final DateTime date;

  CandlestickData({
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.date,
  });
}

// Candlestick Chart Painter
class CandlestickChartPainter extends CustomPainter {
  final List<CandlestickData> candlestickData;
  final bool isDark;

  CandlestickChartPainter({
    required this.candlestickData,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candlestickData.isEmpty) return;

    final prices = candlestickData.expand((c) => [c.high, c.low]).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    // Draw grid lines
    _drawGridLines(canvas, size, minPrice, maxPrice, priceRange);

    final candleWidth = (size.width / candlestickData.length) * 0.7;
    final spacing = size.width / candlestickData.length;

    for (int i = 0; i < candlestickData.length; i++) {
      final candle = candlestickData[i];
      final x = i * spacing + spacing / 2;

      final isGreen = candle.close >= candle.open;
      final color = isGreen
          ? const Color(0xFF26A69A) // Beautiful teal green
          : const Color(0xFFEF5350); // Beautiful red

      // Draw wick (high-low line)
      final highY = size.height - ((candle.high - minPrice) / priceRange) * size.height;
      final lowY = size.height - ((candle.low - minPrice) / priceRange) * size.height;

      final wickPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        wickPaint,
      );

      // Draw candle body with shadow
      final openY = size.height - ((candle.open - minPrice) / priceRange) * size.height;
      final closeY = size.height - ((candle.close - minPrice) / priceRange) * size.height;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - candleWidth / 2,
          math.min(openY, closeY),
          x + candleWidth / 2,
          math.max(openY, closeY) == math.min(openY, closeY)
              ? math.max(openY, closeY) + 1 // Ensure minimum height for doji
              : math.max(openY, closeY),
        ),
        const Radius.circular(2),
      );

      // Draw shadow for depth
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawRRect(
        rect.shift(const Offset(1, 1)),
        shadowPaint,
      );

      // Draw candle body
      if (isGreen) {
        // Green candle - outline with light fill
        final outlinePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        final fillPaint = Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.fill;

        canvas.drawRRect(rect, fillPaint);
        canvas.drawRRect(rect, outlinePaint);
      } else {
        // Red candle - solid fill
        final bodyPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        canvas.drawRRect(rect, bodyPaint);
      }
    }

    // Draw price labels
    _drawPriceLabels(canvas, size, minPrice, maxPrice, isDark);
  }

  void _drawGridLines(Canvas canvas, Size size, double minPrice, double maxPrice, double priceRange) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  void _drawPriceLabels(Canvas canvas, Size size, double minPrice, double maxPrice, bool isDark) {
    final textColor = isDark ? Colors.white70 : Colors.black54;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw max price
    textPainter.text = TextSpan(
      text: maxPrice.toStringAsFixed(2),
      style: TextStyle(
        color: textColor,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 4, 2));

    // Draw min price
    textPainter.text = TextSpan(
      text: minPrice.toStringAsFixed(2),
      style: TextStyle(
        color: textColor,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 4, size.height - textPainter.height - 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Volume Chart Painter
class VolumeChartPainter extends CustomPainter {
  final List<double> volumeData;
  final bool isDark;

  VolumeChartPainter({
    required this.volumeData,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (volumeData.isEmpty) return;

    final maxVolume = volumeData.reduce((a, b) => a > b ? a : b);
    if (maxVolume == 0) return;

    final barWidth = (size.width / volumeData.length) * 0.7;
    final spacing = size.width / volumeData.length;

    for (int i = 0; i < volumeData.length; i++) {
      final volume = volumeData[i];
      final x = i * spacing + spacing / 2;
      final barHeight = (volume / maxVolume) * size.height;

      // Create gradient based on volume intensity
      final intensity = volume / maxVolume;
      final baseColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - barWidth / 2,
          size.height - barHeight,
          x + barWidth / 2,
          size.height,
        ),
        const Radius.circular(2),
      );

      // Draw shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawRRect(
        rect.shift(const Offset(0.5, 0.5)),
        shadowPaint,
      );

      // Draw bar with gradient
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          baseColor.withOpacity(0.9),
          baseColor.withOpacity(0.5),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect.outerRect)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, paint);

      // Add highlight on top
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final highlightRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          x - barWidth / 2,
          size.height - barHeight,
          x + barWidth / 2,
          size.height - barHeight + 2,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(highlightRect, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for mini graph
class MiniGraphPainter extends CustomPainter {
  final List<double> priceHistory;
  final String status;

  MiniGraphPainter({required this.priceHistory, required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    if (priceHistory.isEmpty) return;

    // Determine color based on status
    Color graphColor;
    if (status == 'GAIN') {
      graphColor = const Color(0xFF26A69A); // Beautiful teal green
    } else if (status == 'LOSE') {
      graphColor = const Color(0xFFEF5350); // Beautiful red
    } else {
      graphColor = Colors.grey;
    }

    final paint = Paint()
      ..color = graphColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          graphColor.withOpacity(0.4),
          graphColor.withOpacity(0.1),
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

    // Generate points
    for (int i = 0; i < priceHistory.length; i++) {
      final x = (i / (priceHistory.length - 1)) * size.width;
      final normalizedPrice = (priceHistory[i] - minPrice) / priceRange;
      final y = size.height - (normalizedPrice * size.height * 0.9) - (size.height * 0.05);
      points.add(Offset(x, y));
    }

    // Create smooth curve using cubic bezier
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];

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

        fillPath.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p1.dx, p1.dy,
        );
      }

      fillPath.lineTo(size.width, size.height);
      fillPath.close();

      // Draw shadow under the line
      final shadowPaint = Paint()
        ..color = graphColor.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawPath(path, shadowPaint..strokeWidth = 4);

      // Draw fill
      canvas.drawPath(fillPath, fillPaint);

      // Draw line
      canvas.drawPath(path, paint);

      // Draw glow effect on the line
      final glowPaint = Paint()
        ..color = graphColor.withOpacity(0.5)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}