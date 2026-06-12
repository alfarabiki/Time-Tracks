import 'package:flutter/material.dart';

import '../../models/overlay_settings.dart';
import '../../services/log_service.dart';
import '../../services/settings_service.dart';
import '../../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late OverlaySettings _s;
  late final TextEditingController _customText;
  late final TextEditingController _employee;
  late final TextEditingController _brand;
  late final TextEditingController _verified;
  late final TextEditingController _staffName;

  @override
  void initState() {
    super.initState();
    _s = SettingsService.instance.current;
    _customText = TextEditingController(text: _s.customText);
    _employee = TextEditingController(text: _s.employeeName);
    _brand = TextEditingController(text: _s.brandName);
    _verified = TextEditingController(text: _s.verifiedLabel);
    _staffName = TextEditingController(text: _s.staffName);
  }

  @override
  void dispose() {
    _customText.dispose();
    _employee.dispose();
    _brand.dispose();
    _verified.dispose();
    _staffName.dispose();
    super.dispose();
  }

  Future<void> _update(OverlaySettings next) async {
    setState(() => _s = next);
    await SettingsService.instance.save(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Profil Marketing'),
          _textField(
            _staffName,
            hint: 'Nama Staf / Marketing',
            onChanged: (v) => _update(_s.copyWith(staffName: v)),
          ),
          const SizedBox(height: 16),

          _section('Template'),
          _templateSelector(),
          const SizedBox(height: 8),

          _section('Tampilkan pada Overlay'),
          _switchTile('Waktu', _s.showTime,
              (v) => _update(_s.copyWith(showTime: v))),
          _switchTile('Alamat', _s.showAddress,
              (v) => _update(_s.copyWith(showAddress: v))),
          _switchTile('Koordinat', _s.showCoordinate,
              (v) => _update(_s.copyWith(showCoordinate: v))),
          _switchTile('Kode Verifikasi', _s.showVerification,
              (v) => _update(_s.copyWith(showVerification: v))),
          _switchTile('Custom Text', _s.showCustomText,
              (v) => _update(_s.copyWith(showCustomText: v))),
          _switchTile('Header Radjak (atas foto)', _s.showHeader,
              (v) => _update(_s.copyWith(showHeader: v))),
          _switchTile('Info Kunjungan (staf · jenis · faskes)',
              _s.showVisitInfo,
              (v) => _update(_s.copyWith(showVisitInfo: v))),

          const SizedBox(height: 16),
          _section('Custom Text'),
          _textField(
            _customText,
            hint: 'mis. Sales Visit / Maintenance Site / Audit Internal',
            onChanged: (v) => _update(_s.copyWith(customText: v)),
          ),

          if (_s.template == OverlayTemplate.b) ...[
            const SizedBox(height: 16),
            _section('Nama Pegawai (Template B)'),
            _textField(
              _employee,
              hint: 'Nama pegawai',
              onChanged: (v) => _update(_s.copyWith(employeeName: v)),
            ),
          ],

          const SizedBox(height: 16),
          _section('Kualitas Gambar'),
          _qualitySelector(),

          const SizedBox(height: 16),
          _section('Ukuran Teks Info (tanggal, alamat, dll)'),
          _fontSizeSelector(),

          const SizedBox(height: 16),
          _section("Ukuran Teks 'Verified' (kanan)"),
          _verifiedSizeSelector(),

          const SizedBox(height: 16),
          _section('Jenis Font Overlay'),
          _fontFamilySelector(),

          const SizedBox(height: 16),
          _section('Watermark (kanan-atas)'),
          _switchTile(
            'Remove Watermark',
            !_s.showWatermark,
            (v) => _update(_s.copyWith(showWatermark: !v)),
          ),
          const SizedBox(height: 8),
          _watermarkStyleSelector(),
          const SizedBox(height: 14),
          _section('Ukuran Watermark'),
          _brandSizeSelector(),

          const SizedBox(height: 16),
          _section('Branding Overlay'),
          _textField(
            _brand,
            hint: 'Nama brand (default: Timemark)',
            onChanged: (v) => _update(_s.copyWith(brandName: v)),
          ),
          const SizedBox(height: 10),
          _textField(
            _verified,
            hint: 'Label verified (default: Timemark Verified)',
            onChanged: (v) => _update(_s.copyWith(verifiedLabel: v)),
          ),

          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.article_outlined, color: AppTheme.textSecondary),
            title: const Text('Lihat Log Internal'),
            subtitle: const Text('Riwayat aktivitas 30 hari (troubleshooting)'),
            onTap: _showLogs,
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.accent,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      );

  Widget _templateSelector() {
    final options = {
      OverlayTemplate.a: 'A — Tanggal, Alamat, Koordinat, Kode (default)',
      OverlayTemplate.b: 'B — Tanggal, Nama Pegawai, Lokasi, Koordinat',
      OverlayTemplate.c: 'C — Custom (ikuti toggle di atas)',
    };
    return Column(
      children: options.entries.map((e) {
        return RadioListTile<OverlayTemplate>(
          value: e.key,
          groupValue: _s.template,
          activeColor: AppTheme.accent,
          title: Text(e.value, style: const TextStyle(fontSize: 14)),
          onChanged: (v) {
            if (v != null) _update(_s.copyWith(template: v));
          },
        );
      }).toList(),
    );
  }

  Widget _qualitySelector() {
    return SegmentedButton<ImageQuality>(
      segments: const [
        ButtonSegment(value: ImageQuality.high, label: Text('High 95%')),
        ButtonSegment(value: ImageQuality.medium, label: Text('Medium 90%')),
        ButtonSegment(value: ImageQuality.low, label: Text('Low 80%')),
      ],
      selected: {_s.imageQuality},
      onSelectionChanged: (sel) =>
          _update(_s.copyWith(imageQuality: sel.first)),
    );
  }

  Widget _fontSizeSelector() {
    return SegmentedButton<FontSizeOption>(
      segments: FontSizeOption.values
          .map((f) => ButtonSegment(value: f, label: Text(f.label)))
          .toList(),
      selected: {_s.fontSize},
      showSelectedIcon: false,
      onSelectionChanged: (sel) => _update(_s.copyWith(fontSize: sel.first)),
    );
  }

  Widget _verifiedSizeSelector() {
    return SegmentedButton<FontSizeOption>(
      segments: FontSizeOption.values
          .map((f) => ButtonSegment(value: f, label: Text(f.label)))
          .toList(),
      selected: {_s.verifiedSize},
      showSelectedIcon: false,
      onSelectionChanged: (sel) => _update(_s.copyWith(verifiedSize: sel.first)),
    );
  }

  Widget _brandSizeSelector() {
    return SegmentedButton<FontSizeOption>(
      segments: FontSizeOption.values
          .map((f) => ButtonSegment(value: f, label: Text(f.label)))
          .toList(),
      selected: {_s.brandSize},
      showSelectedIcon: false,
      onSelectionChanged: (sel) => _update(_s.copyWith(brandSize: sel.first)),
    );
  }

  Widget _watermarkStyleSelector() {
    return Column(
      children: WatermarkStyle.values.map((w) {
        return RadioListTile<WatermarkStyle>(
          value: w,
          groupValue: _s.watermarkStyle,
          activeColor: AppTheme.accent,
          contentPadding: EdgeInsets.zero,
          title: Text(w.optionLabel, style: const TextStyle(fontSize: 14)),
          subtitle: Text('Sub-label: "${w.sublabel}"',
              style: const TextStyle(fontSize: 12)),
          onChanged: (v) {
            if (v != null) _update(_s.copyWith(watermarkStyle: v));
          },
        );
      }).toList(),
    );
  }

  Widget _fontFamilySelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kOverlayFonts.map((f) {
        final selected = _s.fontFamily == f;
        return ChoiceChip(
          selected: selected,
          showCheckmark: false,
          selectedColor: AppTheme.accent,
          backgroundColor: AppTheme.surface,
          label: Text(
            f,
            style: TextStyle(
              fontFamily: f,
              fontSize: 16,
              color: selected ? Colors.black : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          onSelected: (_) => _update(_s.copyWith(fontFamily: f)),
        );
      }).toList(),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      activeColor: AppTheme.accent,
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

  Widget _textField(
    TextEditingController c, {
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: c,
      onChanged: onChanged,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _showLogs() async {
    final logs = await LogService.instance.readAll();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Log Internal'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              logs.isEmpty ? 'Belum ada log.' : logs,
              style: const TextStyle(fontSize: 11, height: 1.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
