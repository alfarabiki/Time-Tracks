import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'luxe_card.dart';

class StatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final bool gold;
  const StatTile({super.key, required this.value, required this.label,
    required this.icon, this.gold = false});
  @override
  Widget build(BuildContext context) {
    final tint = gold ? AppTheme.gold : AppTheme.primary;
    return LuxeCard(goldTop: gold, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 19, color: tint)),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontFamily: AppTheme.fontHeading,
          fontSize: 34, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1)),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500)),
      ],
    ));
  }
}
