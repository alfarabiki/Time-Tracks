import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../models/capture_data.dart';
import '../../models/overlay_settings.dart';
import '../../services/draft_service.dart';
import '../../services/photo_save_service.dart';
import '../../services/settings_service.dart';
import '../../services/tracking_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/timemark_overlay.dart';

class PreviewScreen extends StatefulWidget {
  final CaptureData data;
  const PreviewScreen({super.key, required this.data});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  // Rasio foto hasil dikunci 3:4 (potrait). Foto di-crop tengah (cover) ke 3:4.
  static const double _kAspect = 3 / 4; // w/h

  bool _loadingImage = true;
  bool _saving = false;
  int _originalWidth = 1080;

  // Data & pengaturan yang bisa diedit (live) sebelum disimpan.
  late CaptureData _data;
  late OverlaySettings _settings;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _settings = SettingsService.instance.current;
    if (_data.visitType.isEmpty) {
      _data = _data.copyWith(visitType: 'Sales Visit');
    }
    _decode();
    _assignTracking();
  }

  Future<void> _assignTracking() async {
    if (_data.trackingNumber.isNotEmpty) return; // draft sudah punya nomor
    final tn = await TrackingService.instance.next(_data.timestamp.year);
    if (!mounted) return;
    setState(() => _data = _data.copyWith(trackingNumber: tn));
  }

  Future<void> _decode() async {
    try {
      final bytes = await File(_data.rawImagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      if (!mounted) return;
      setState(() {
        // Basis resolusi: pakai sisi terbesar agar crop 3:4 tetap tajam.
        _originalWidth = img.width > img.height ? img.width : img.height;
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Pratinjau'),
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
                              aspectRatio: _kAspect,
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
              const Icon(Icons.lock_outline, size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              Text('Foto terkunci — data tidak dapat diubah (anti-pemalsuan).',
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
