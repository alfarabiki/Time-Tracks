import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shell/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final Animation<double> _scale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic)));
  late final Animation<double> _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.40, curve: Curves.easeOut)));
  late final Animation<double> _shimmer = Tween(begin: -1.5, end: 2.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.9, curve: Curves.easeInOut)));
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _c.forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _go();
    });
  }

  void _go() {
    if (_gone || !mounted) return;
    _gone = true;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _go,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -0.15), radius: 1.0,
              colors: [Color(0xFFEAF1FF), Color(0xFFFFFFFF)], stops: [0, 0.62])),
          child: Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (ctx, _) => Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                      colors: const [Colors.transparent, Color(0x99D4AF37), Colors.transparent],
                      stops: const [0.0, 0.5, 1.0],
                      transform: _SlideGradient(_shimmer.value),
                    ).createShader(rect),
                    child: Image.asset('assets/branding/radjak_logo.png', width: 230),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double t;
  const _SlideGradient(this.t);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * t, 0, 0);
}
