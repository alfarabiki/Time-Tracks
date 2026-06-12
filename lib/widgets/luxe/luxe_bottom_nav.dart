import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class LuxeBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const LuxeBottomNav({super.key, required this.index, required this.onChanged});
  static const _items = [
    (Icons.home_outlined, 'Beranda'),
    (Icons.history, 'Riwayat'),
    (Icons.person_outline, 'Profil'),
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      height: 66,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.line),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.14),
          blurRadius: 30, offset: const Offset(0, 12))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final on = i == index;
          final c = on ? AppTheme.primary : AppTheme.textSecondary;
          return GestureDetector(onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(_items[i].$1, size: 22, color: c), const SizedBox(height: 4),
                Text(_items[i].$2, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: c))]));
        })),
    );
  }
}
