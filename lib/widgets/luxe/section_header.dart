import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontFamily: AppTheme.fontHeading,
        fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      if (actionLabel != null) GestureDetector(onTap: onAction,
        child: Text(actionLabel!, style: const TextStyle(color: AppTheme.primary,
          fontSize: 12.5, fontWeight: FontWeight.w600))),
    ]);
  }
}
