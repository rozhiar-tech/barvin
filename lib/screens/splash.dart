import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

const Color primaryColor = Color(0xFF567765);

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
    // 1) set up your Lottie controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    // 2) check connectivity once
    Connectivity().checkConnectivity().then((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });

    // 3) schedule navigation, but only if we're still online
    Timer(const Duration(seconds: 3), () {
      if (mounted && _isOnline) {
        Navigator.pushReplacementNamed(context, '/main');
      }
      // else: do nothing, remain on splash
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // pick one of two Lottie animations based on connectivity
    final asset = _isOnline ? 'assets/splash.json' : 'assets/nointernet.json';

    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: _controller,
            curve: Curves.elasticOut,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 4) Lottie animation in place of icon
              SizedBox(
                width: 250,
                height: 250,
                child: Lottie.asset(
                  asset,
                  controller: _controller,
                  onLoaded: (composition) {
                    _controller.duration = composition.duration;
                    _controller.repeat();
                  },
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  'Barvin',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (!_isOnline) ...[
                const SizedBox(height: 12),
                Text(
                  'No internet connection',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
