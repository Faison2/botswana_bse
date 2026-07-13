import 'dart:async';
import 'dart:math' as math;

import 'package:bse/screens/auth/login/login.dart';
import 'package:flutter/material.dart';

// ── BSE Brand Palette ──────────────────────────────────────────
class BSEColors {
  static const marigold = Color(0xFFC6912D);
  static const marigoldLight = Color(0xFFE8C88A);
  static const marigoldDark = Color(0xFFA97620);
  static const bearish = Color(0xFFB6673F);
  static const bearishLight = Color(0xFFE3B79A);
  static const ink = Color(0xFF2C2418);
  static const charcoal = Color(0xFF4A3F2E);
  static const muted = Color(0xFF8A7A5F);
  static const canvas = Color(0xFFFDF9F1);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Drives the live candlestick chart in the background
  late AnimationController _tickerController;
  late List<_CandleSpec> _candles;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Continuously looping "market" animation — never stops, feels alive
    _tickerController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _candles = _generateCandles(18);

    // Preload + fully decode the background image before it's shown,
    // so it never renders soft/blurry mid-decode during the fade-in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/splash.png'), context);
    });

    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  List<_CandleSpec> _generateCandles(int count) {
    final rnd = math.Random(7); // fixed seed = consistent look each launch
    return List.generate(count, (i) {
      return _CandleSpec(
        xFraction: i / count,
        baseHeight: 0.25 + rnd.nextDouble() * 0.35,
        amplitude: 0.10 + rnd.nextDouble() * 0.12,
        speed: 0.6 + rnd.nextDouble() * 0.9,
        phase: rnd.nextDouble() * math.pi * 2,
        bullish: rnd.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BSEColors.canvas,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Live, moving candlestick market backdrop
            Positioned.fill(
              child: CustomPaint(
                painter: CandlestickPainter(
                  animation: _tickerController,
                  candles: _candles,
                ),
              ),
            ),

            // Gentle light-wash so the logo/text area stays crisp
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      BSEColors.canvas.withOpacity(0.65),
                      BSEColors.canvas.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),

            // ── Header — logo, then Welcome text, pinned near the top ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // Animated logo
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: BSEColors.marigoldLight,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BSEColors.marigold.withOpacity(0.25),
                                      blurRadius: 30,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Gradient-filled headline for a premium feel
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  BSEColors.marigoldDark,
                                  BSEColors.marigold,
                                  BSEColors.marigoldLight,
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'Welcome To BSE',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white, // masked by gradient
                                  letterSpacing: 1.2,
                                  height: 1.1,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Divider-flanked subtitle for an "official" feel
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _HeaderDivider(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    'BOTSWANA STOCK EXCHANGE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: BSEColors.charcoal.withOpacity(0.75),
                                      letterSpacing: 2.4,
                                    ),
                                  ),
                                ),
                                _HeaderDivider(flipped: true),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Main content — splash image, centered below the header
            Align(
              alignment: const Alignment(0, 0.3),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.90,
                          maxHeight: MediaQuery.of(context).size.height * 0.55,
                        ),
                        child: Image.asset(
                          'assets/splash.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Dashed line loading indicator at bottom
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: const DashedLineLoader(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small gradient divider line flanking the header subtitle ─────
class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider({this.flipped = false});

  final bool flipped;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 1.4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: flipped ? Alignment.centerRight : Alignment.centerLeft,
          end: flipped ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            BSEColors.marigold.withOpacity(0.0),
            BSEColors.marigold.withOpacity(0.7),
          ],
        ),
      ),
    );
  }
}

// ── Pulsing three-dot loader ─────────────────────────────────────
class DashedLineLoader extends StatefulWidget {
  const DashedLineLoader({super.key});

  @override
  State<DashedLineLoader> createState() => _DashedLineLoaderState();
}

class _DashedLineLoaderState extends State<DashedLineLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.15;
            final animationValue = (_controller.value + delay) % 1.0;
            final scale = 0.5 + (math.sin(animationValue * math.pi) * 0.5);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: BSEColors.marigold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: BSEColors.marigold.withOpacity(0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Data model for one animated candle ───────────────────────────
class _CandleSpec {
  _CandleSpec({
    required this.xFraction,
    required this.baseHeight,
    required this.amplitude,
    required this.speed,
    required this.phase,
    required this.bullish,
  });

  final double xFraction; // horizontal slot, 0..1
  final double baseHeight; // resting body height, fraction of chart area
  final double amplitude; // how much it "breathes" up/down
  final double speed; // oscillation speed multiplier
  final double phase; // phase offset so candles don't all move in sync
  final bool bullish; // base color bias
}

// ── Live, moving candlestick chart painted behind the logo ───────
class CandlestickPainter extends CustomPainter {
  CandlestickPainter({required this.animation, required this.candles})
      : super(repaint: animation);

  final Animation<double> animation;
  final List<_CandleSpec> candles;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value; // loops 0 → 1 forever
    final spacing = size.width / candles.length;
    final scrollOffset = t * spacing; // slow continuous horizontal drift
    final chartCenterY = size.height * 0.34;

    final wickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final bodyPaint = Paint()..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final topPoints = <Offset>[];

    for (final c in candles) {
      // Horizontal drift with wraparound so the chart scrolls infinitely
      double x = (c.xFraction * size.width - scrollOffset) % size.width;
      if (x < 0) x += size.width;

      // Simulated live price motion
      final wave = math.sin(t * 2 * math.pi * c.speed + c.phase);
      final heightFraction = (c.baseHeight + wave * c.amplitude).clamp(0.10, 0.9);
      final height = size.height * heightFraction * 0.42;
      final yDrift = math.sin(t * 2 * math.pi * c.speed * 0.5 + c.phase) * 12;
      final y = chartCenterY + yDrift;

      // Occasionally flips bullish/bearish as the "price" crosses zero
      final bullish = wave >= 0 ? c.bullish : !c.bullish;
      final color = bullish ? BSEColors.marigold : BSEColors.bearish;
      final strength = 0.16 + wave.abs() * 0.14;

      final bodyRect = Rect.fromCenter(
        center: Offset(x, y),
        width: spacing * 0.42,
        height: height,
      );
      final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(3));

      // Soft drop shadow so the body reads clearly on the light backdrop
      shadowPaint.color = BSEColors.charcoal.withOpacity(0.06);
      canvas.drawRRect(bodyRRect.shift(const Offset(0, 3)), shadowPaint);

      bodyPaint.color = color.withOpacity(strength);
      canvas.drawRRect(bodyRRect, bodyPaint);

      wickPaint.color = color.withOpacity(strength * 1.6);
      canvas.drawLine(
        Offset(x, y - height / 2 - 16),
        Offset(x, y + height / 2 + 16),
        wickPaint,
      );

      topPoints.add(Offset(x, y - height / 2));
    }

    // Faint ticker line tracing across the candle tops
    topPoints.sort((a, b) => a.dx.compareTo(b.dx));
    if (topPoints.length > 1) {
      final path = Path()..moveTo(topPoints.first.dx, topPoints.first.dy);
      for (final p in topPoints.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      final linePaint = Paint()
        ..color = BSEColors.marigoldDark.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) => true;
}