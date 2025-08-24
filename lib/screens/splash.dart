import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

const Color splashBackground = Color(0xFFD3E4C4);

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    Connectivity().checkConnectivity().then((result) {
      setState(() => _isOnline = result != ConnectivityResult.none);
    });

    Timer(const Duration(seconds: 3), () {
      if (mounted && _isOnline) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = _isOnline ? 'assets/splash.json' : 'assets/nointernet.json';

    return Scaffold(
      backgroundColor: Color(0xffD3E4C4),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie animation with enlarged logo overlay

            SizedBox(
              width: 220,
              height: 220,
              child: Lottie.asset(
                asset,
                controller: _controller,
                onLoaded: (composition) {
                  _controller
                    ..duration = composition.duration
                    ..repeat();
                },
              ),
            ),
            if (!_isOnline) ...[
              const SizedBox(height: 24),
              Text(
                'No internet connection',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
