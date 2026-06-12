import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class VisitTile extends StatelessWidget {
  final String facility, meta, trackingNumber, chip;
  final VoidCallback? onTap;
  const VisitTile({super.key, required this.facility, required this.meta,
    required this.trackingNumber, this.chip = '', this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line)),
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(colors: [Color(0xFFEEF3FF), Color(0xFFDCE7FF)])),
          child: const Icon(Icons.local_hospital_outlined, size: 21, color: AppTheme.primary)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(facility, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(meta, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
          if (trackingNumber.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2),
            child: Text(trackingNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: Color(0xFFB8902A), letterSpacing: 0.3))),
        ])),
        if (chip.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7)),
          child: Text(chip, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary))),
      ]),
    ));
  }
}
