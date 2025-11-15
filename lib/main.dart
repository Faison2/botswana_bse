import 'package:bse/screens/splash_screen/spalsh_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar color
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const BSEApp());
}

class BSEApp extends StatelessWidget {
  const BSEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BSE - Botswana Stock Exchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}