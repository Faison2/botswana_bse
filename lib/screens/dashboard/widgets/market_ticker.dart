import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bse/contants/constants.dart';

class MarketTickerWidget extends StatefulWidget {
  final bool isDark;

  const MarketTickerWidget({super.key, required this.isDark});

  @override
  State<MarketTickerWidget> createState() => _MarketTickerWidgetState();
}

class _MarketTickerWidgetState extends State<MarketTickerWidget> {
  List<_TickerItem> _items = [];
  bool _isLoading = true;

  // Scroll animation
  late ScrollController _scrollController;
  Timer? _scrollTimer;
  Timer? _fetchTimer;

  static const double _scrollSpeed = 0.8; // pixels per tick
  static const int _scrollIntervalMs = 16; // ~60fps

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchMarketData();
    // Refresh data every 60 seconds
    _fetchTimer = Timer.periodic(const Duration(seconds: 60), (_) => _fetchMarketData());
  }

  Future<void> _fetchMarketData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return;

      final response = await http.post(
        Uri.parse('$baseUrl/Home/getMarketData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> jsonData = decoded is List ? decoded : [decoded];

        if (jsonData.isNotEmpty && jsonData[0]['MdataItem'] != null) {
          final dynamic rawItems = jsonData[0]['MdataItem'];
          final List<dynamic> itemList = rawItems is List ? rawItems : [rawItems];

          final items = itemList.whereType<Map>().map((item) {
            final vwap = double.tryParse(item['VwapPrice']?.toString() ?? '0') ?? 0;
            final open = double.tryParse(item['OpeningPrice']?.toString() ?? '0') ?? 0;
            final change = open != 0 ? ((vwap - open) / open) * 100 : 0.0;
            return _TickerItem(
              symbol: item['Symbol']?.toString() ?? '',
              changePercent: change,
            );
          }).where((t) => t.symbol.isNotEmpty).toList();

          setState(() {
            _items = items;
            _isLoading = false;
          });

          // Start scrolling after data loaded
          WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
        }
      }
    } catch (e) {
      debugPrint('Ticker fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    if (!_scrollController.hasClients) return;

    _scrollTimer = Timer.periodic(
      Duration(milliseconds: _scrollIntervalMs),
          (_) {
        if (!_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;
        final current = _scrollController.offset;

        if (current >= max) {
          // Jump back to start seamlessly (we duplicate the list)
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(current + _scrollSpeed);
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _fetchTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFEEEEEE);
    final dividerColor = widget.isDark
        ? Colors.white24
        : Colors.black12;

    if (_isLoading || _items.isEmpty) {
      return Container(
        height: 36,
        color: bgColor,
        child: Center(
          child: SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: widget.isDark ? Colors.amber : const Color(0xFFB8860B),
            ),
          ),
        ),
      );
    }

    // Duplicate list so scroll loops seamlessly
    final displayItems = [..._items, ..._items, ..._items];

    return Container(
      height: 36,
      color: bgColor,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayItems.length,
        separatorBuilder: (_, __) => Container(
          width: 1,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: dividerColor,
        ),
        itemBuilder: (context, index) {
          final item = displayItems[index];
          final isPositive = item.changePercent >= 0;
          final changeColor = isPositive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);
          final prefix = isPositive ? '+' : '';
          final textColor = widget.isDark ? Colors.white : Colors.black87;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.symbol,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: changeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$prefix${item.changePercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TickerItem {
  final String symbol;
  final double changePercent;
  const _TickerItem({required this.symbol, required this.changePercent});
}