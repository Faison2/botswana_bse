import 'package:bse/screens/auth/login/login.dart';
import 'package:bse/screens/splash_screen/spalsh_screen.dart';
import 'package:bse/screens/dashboard/dashboard.dart';
import 'package:bse/screens/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


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

class BSEApp extends StatefulWidget {
  const BSEApp({super.key});

  @override
  State<BSEApp> createState() => _BSEAppState();
}

class _BSEAppState extends State<BSEApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App is closing or going to background
      _performAutoLogout();
    }
  }

  Future<void> _performAutoLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isNotEmpty) {
        // Call logout API
        await http.post(
          Uri.parse('http://192.168.3.201/MainAPI/Authentication/Logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'Token': token}),
        ).timeout(const Duration(seconds: 10));
      }

      // Clear all data
      await prefs.clear();
      print('Auto logout performed');
    } catch (e) {
      print('Error during auto logout: $e');
      // Still clear preferences even if API fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}