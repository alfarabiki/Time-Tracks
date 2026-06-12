import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxe/luxe_bottom_nav.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _i = 0;
  late final List<Widget> _pages = [
    HomeScreen(onSeeAll: () => setState(() => _i = 1)),
    const HistoryScreen(),
    const SettingsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: LuxeBottomNav(index: _i, onChanged: (v) => setState(() => _i = v)),
    );
  }
}
