import 'dart:async';

import 'package:flutter/material.dart';
import 'package:i_tabung/app/app_home_router.dart';

class AppSplashGate extends StatefulWidget {
  const AppSplashGate({super.key});

  @override
  State<AppSplashGate> createState() => _AppSplashGateState();
}

class _AppSplashGateState extends State<AppSplashGate> {
  bool _showRouter = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _showRouter = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showRouter) {
      return const AppHomeRouter();
    }

    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Image(
          image: AssetImage('assets/images/auth/splash_screen.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
