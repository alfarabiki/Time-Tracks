import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../camera/camera_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/icon/logo.png',
                width: 140,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bukti foto terverifikasi',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
