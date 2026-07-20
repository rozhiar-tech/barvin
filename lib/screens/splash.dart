import 'dart:async';
import 'package:barvin/screens/update_required.dart';
import 'package:barvin/services/app_version_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:barvin/constants/app_constants.dart';

const Color splashBackground = AppColors.backgroundLight;

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOnline = true;
  bool _navigated = false;
  final AppVersionService _versionService = const AppVersionService();
  Timer? _navTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    Connectivity().checkConnectivity().then((result) {
      if (!mounted) return;
      setState(() => _isOnline = !result.contains(ConnectivityResult.none));
      if (_isOnline) _scheduleNavigation();
    });

    // If we started offline, come back to life the moment connectivity
    // returns instead of leaving the user stuck on this screen forever.
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      final online = !result.contains(ConnectivityResult.none);
      setState(() => _isOnline = online);
      if (online) _scheduleNavigation();
    });
  }

  void _scheduleNavigation() {
    if (_navigated) return;
    _navTimer?.cancel();
    _navTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isOnline) _handleNavigation();
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _connectivitySub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation() async {
    if (_navigated) return;
    _navigated = true;
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
