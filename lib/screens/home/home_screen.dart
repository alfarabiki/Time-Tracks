import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/photo_record.dart';
import '../../services/database_service.dart';
import '../../services/settings_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxe/stat_tile.dart';
import '../../widgets/luxe/primary_button.dart';
import '../../widgets/luxe/section_header.dart';
import '../../widgets/luxe/visit_tile.dart';
import '../start_visit/start_visit_screen.dart';
import '../history/photo_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _today = 0, _month = 0;
  List<PhotoRecord> _recent = const [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final today = await db.countToday();
    final month = await db.countThisMonth();
    final recent = await db.recent(3);
    if (!mounted) return;
    setState(() { _today = today; _month = month; _recent = recent; _loading = false; });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi,';
    if (h < 15) return 'Selamat siang,';
    if (h < 19) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  Future<void> _startVisit() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StartVisitScreen()));
    _load();
  }

  bool _isToday(DateTime t) { final n = DateTime.now(); return t.year==n.year && t.month==n.month && t.day==n.day; }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'M';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0,1) + parts.last.substring(0,1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final staff = SettingsService.instance.current.staffName;
    final name = staff.isEmpty ? 'Marketing' : staff;
    final dateStr = DateFormat("EEEE, dd MMMM yyyy", 'id_ID').format(DateTime.now());
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(22, 8, 22, 24), children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Image.asset('assets/branding/radjak_logo.png', height: 30),
            Container(width: 42, height: 42, decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary])),
              child: Center(child: Text(_initials(name),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
          ]),
          const SizedBox(height: 22),
          Text(_greeting(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(name, style: const TextStyle(fontFamily: AppTheme.fontHeading, fontSize: 30, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1.1)),
          const SizedBox(height: 6),
          Text('$dateStr · Marketing Salemba', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: StatTile(value: '$_today', label: 'Kunjungan hari ini', icon: Icons.place_outlined)),
            const SizedBox(width: 14),
            Expanded(child: StatTile(value: '$_month', label: 'Total bulan ini', icon: Icons.bar_chart, gold: true)),
          ]),
          const SizedBox(height: 18),
          PrimaryGradientButton(title: 'Mulai Kunjungan', subtitle: 'Foto bukti + lokasi otomatis',
            icon: Icons.camera_alt_outlined, onTap: _startVisit),
          const SizedBox(height: 24),
          SectionHeader(title: 'Kunjungan Terakhir', actionLabel: _recent.isEmpty ? null : 'Lihat semua', onAction: () {}),
          const SizedBox(height: 12),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_recent.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 18),
            child: Text('Belum ada kunjungan. Tekan "Mulai Kunjungan".',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)))
          else ..._recent.map((r) => VisitTile(
            facility: r.facility.isEmpty ? 'Tanpa nama faskes' : r.facility,
            meta: '${DateFormat('HH:mm').format(r.timestamp)} · ${r.visitType.isEmpty ? "Kunjungan" : r.visitType}',
            trackingNumber: r.trackingNumber,
            chip: _isToday(r.timestamp) ? 'Hari ini' : '',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PhotoDetailScreen(record: r))),
          )),
        ]),
      ),
    );
  }
}
