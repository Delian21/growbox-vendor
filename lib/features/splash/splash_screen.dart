import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How long the splash stays up even when startup is instant. The logo
/// animation below runs for 800ms, so it finishes inside this window and the
/// vendor is never waiting on it.
const Duration kSplashMinimumDuration = Duration(seconds: 1);

/// The real work a cold start has to finish before the first screen: opening
/// the preference store that the theme mode and the store profile are read
/// from. Everything else (products, orders, sales, notifications) is in-memory
/// mock data and auth is not persisted, so nothing else holds the app up.
Future<void> growboxStartupWork() async {
  await SharedPreferences.getInstance();
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.startup = growboxStartupWork,
    this.minimumDuration = kSplashMinimumDuration,
  });

  /// Real startup work. The splash leaves once this has finished AND
  /// [minimumDuration] has elapsed — whichever is later.
  final Future<void> Function() startup;

  /// Shortest time the splash is shown, so the logo animation is not cut off
  /// mid-flight on a fast start.
  final Duration minimumDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _left = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    _leaveWhenReady();
  }

  /// Leaves for the login screen once the minimum display time is up and the
  /// startup work has finished — never before, and never on a fixed wait that
  /// ignores how long the work actually took.
  Future<void> _leaveWhenReady() async {
    await Future.wait<void>([
      Future<void>.delayed(widget.minimumDuration),
      _runStartup(),
    ]);
    if (!mounted || _left) return;
    _left = true;
    context.go('/login');
  }

  /// Startup work must never trap the vendor on the splash: a failure here is
  /// logged and the app carries on to the login screen.
  Future<void> _runStartup() async {
    try {
      await widget.startup();
    } catch (e) {
      debugPrint('Startup work failed: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1B7A2B),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Image(
                  image: AssetImage('assets/images/growbox_logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
