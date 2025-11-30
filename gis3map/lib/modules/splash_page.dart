import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word3map/routes/routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  void _startSplash() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('userId') ?? "";

    Timer(const Duration(seconds: 2), () {
      if (saved.isEmpty) {
        Navigator.pushReplacementNamed(context, AppRoutes.LOGIN);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.HOME);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: MediaQuery.of(context).size.width * .45,
        ),
      ),
    );
  }
}
