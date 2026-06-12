import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Kartu kaca (glassmorphism) Light Luxe.
class LuxeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool goldTop;
  const LuxeCard({super.key, required this.child,
    this.padding = const EdgeInsets.all(18), this.goldTop = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.06),
          blurRadius: 24, offset: const Offset(0, 10))],
      ),
      foregroundDecoration: goldTop
        ? const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.gold, width: 2)),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)))
        : null,
      child: child,
    );
  }
}
