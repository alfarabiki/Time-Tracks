import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../models/capture_data.dart';
import '../../models/overlay_settings.dart';
import '../../services/draft_service.dart';
import '../../services/photo_save_service.dart';
import '../../services/settings_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../widgets/timemark_overlay.dart';

class PreviewScreen extends StatefulWidget {
  final CaptureData data;
  const PreviewScreen({super.key, required this.data});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  bool _loadingImage = true;
  bool _saving = false;
  double _aspect = 3 / 4; // w/h
  int _originalWidth = 1080;

  // Data & pengaturan yang bisa diedit (live) sebelum disimpan.
  late CaptureData _data;
  late OverlaySettings _settings;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _settings = SettingsService.instance.current;
    _decode();
  }

  Future<void> _decode() async {
    try {
      final bytes = await File(_data.rawImagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      if (!mounted) return;
      setState(() {
        _originalWidth = img.width;
        _aspect = img.width / img.height;
        _loadingImage = false;
      });
      img.dispose();
    } catch (_) {
      if (mounted) setState(() => _loadingImage = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('boundary null');

      final logicalWidth = boundary.size.width;
      var pixelRatio = logicalWidth > 0 ? (_originalWidth / logicalWidth) : 1.0;
      if (pixelRatio < 1.0) pixelRatio = 1.0;
      if (pixelRatio > 4.0) pixelRatio = 4.0;

      final ui.Image composited =
          await boundary.toImage(pixelRatio: pixelRatio);

      await PhotoSaveService.instance.finalize(
        composited: composited,
        data: _data,
        settings: _settings,
      );
      composited.dispose();
      await DraftService.instance.clear();

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on SaveException catch (e) {
      if (mounted) showAppMessage(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Foto gagal disimpan. Silakan coba lagi.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _retake() async {
    await DraftService.instance.clear();
    if (mounted) Navigator.of(context).pop(false);
  }

  // ===== Edit handlers =====

  Future<void> _editDateTime() async {
    final now = _data.timestamp;
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (!mounted) return;
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? now.hour,
      time?.minute ?? now.minute,
    );
    setState(() {
      _data = _data.copyWith(timestampMs: dt.millisecondsSinceEpoch);
    });
  }

  void _openEditor() {
    final addressCtrl = TextEditingController(text: _data.address);
    final customCtrl = TextEditingController(text: _settings.customText);
    final latCtrl = TextEditingController(text: _data.latitude.toString());
    final lngCtrl = TextEditingController(text: _data.longitude.toString());

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text('Ubah Data Overlay',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),

                    // Tanggal & waktu
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule, color: AppTheme.accent),
                      title: const Text('Tanggal & Waktu'),
                      subtitle: Text(FormatUtils.fullDate(_data.timestamp)),
                      trailing: const Icon(Icons.edit, size: 18),
                      onTap: () async {
                        await _editDateTime();
                        setSheet(() {});
                      },
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Alamat
                    _label('Alamat'),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 3,
                      minLines: 2,
                      decoration: _dec('Alamat lokasi'),
                      onChanged: (v) => setState(
                          () => _data = _data.copyWith(address: v)),
                    ),
                    const SizedBox(height: 14),

                    // Koordinat
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Latitude'),
                              TextField(
                                controller: latCtrl,
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true, signed: true),
                                decoration: _dec('-6.185037'),
                                onChanged: (v) {
                                  final d = double.tryParse(v);
                                  if (d != null) {
                                    setState(() => _data =
                                        _data.copyWith(latitude: d, locationAvailable: true));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Longitude'),
                              TextField(
                                controller: lngCtrl,
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true, signed: true),
                                decoration: _dec('106.863431'),
                                onChanged: (v) {
                                  final d = double.tryParse(v);
                                  if (d != null) {
                                    setState(() => _data =
                                        _data.copyWith(longitude: d, locationAvailable: true));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Custom text
                    _label('Custom Text'),
                    TextField(
                      controller: customCtrl,
                      decoration: _dec('mis. Sales Visit / Audit Internal'),
                      onChanged: (v) => setState(() => _settings =
                          _settings.copyWith(
                              customText: v, showCustomText: true)),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.check),
                        label: const Text('Selesai'),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: AppTheme.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Pratinjau'),
          actions: [
            TextButton.icon(
              onPressed: _saving ? null : _openEditor,
              icon: const Icon(Icons.edit, size: 18, color: AppTheme.accent),
              label: const Text('Ubah Data',
                  style: TextStyle(color: AppTheme.accent)),
            ),
          ],
        ),
        body: _loadingImage
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent))
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: RepaintBoundary(
                            key: _boundaryKey,
                            child: AspectRatio(
                              aspectRatio: _aspect,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(_data.rawImagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey.shade900,
                                      child: const Center(
                                        child: Icon(Icons.broken_image,
                                            color: Colors.white38, size: 48),
                                      ),
                                    ),
                                  ),
                                  TimemarkOverlay(
                                    data: _data,
                                    settings: _settings,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildActions(),
                ],
              ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app, size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              Text('Ketuk "Ubah Data" untuk edit tanggal, alamat, koordinat & teks',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _retake,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.replay),
                  label: const Text('Ambil Ulang'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.save_alt),
                  label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
