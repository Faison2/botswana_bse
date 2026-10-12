import 'package:flutter/material.dart';

/// Status of an IPO relative to its subscription window.
enum IpoStatus { upcoming, open, closingSoon, closed }

class IpoListing {
  final String id;
  final String companyName;
  final String ticker;
  final String sector;
  final String logoUrl;
  final Color accentColor;
  final double pricePerShare;
  final int minShares;
  final int maxShares;
  final double sharesOnOffer;
  final double sharesSubscribed;
  final DateTime openDate;
  final DateTime closeDate;
  final DateTime listingDate;
  final String summary;
  final List<String> highlights;
  final IpoStatus status;

  const IpoListing({
    required this.id,
    required this.companyName,
    required this.ticker,
    required this.sector,
    required this.logoUrl,
    required this.accentColor,
    required this.pricePerShare,
    required this.minShares,
    required this.maxShares,
    required this.sharesOnOffer,
    required this.sharesSubscribed,
    required this.openDate,
    required this.closeDate,
    required this.listingDate,
    required this.summary,
    required this.highlights,
    required this.status,
  });

  double get subscriptionPercent =>
      sharesOnOffer <= 0 ? 0 : (sharesSubscribed / sharesOnOffer).clamp(0, 1.0) * 100;

  bool get isBiddable => status == IpoStatus.open || status == IpoStatus.closingSoon;

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(closeDate)) return 0;
    return closeDate.difference(now).inDays;
  }

  String get statusLabel {
    switch (status) {
      case IpoStatus.upcoming:
        return 'UPCOMING';
      case IpoStatus.open:
        return 'OPEN';
      case IpoStatus.closingSoon:
        return 'CLOSING SOON';
      case IpoStatus.closed:
        return 'CLOSED';
    }
  }

  Color get statusColor {
    switch (status) {
      case IpoStatus.upcoming:
        return const Color(0xFF42A5F5);
      case IpoStatus.open:
        return const Color(0xFF26A69A);
      case IpoStatus.closingSoon:
        return const Color(0xFFFFA726);
      case IpoStatus.closed:
        return Colors.grey;
    }
  }
}

/// Mock IPO pipeline — stand-in for a future `GetIpoListings` API call.
/// Swap [IpoRepository.fetchListings] for a real HTTP call once the
/// backend endpoint exists; everything downstream already expects a
/// `Future<List<IpoListing>>`.
class IpoRepository {
  static List<IpoListing> _mockListings() {
    final now = DateTime.now();
    return [
      IpoListing(
        id: 'ipo-kgalagadi-2026',
        companyName: 'Kgalagadi Resources Ltd',
        ticker: 'KGRL',
        sector: 'Mining & Resources',
        logoUrl: '',
        accentColor: const Color(0xFF8B6914),
        pricePerShare: 4.25,
        minShares: 500,
        maxShares: 50000,
        sharesOnOffer: 40000000,
        sharesSubscribed: 26800000,
        openDate: now.subtract(const Duration(days: 4)),
        closeDate: now.add(const Duration(days: 3)),
        listingDate: now.add(const Duration(days: 17)),
        summary:
            'Kgalagadi Resources is offering 40,000,000 ordinary shares to the public '
            'ahead of its primary listing on the BSE Main Board, raising capital to '
            'fund expansion of its Jwaneng-area exploration assets.',
        highlights: const [
          'Offer price: BWP 4.25 per share',
          'Minimum application: 500 shares (BWP 2,125.00)',
          'Oversubscription allowed up to 50,000 shares per applicant',
          'Expected listing date within 3 weeks of close',
        ],
        status: IpoStatus.open,
      ),
      IpoListing(
        id: 'ipo-mascom-followon-2026',
        companyName: 'Mascom Wireless Botswana',
        ticker: 'MASC',
        sector: 'Telecommunications',
        logoUrl: '',
        accentColor: const Color(0xFF2F3A4A),
        pricePerShare: 2.80,
        minShares: 1000,
        maxShares: 100000,
        sharesOnOffer: 60000000,
        sharesSubscribed: 9500000,
        openDate: now.add(const Duration(days: 10)),
        closeDate: now.add(const Duration(days: 24)),
        listingDate: now.add(const Duration(days: 35)),
        summary:
            'A follow-on public offer of 60,000,000 shares by Mascom Wireless '
            'Botswana, widening local ownership ahead of its network expansion programme.',
        highlights: const [
          'Offer price: BWP 2.80 per share',
          'Minimum application: 1,000 shares (BWP 2,800.00)',
          'Priority allocation for existing CDS account holders',
        ],
        status: IpoStatus.upcoming,
      ),
      IpoListing(
        id: 'ipo-botshelo-2025',
        companyName: 'Botshelo Health Group',
        ticker: 'BHLG',
        sector: 'Healthcare',
        logoUrl: '',
        accentColor: const Color(0xFF4A2F2F),
        pricePerShare: 1.95,
        minShares: 500,
        maxShares: 30000,
        sharesOnOffer: 15000000,
        sharesSubscribed: 15000000,
        openDate: now.subtract(const Duration(days: 40)),
        closeDate: now.subtract(const Duration(days: 12)),
        listingDate: now.subtract(const Duration(days: 2)),
        summary:
            'Botshelo Health Group\'s offer closed fully subscribed and the counter '
            'is now trading on the BSE Main Board.',
        highlights: const [
          'Offer price: BWP 1.95 per share',
          'Fully subscribed — 15,000,000 shares allotted',
          'Now listed and trading on the BSE Main Board',
        ],
        status: IpoStatus.closed,
      ),
    ];
  }

  /// Simulates a network round-trip so the UI can show its loading state.
  static Future<List<IpoListing>> fetchListings() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final listings = _mockListings();

    // Promote OPEN listings closing within 5 days to "closing soon".
    return listings.map((l) {
      if (l.status == IpoStatus.open && l.daysRemaining <= 5) {
        return IpoListing(
          id: l.id,
          companyName: l.companyName,
          ticker: l.ticker,
          sector: l.sector,
          logoUrl: l.logoUrl,
          accentColor: l.accentColor,
          pricePerShare: l.pricePerShare,
          minShares: l.minShares,
          maxShares: l.maxShares,
          sharesOnOffer: l.sharesOnOffer,
          sharesSubscribed: l.sharesSubscribed,
          openDate: l.openDate,
          closeDate: l.closeDate,
          listingDate: l.listingDate,
          summary: l.summary,
          highlights: l.highlights,
          status: IpoStatus.closingSoon,
        );
      }
      return l;
    }).toList();
  }

  static Future<IpoListing?> fetchFeaturedListing() async {
    final listings = await fetchListings();
    for (final l in listings) {
      if (l.isBiddable) return l;
    }
    return null;
  }
}
