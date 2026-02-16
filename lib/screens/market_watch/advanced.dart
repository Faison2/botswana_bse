import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme_provider.dart';
import 'comparison_screen_analysis.dart';

class CompanyComparisonScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? allStocks;

  const CompanyComparisonScreen({
    Key? key,
    this.allStocks,
  }) : super(key: key);

  @override
  State<CompanyComparisonScreen> createState() => _CompanyComparisonScreenState();
}

class _CompanyComparisonScreenState extends State<CompanyComparisonScreen> {
  final Set<int> _selectedIndices = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _marketData = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _token;

  final String _apiUrl = 'http://192.168.3.201/MainAPI/Home/getMarketData';

  @override
  void initState() {
    super.initState();
    if (widget.allStocks != null && widget.allStocks!.isNotEmpty) {
      _marketData = widget.allStocks!;
      _isLoading = false;
    } else {
      _initializeAndFetch();
    }
  }

  Future<void> _initializeAndFetch() async {
    await _loadToken();
    if (_token != null) {
      await _fetchMarketData();
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

  List<double> _generateRealisticPriceHistory(double closePrice, double openPrice) {
    final history = <double>[];
    final random = math.Random();
    double currentPrice = closePrice * (0.9 + random.nextDouble() * 0.2);

    for (int i = 0; i < 30; i++) {
      final trend = (closePrice - currentPrice) / (30 - i);
      final volatility = closePrice * 0.02;
      final change = trend + (random.nextDouble() - 0.5) * volatility;
      currentPrice += change;
      history.add(currentPrice);
    }
    return history;
  }

  List<Map<String, dynamic>> _generateCandlestickData(
      double closePrice,
      double openPrice,
      double maxPrice,
      double minPrice
      ) {
    final data = <Map<String, dynamic>>[];
    final random = math.Random();
    double currentPrice = closePrice * 0.95;

    for (int i = 0; i < 30; i++) {
      final dayOpen = currentPrice;
      final volatility = closePrice * 0.03;
      final dayClose = dayOpen + (random.nextDouble() - 0.5) * volatility;
      final dayHigh = math.max(dayOpen, dayClose) + random.nextDouble() * volatility * 0.5;
      final dayLow = math.min(dayOpen, dayClose) - random.nextDouble() * volatility * 0.5;

      data.add({
        'open': dayOpen,
        'close': dayClose,
        'high': dayHigh,
        'low': dayLow,
        'date': DateTime.now().subtract(Duration(days: 30 - i)),
      });

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredStocks {
    if (_searchQuery.isEmpty) {
      return _marketData;
    }
    return _marketData.where((stock) {
      final company = (stock['Company'] ?? '').toString().toLowerCase();
      final symbol = (stock['Symbol'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return company.contains(query) || symbol.contains(query);
    }).toList();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        if (_selectedIndices.length < 5) {
          _selectedIndices.add(index);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only compare up to 5 companies'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _navigateToComparison() {
    if (_selectedIndices.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 companies to compare'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final selectedStocks = _selectedIndices.map((index) => _marketData[index]).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComparisonAnalysisScreen(
          selectedStocks: selectedStocks,
        ),
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedIndices.clear();
    });
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
    final searchBgColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade100;

    final filteredList = _filteredStocks;

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
                      child: Text(
                        'Compare Companies',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_selectedIndices.isNotEmpty)
                      GestureDetector(
                        onTap: _clearSelection,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.clear_all,
                            color: accentColor,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: searchBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search companies...',
                      hintStyle: TextStyle(color: subtextColor),
                      prefixIcon: Icon(Icons.search, color: accentColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: subtextColor),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Selection Info
              if (_selectedIndices.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: accentColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_selectedIndices.length} ${_selectedIndices.length == 1 ? 'company' : 'companies'} selected (max 5)',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

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
                    : filteredList.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: subtextColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No companies found',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: filteredList.length,
                  itemBuilder: (context, listIndex) {
                    // Find the original index in _marketData
                    final stock = filteredList[listIndex];
                    final originalIndex = _marketData.indexOf(stock);
                    final isSelected = _selectedIndices.contains(originalIndex);

                    return _buildCompanyCard(
                      stock,
                      originalIndex,
                      isSelected,
                      isDark,
                      textColor,
                      subtextColor,
                      accentColor,
                      cardBgColor,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Compare Button
      floatingActionButton: _selectedIndices.length >= 2
          ? Container(
        width: MediaQuery.of(context).size.width - 40,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: FloatingActionButton.extended(
          onPressed: _navigateToComparison,
          backgroundColor: accentColor,
          icon: const Icon(Icons.analytics, color: Colors.white),
          label: Text(
            'Compare ${_selectedIndices.length} Companies',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCompanyCard(
      Map<String, dynamic> stock,
      int index,
      bool isSelected,
      bool isDark,
      Color textColor,
      Color subtextColor,
      Color accentColor,
      Color cardBgColor,
      ) {
    final closePrice = double.tryParse(stock['ClosingPrice']?.toString() ?? '0') ?? 0;
    final openPrice = double.tryParse(stock['OpeningPrice']?.toString() ?? '0') ?? 0;
    final priceChange = closePrice - openPrice;
    final priceChangePercent = openPrice != 0 ? (priceChange / openPrice) * 100 : 0;
    final isPositive = priceChange >= 0;

    return GestureDetector(
      onTap: () => _toggleSelection(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
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
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : subtextColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
                  : null,
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
                      fontSize: 15,
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

            const SizedBox(width: 12),

            // Price & Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TZS ${closePrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${priceChangePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 11,
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
    );
  }
}