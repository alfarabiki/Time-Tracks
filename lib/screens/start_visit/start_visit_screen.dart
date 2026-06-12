import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../../utils/app_theme.dart';
import '../camera/camera_screen.dart';

const kVisitTypes = ['Sales Visit','Maintenance','Audit Internal','Follow-up','Survey','Lainnya'];

class StartVisitScreen extends StatefulWidget {
  const StartVisitScreen({super.key});
  @override
  State<StartVisitScreen> createState() => _StartVisitScreenState();
}

class _StartVisitScreenState extends State<StartVisitScreen> {
  final _facility = TextEditingController();
  String _type = kVisitTypes.first;

  @override
  void dispose() { _facility.dispose(); super.dispose(); }

  Future<void> _next() async {
    final staff = SettingsService.instance.current.staffName;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CameraScreen(
      facility: _facility.text.trim(), visitType: _type, staffName: staff)));
    if (mounted) Navigator.of(context).pop(); // kembali ke Home setelah alur kamera
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mulai Kunjungan')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(22), children: [
        const Text('Tujuan / Faskes', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(controller: _facility, decoration: _dec('mis. RS Mitra Keluarga')),
        const SizedBox(height: 18),
        const Text('Jenis Kunjungan', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(initialValue: _type, decoration: _dec(''),
          items: kVisitTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _type = v ?? _type)),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _next,
          icon: const Icon(Icons.camera_alt_outlined), label: const Text('Lanjut ke Kamera'))),
      ])),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(hintText: hint, filled: true,
    fillColor: AppTheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.line)));
}
