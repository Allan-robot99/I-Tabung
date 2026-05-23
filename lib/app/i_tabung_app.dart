import 'package:flutter/material.dart';
import 'package:i_tabung/app/app_splash_gate.dart';

class ITabungApp extends StatelessWidget {
  const ITabungApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-Tabung',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C7D69)),
      ),
      home: const AppSplashGate(),
    );
  }
}
