import 'package:bse/screens/auth/login/login.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2C1810),
              const Color(0xFF1A1A1A),
              const Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background candlestick pattern
            Positioned.fill(
              child: CustomPaint(
                painter: CandlestickPainter(),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Welcome text with animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Welcome To BSE',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Subtitle
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'BOTSWANA STOCK EXCHANGE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber,
                            letterSpacing: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Loading indicator at bottom
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
                      child: const SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                      ),
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

// Custom painter for background candlestick pattern
class CandlestickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw green and red candlesticks with low opacity
    final candlesticks = [
      {'x': 0.15, 'height': 0.3, 'color': Colors.green},
      {'x': 0.25, 'height': 0.5, 'color': Colors.red},
      {'x': 0.35, 'height': 0.4, 'color': Colors.green},
      {'x': 0.45, 'height': 0.6, 'color': Colors.green},
      {'x': 0.55, 'height': 0.35, 'color': Colors.red},
      {'x': 0.65, 'height': 0.55, 'color': Colors.green},
      {'x': 0.75, 'height': 0.4, 'color': Colors.red},
      {'x': 0.85, 'height': 0.5, 'color': Colors.green},
    ];

    for (var candle in candlesticks) {
      paint.color = (candle['color'] as Color).withOpacity(0.1);

      final x = size.width * (candle['x'] as double);
      final height = size.height * (candle['height'] as double);
      final y = size.height * 0.3;

      // Draw candlestick body
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 15, y, 30, height),
          const Radius.circular(4),
        ),
        paint,
      );

      // Draw wick
      paint.strokeWidth = 2;
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x, y - 20),
        Offset(x, y + height + 20),
        paint,
      );
      paint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}