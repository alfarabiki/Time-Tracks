import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class PrimaryGradientButton extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const PrimaryGradientButton({super.key, required this.title, required this.subtitle,
    required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: Ink(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.34),
          blurRadius: 30, offset: const Offset(0, 16))]),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontFamily: AppTheme.fontHeading,
            color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        ])),
        Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35))),
          child: Icon(icon, color: Colors.white)),
      ]),
    ));
  }
}
