import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import 'ipo_bid_screen.dart';
import 'ipo_models.dart';

/// Full-screen "IPO Market Watch" — lists every IPO in the pipeline
/// (upcoming, open, closing soon, closed), mirroring the layout and
/// colour language of [MarketWatchScreen] so it feels like the same app.
class IpoMarketWatchScreen extends StatefulWidget {
  const IpoMarketWatchScreen({super.key});

  @override
  State<IpoMarketWatchScreen> createState() => _IpoMarketWatchScreenState();
}

class _IpoMarketWatchScreenState extends State<IpoMarketWatchScreen> {
  List<IpoListing> _listings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final listings = await IpoRepository.fetchListings();
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load IPOs';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF2C1810), Color(0xFF1A1A1A), Color(0xFF0D0D0D)])
        : const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E7), Color(0xFFF5F5F5), Color(0xFFFFFFFF)]);

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
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back, color: textColor, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('IPO Market Watch',
                          style: TextStyle(
                              color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: _load,
                      icon: Icon(Icons.refresh, color: accentColor, size: 24),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: accentColor))
                    : _error != null
                        ? Center(
                            child: Text(_error!,
                                style: TextStyle(color: textColor, fontSize: 15)))
                        : _listings.isEmpty
                            ? Center(
                                child: Text('No IPOs available right now',
                                    style: TextStyle(color: textColor, fontSize: 15)))
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 40),
                                itemCount: _listings.length,
                                itemBuilder: (context, index) => IpoCard(
                                  ipo: _listings[index],
                                  isDark: isDark,
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single IPO row card — reused on the full IPO Market Watch screen
/// and (in limited form) on the dashboard's "IPO Market Watch" section.
class IpoCard extends StatelessWidget {
  final IpoListing ipo;
  final bool isDark;

  const IpoCard({super.key, required this.ipo, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.55) : Colors.black54;
    final accentColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);

    return GestureDetector(
      onTap: () => showIpoDetailSheet(context, ipo, isDark),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: ipo.accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ipo.companyName,
                          style: TextStyle(
                              color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text('${ipo.ticker}  ·  ${ipo.sector}',
                          style: TextStyle(color: subtextColor, fontSize: 11.5)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('BWP ${ipo.pricePerShare.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ipo.statusColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(ipo.statusLabel,
                          style: TextStyle(
                              color: ipo.statusColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (ipo.subscriptionPercent / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                color: accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${ipo.subscriptionPercent.toStringAsFixed(0)}% subscribed',
                    style: TextStyle(color: subtextColor, fontSize: 11)),
                Text(
                  ipo.status == IpoStatus.closed
                      ? 'Closed'
                      : ipo.status == IpoStatus.upcoming
                          ? 'Opens ${_formatDate(ipo.openDate)}'
                          : '${ipo.daysRemaining} day${ipo.daysRemaining == 1 ? '' : 's'} left',
                  style: TextStyle(color: subtextColor, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

/// Bottom sheet with full IPO details and the "Bid Now" CTA.
void showIpoDetailSheet(BuildContext context, IpoListing ipo, bool isDark) {
  final cardColor = isDark ? const Color(0xFF23201C) : Colors.white;
  final textColor = isDark ? Colors.white : Colors.black87;
  final subtextColor = isDark ? Colors.white70 : Colors.black54;
  final accentColor = isDark ? const Color(0xFF8B6914) : const Color(0xFFD4A855);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subtextColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(ipo.companyName,
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ipo.statusColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(ipo.statusLabel,
                                style: TextStyle(
                                    color: ipo.statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${ipo.ticker}  ·  ${ipo.sector}',
                          style: TextStyle(color: subtextColor, fontSize: 13)),
                      const SizedBox(height: 16),
                      Text(ipo.summary,
                          style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4)),
                      const SizedBox(height: 20),
                      Text('Highlights',
                          style: TextStyle(
                              color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...ipo.highlights.map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle,
                                    color: accentColor, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(h,
                                      style:
                                          TextStyle(color: textColor, fontSize: 13)),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            _row('Opens', _formatFullDate(ipo.openDate), textColor, subtextColor),
                            const SizedBox(height: 8),
                            _row('Closes', _formatFullDate(ipo.closeDate), textColor, subtextColor),
                            const SizedBox(height: 8),
                            _row('Expected listing', _formatFullDate(ipo.listingDate),
                                textColor, subtextColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ipo.isBiddable ? accentColor : Colors.grey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: ipo.isBiddable
                              ? () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => IpoBidScreen(ipo: ipo)),
                                  );
                                }
                              : null,
                          child: Text(
                            ipo.isBiddable ? 'BID NOW' : 'APPLICATIONS CLOSED',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _row(String label, String value, Color textColor, Color subtextColor) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: subtextColor, fontSize: 13)),
      Text(value, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
    ],
  );
}

String _formatFullDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
