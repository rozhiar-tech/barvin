import 'dart:async';
import 'package:barvin/screens/update_required.dart';
import 'package:barvin/services/app_version_service.dart';
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
  final AppVersionService _versionService = const AppVersionService();
  Timer? _navTimer;

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

    _navTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isOnline) {
        _handleNavigation();
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation() async {
    final status = await _versionService.checkVersion();
    if (!mounted) return;
    if (status.requiresUpdate) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UpdateRequiredScreen(status: status),
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/main');
    }
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
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
