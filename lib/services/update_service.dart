import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/app_theme.dart';
import 'log_service.dart';

/// Sumber sinyal remote (gratis, tanpa backend):
/// - control.json (kill switch / minimal versi) di GitHub raw.
/// - releases/latest (deteksi versi baru + URL APK) via GitHub API.
const String _kControlUrl =
    'https://raw.githubusercontent.com/alfarabiki/Time-Tracks/main/control.json';
const String _kLatestApi =
    'https://api.github.com/repos/alfarabiki/Time-Tracks/releases/latest';

enum UpdateAction { none, optional, forced, killed }

class UpdateInfo {
  final UpdateAction action;
  final String currentVersion;
  final String? latestVersion;
  final String? apkUrl;
  final String message;

  const UpdateInfo({
    required this.action,
    required this.currentVersion,
    this.latestVersion,
    this.apkUrl,
    this.message = '',
  });
}

/// Auto-update (dari GitHub Releases) + kill switch / paksa-update (control.json).
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  bool _gateShownThisSession = false;

  /// Bandingkan versi semantik. >0 jika [a] lebih baru dari [b], 0 sama, <0 lebih lama.
  /// Toleran prefix "v" dan karakter non-angka (mis. "v1.3.0" / "1.3.0+5").
  static int compareVersion(String a, String b) {
    List<int> parse(String s) {
      final cleaned = s.toLowerCase().split('+').first;
      final parts = cleaned.split('.');
      return List<int>.generate(3, (i) {
        if (i >= parts.length) return 0;
        final digits = RegExp(r'\d+').firstMatch(parts[i])?.group(0);
        return int.tryParse(digits ?? '0') ?? 0;
      });
    }

    final pa = parse(a);
    final pb = parse(b);
    for (var i = 0; i < 3; i++) {
      if (pa[i] != pb[i]) return pa[i] > pb[i] ? 1 : -1;
    }
    return 0;
  }

  /// Cek status app vs sinyal remote. Aman saat offline (mengembalikan none).
  Future<UpdateInfo> check() async {
    final pkg = await PackageInfo.fromPlatform();
    final current = pkg.version; // versionName, mis. "1.2.2"

    // 1) control.json — kill switch & versi minimal (best effort).
    bool killed = false;
    String killMessage = 'Aplikasi dinonaktifkan sementara. Hubungi admin.';
    String minVersion = '0.0.0';
    String forceMessage =
        'Versi ini sudah tidak didukung. Silakan update untuk melanjutkan.';
    try {
      final r = await http
          .get(Uri.parse(_kControlUrl))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        killed = (j['killed'] ?? false) == true;
        killMessage = (j['killMessage'] ?? killMessage).toString();
        minVersion = (j['minVersionName'] ?? minVersion).toString();
        forceMessage = (j['forceUpdateMessage'] ?? forceMessage).toString();
      }
    } catch (_) {/* offline / file tidak ada: jangan blokir user */}

    // 2) releases/latest — versi terbaru + URL APK (best effort).
    String? latest;
    String? apkUrl;
    String notes = '';
    try {
      final r = await http.get(
        Uri.parse(_kLatestApi),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        latest = (j['tag_name'] ?? '').toString();
        notes = (j['body'] ?? '').toString();
        apkUrl = _pickApkUrl((j['assets'] as List?) ?? const []);
      }
    } catch (_) {/* offline */}

    if (killed) {
      return UpdateInfo(
        action: UpdateAction.killed,
        currentVersion: current,
        message: killMessage,
      );
    }
    if (compareVersion(current, minVersion) < 0 && apkUrl != null) {
      return UpdateInfo(
        action: UpdateAction.forced,
        currentVersion: current,
        latestVersion: latest,
        apkUrl: apkUrl,
        message: forceMessage,
      );
    }
    if (latest != null &&
        apkUrl != null &&
        compareVersion(latest, current) > 0) {
      return UpdateInfo(
        action: UpdateAction.optional,
        currentVersion: current,
        latestVersion: latest,
        apkUrl: apkUrl,
        message: notes,
      );
    }
    return UpdateInfo(
      action: UpdateAction.none,
      currentVersion: current,
      latestVersion: latest,
    );
  }

  /// Pilih APK universal (cocok semua arsitektur); fallback arm64.
  String? _pickApkUrl(List<dynamic> assets) {
    String? urlFor(String part) {
      for (final a in assets) {
        final name = (a['name'] ?? '').toString();
        if (name.contains(part)) {
          return (a['browser_download_url'] ?? '').toString();
        }
      }
      return null;
    }

    return urlFor('universal') ?? urlFor('arm64-v8a');
  }

  /// Jalankan "gerbang" pengecekan saat app dibuka (sekali per sesi).
  Future<void> runGate(BuildContext context) async {
    if (_gateShownThisSession) return;
    _gateShownThisSession = true;

    UpdateInfo info;
    try {
      info = await check();
    } catch (_) {
      return;
    }
    await LogService.instance.log(
      'Update Check',
      detail:
          '${info.action.name} cur=${info.currentVersion} latest=${info.latestVersion ?? "-"} apk=${info.apkUrl != null}',
    );
    if (!context.mounted) return;

    switch (info.action) {
      case UpdateAction.killed:
        await _showBlocking(context, info,
            title: 'Aplikasi dinonaktifkan', allowUpdate: false);
        break;
      case UpdateAction.forced:
        await _showBlocking(context, info,
            title: 'Wajib update', allowUpdate: true);
        break;
      case UpdateAction.optional:
        await _showOptional(context, info);
        break;
      case UpdateAction.none:
        break;
    }
  }

  Future<void> _showOptional(BuildContext context, UpdateInfo info) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Versi baru ${info.latestVersion ?? ''} tersedia'),
        content: SingleChildScrollView(
          child: Text(
            _trimNotes(info.message),
            style: const TextStyle(height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              if (info.apkUrl != null) _startDownload(context, info.apkUrl!);
            },
            icon: const Icon(Icons.system_update),
            label: const Text('Update sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBlocking(
    BuildContext context,
    UpdateInfo info, {
    required String title,
    required bool allowUpdate,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(title),
          content: Text(info.message, style: const TextStyle(height: 1.4)),
          actions: [
            if (allowUpdate && info.apkUrl != null)
              ElevatedButton.icon(
                onPressed: () => _startDownload(context, info.apkUrl!),
                icon: const Icon(Icons.system_update),
                label: const Text('Update sekarang'),
              )
            else
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Keluar'),
              ),
          ],
        ),
      ),
    );
  }

  /// Unduh APK (dengan progress) lalu buka installer Android.
  Future<void> _startDownload(BuildContext context, String url) async {
    final progress = ValueNotifier<double>(0);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Mengunduh pembaruan...'),
          content: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, v, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: v > 0 ? v : null,
                  color: AppTheme.accent,
                  backgroundColor: Colors.white12,
                ),
                const SizedBox(height: 12),
                Text(v > 0 ? '${(v * 100).toStringAsFixed(0)}%' : 'Menyiapkan...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final file = await _download(url, (p) => progress.value = p);
      await LogService.instance.log('Update Downloaded', detail: file.path);
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // tutup progress
      }
      final res = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      await LogService.instance.log('Update Install Intent', detail: res.message);
    } catch (e) {
      await LogService.instance.log('Update Failed', detail: e.toString());
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showAppMessage(
          context,
          'Gagal mengunduh pembaruan. Periksa koneksi & coba lagi.',
          error: true,
        );
      }
    } finally {
      progress.dispose();
    }
  }

  Future<File> _download(String url, void Function(double) onProgress) async {
    final dir =
        await getExternalStorageDirectory() ?? await getTemporaryDirectory();
    final file = File('${dir.path}/timeproof-update.apk');
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
    final client = http.Client();
    try {
      final resp = await client.send(http.Request('GET', Uri.parse(url)));
      final total = resp.contentLength ?? 0;
      final sink = file.openWrite();
      var received = 0;
      await for (final chunk in resp.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) onProgress(received / total);
      }
      await sink.flush();
      await sink.close();
      return file;
    } finally {
      client.close();
    }
  }

  String _trimNotes(String notes) {
    final lines = notes
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#') && !l.startsWith('>'))
        .take(6)
        .toList();
    final text = lines.join('\n');
    return text.isEmpty ? 'Perbaikan & peningkatan tersedia.' : text;
  }
}
