import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/capture_data.dart';
import '../../services/draft_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/location_service.dart';
import '../../services/log_service.dart';
import '../../services/storage_service.dart';
import '../../services/update_service.dart';
import '../../services/verification_service.dart';
import '../../utils/app_theme.dart';
import '../history/history_screen.dart';
import '../preview/preview_screen.dart';
import '../settings/settings_screen.dart';

class CameraScreen extends StatefulWidget {
  final String facility;
  final String visitType;
  final String staffName;

  const CameraScreen({
    super.key,
    this.facility = '',
    this.visitType = '',
    this.staffName = '',
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  String? _initError;
  bool _busy = false;

  List<CameraDescription> _cameras = const [];
  CameraDescription? _current;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _setup() async {
    await _initCamera();
    if (!mounted) return;
    _checkStorage();
    _checkDraft();
    // Cek pembaruan / kill switch (sekali per sesi, aman saat offline).
    UpdateService.instance.runGate(context);
  }

  Future<void> _initCamera({CameraDescription? camera}) async {
    setState(() {
      _initializing = true;
      _initError = null;
    });
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _initializing = false;
          _initError = 'Izin kamera ditolak.\nBerikan izin kamera untuk melanjutkan.';
        });
        return;
      }

      final cameras = await availableCameras();
      _cameras = cameras;
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _initError = 'Kamera tidak ditemukan pada perangkat ini.';
        });
        return;
      }

      final chosen = camera ??
          _current ??
          cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );
      _current = chosen;

      final controller = CameraController(
        chosen,
        ResolutionPreset.veryHigh, // 1080p minimum (Quality > Image Quality)
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
      await LogService.instance.log('Camera Ready');
    } on CameraException catch (e) {
      await LogService.instance.log('Camera Init Failed', detail: e.code);
      setState(() {
        _initializing = false;
        _initError = 'Kamera gagal terbuka.\nTutup aplikasi lain yang memakai kamera, lalu coba lagi.';
      });
    } catch (e) {
      setState(() {
        _initializing = false;
        _initError = 'Kamera gagal terbuka. Silakan coba lagi.';
      });
    }
  }

  Future<void> _flipCamera() async {
    if (_busy || _initializing || _cameras.length < 2) return;
    final cur = _current;
    CameraDescription next;
    if (cur != null) {
      next = _cameras.firstWhere(
        (c) => c.lensDirection != cur.lensDirection,
        orElse: () =>
            _cameras[(_cameras.indexOf(cur) + 1) % _cameras.length],
      );
    } else {
      next = _cameras.first;
    }
    await _controller?.dispose();
    _controller = null;
    await _initCamera(camera: next);
  }

  Future<void> _checkStorage() async {
    final low = await StorageService.instance.isLow();
    if (low && mounted) {
      showAppMessage(
        context,
        'Penyimpanan hampir penuh (< 500 MB). Kosongkan ruang agar foto tetap tersimpan.',
        error: true,
      );
    }
  }

  Future<void> _checkDraft() async {
    final draft = await DraftService.instance.load();
    if (draft == null || !mounted) return;
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Lanjutkan foto sebelumnya?'),
        content: const Text(
          'Ada foto yang belum selesai disimpan. Lanjutkan ke pratinjau?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Buang'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resume == true) {
      _openPreview(draft);
    } else {
      await DraftService.instance.clear();
    }
  }

  Future<void> _onShutter() async {
    final c = _controller;
    if (_busy || c == null || !c.value.isInitialized) return;
    setState(() => _busy = true);
    try {
      final shot = await c.takePicture();
      await LogService.instance.log('Photo Taken');

      final loc = await _resolveLocation();
      if (!mounted) return;

      final baseData = CaptureData(
        rawImagePath: shot.path,
        latitude: loc.lat,
        longitude: loc.lng,
        accuracy: loc.acc,
        address: loc.address,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        verificationCode: VerificationService.generate(),
        locationAvailable: loc.available,
      );
      final withVisit = baseData.copyWith(
        facility: widget.facility,
        visitType: widget.visitType,
      );
      await DraftService.instance.save(withVisit);
      await _openPreview(withVisit);
    } on CameraException catch (e) {
      await LogService.instance.log('Capture Failed', detail: e.code);
      if (mounted) {
        showAppMessage(context, 'Gagal mengambil foto. Silakan coba lagi.',
            error: true);
      }
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Gagal mengambil foto. Silakan coba lagi.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importFromGallery() async {
    if (_busy) return;
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (file == null || !mounted) return;
      setState(() => _busy = true);
      await LogService.instance.log('Photo Imported');

      final loc = await _resolveLocation();
      if (!mounted) return;

      final data = CaptureData(
        rawImagePath: file.path,
        latitude: loc.lat,
        longitude: loc.lng,
        accuracy: loc.acc,
        address: loc.address,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        verificationCode: VerificationService.generate(),
        locationAvailable: loc.available,
      );
      await DraftService.instance.save(data);
      await _openPreview(data);
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Gagal membuka galeri. Silakan coba lagi.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPreview(CaptureData data) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PreviewScreen(data: data)),
    );
    if (!mounted) return;
    if (saved == true) {
      showAppMessage(context, 'Foto berhasil disimpan ke galeri.');
    }
  }

  Future<_Loc> _resolveLocation() async {
    final res = await LocationService.instance.getCurrent();
    if (res.ok) {
      final pos = res.position!;
      final addr = await GeocodingService.instance.getAddress(
        pos.latitude,
        pos.longitude,
      );
      return _Loc(pos.latitude, pos.longitude, pos.accuracy, addr, true);
    }

    // Gagal → beri tahu pengguna, lanjut tanpa lokasi (tanpa freeze).
    if (mounted) {
      showAppMessage(context, res.message, error: true);
    }
    return const _Loc(0, 0, 0, '', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('TimeProof'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Import dari galeri',
            onPressed: _busy ? null : _importFromGallery,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Riwayat',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildPreviewArea()),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }
    if (_initError != null) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined,
                  size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                _initError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        ),
      );
    }

    final c = _controller!;
    // Pratinjau dikunci 3:4 (potrait) agar sama persis dengan hasil foto (WYSIWYG).
    return Center(
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: c.value.previewSize?.height ?? 1080,
                  height: c.value.previewSize?.width ?? 1920,
                  child: CameraPreview(c),
                ),
              ),
            ),
        if (_cameras.length >= 2)
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black.withOpacity(0.5),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.flip_camera_android, color: Colors.white),
                tooltip: 'Putar kamera (depan/belakang)',
                onPressed: _busy ? null : _flipCamera,
              ),
            ),
          ),
        if (_busy)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.accent),
                  SizedBox(height: 14),
                  Text('Memproses...',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final ready = _controller != null && _initError == null && !_initializing;
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 54),
          GestureDetector(
            onTap: ready && !_busy ? _onShutter : null,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ready ? Colors.white : Colors.white24,
                border: Border.all(color: AppTheme.accent, width: 4),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 32,
                color: ready ? Colors.black : Colors.white54,
              ),
            ),
          ),
          _circleButton(
            icon: Icons.tune,
            label: 'Template',
            onTap: !_busy
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
            ),
            child: Icon(icon,
                color: onTap == null ? Colors.white30 : Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

/// Hasil resolusi lokasi internal.
class _Loc {
  final double lat;
  final double lng;
  final double acc;
  final String address;
  final bool available;
  const _Loc(this.lat, this.lng, this.acc, this.address, this.available);
}
