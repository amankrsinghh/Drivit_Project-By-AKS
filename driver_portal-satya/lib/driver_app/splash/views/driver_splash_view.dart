import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/notification_service.dart';

class DriverSplashView extends StatefulWidget {
  static String targetRoute = '/driver/login';

  const DriverSplashView({super.key});

  @override
  State<DriverSplashView> createState() => _DriverSplashViewState();
}

class _DriverSplashViewState extends State<DriverSplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    final ns = Get.isRegistered<NotificationService>() ? Get.find<NotificationService>() : null;
    final hasPending = ns?.pendingRideId != null;

    // Stay on splash screen for 3 seconds, or 300ms if opened from a notification
    Timer(Duration(milliseconds: hasPending ? 300 : 3000), () {
      Get.offAllNamed(DriverSplashView.targetRoute);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Drivit Drive',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8A00),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
