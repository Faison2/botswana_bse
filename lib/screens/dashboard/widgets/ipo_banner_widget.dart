import 'package:flutter/material.dart';
import '../../ipo/ipo_bid_screen.dart';
import '../../ipo/ipo_market_watch.dart';
import '../../ipo/ipo_models.dart';

/// Promo banner spotlighting the current open/closing-soon IPO —
/// same gradient-card language as the dashboard's portfolio balance card.
class IpoBannerWidget extends StatefulWidget {
  final bool isDark;

  const IpoBannerWidget({super.key, required this.isDark});

  @override
  State<IpoBannerWidget> createState() => _IpoBannerWidgetState();
}

class _IpoBannerWidgetState extends State<IpoBannerWidget> {
  IpoListing? _featured;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final listing = await IpoRepository.fetchFeaturedListing();
    if (!mounted) return;
    setState(() {
      _featured = listing;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _featured == null) return const SizedBox.shrink();
    final ipo = _featured!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ipo.accentColor, ipo.accentColor.withOpacity(0.65)],
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ipo.status == IpoStatus.closingSoon ? 'IPO CLOSING SOON' : 'IPO NOW OPEN',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6),
                  ),
                ),
                Text('${ipo.daysRemaining}d left',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(ipo.companyName,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'BWP ${ipo.pricePerShare.toStringAsFixed(2)} / share  ·  min ${ipo.minShares} shares',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IpoMarketWatchScreen()),
                    ),
                    child: const Text('View All IPOs',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => IpoBidScreen(ipo: ipo)),
                    ),
                    child: Text('Bid Now',
                        style: TextStyle(
                            color: ipo.accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
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
