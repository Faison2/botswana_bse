// TEMPORARY preview harness — delete after visual check.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_provider.dart';
import 'screens/buy_sell/absa_deposit.dart';

// Flip to false to preview the light theme.
const bool kPreviewDark = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', kPreviewDark);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const _Preview(),
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AbsaDepositScreen(
        brokers: [
          {
            'brokerCode': 'MOTS',
            'brokerName': 'Motswedi Securities',
            'cdsAccount': 'MOTS-B/0610410-LI/00',
          },
          {
            'brokerCode': 'STOC',
            'brokerName': 'Stockbrokers Botswana',
            'cdsAccount': 'STOC-B/0610410-LI/00',
          },
        ],
      ),
    );
  }
}
