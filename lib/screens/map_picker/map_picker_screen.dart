import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../services/geocoding_service.dart';
import '../../services/location_service.dart';
import '../../services/log_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/format_utils.dart';

/// Hasil pemilihan lokasi manual.
class MapPickResult {
  final double lat;
  final double lng;
  final String address;
  const MapPickResult(this.lat, this.lng, this.address);
}

/// Satu hasil pencarian Nominatim.
typedef _SearchHit = ({String name, double lat, double lng});

/// Manual Location Picker (Feature 8) memakai OpenStreetMap via flutter_map.
/// TANPA API key. Bisa: ketik untuk cari lokasi, ketuk peta untuk taruh pin,
/// geser peta, atau masukkan koordinat manual.
class MapPickerScreen extends StatefulWidget {
  final MapPickResult? initial;
  const MapPickerScreen({super.key, this.initial});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _fallback = LatLng(-6.185037, 106.863431); // Jakarta

  final MapController _map = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng _center = _fallback;
  bool _resolving = false;
  bool _loading = true;
  bool _searching = false;
  List<_SearchHit> _results = const [];

  @override
  void initState() {
    super.initState();
    _initCenter();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initCenter() async {
    if (widget.initial != null) {
      _center = LatLng(widget.initial!.lat, widget.initial!.lng);
      if (mounted) setState(() => _loading = false);
      return;
    }
    final res = await LocationService.instance.getCurrent();
    if (res.ok) {
      _center = LatLng(res.position!.latitude, res.position!.longitude);
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Cari lokasi by nama via Nominatim (OSM) — gratis, tanpa API key.
  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _results = const [];
    });
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'jsonv2',
        'limit': '6',
        'accept-language': 'id',
      });
      final resp = await http.get(uri, headers: {
        'User-Agent': 'TimeProof/1.1 (com.timeproof.app)',
      }).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        final hits = <_SearchHit>[];
        for (final e in data) {
          final m = e as Map<String, dynamic>;
          final lat = double.tryParse('${m['lat']}');
          final lon = double.tryParse('${m['lon']}');
          final name = (m['display_name'] ?? '').toString();
          if (lat != null && lon != null && name.isNotEmpty) {
            hits.add((name: name, lat: lat, lng: lon));
          }
        }
        if (!mounted) return;
        setState(() => _results = hits);
        if (hits.isEmpty) {
          showAppMessage(context, 'Lokasi "$q" tidak ditemukan.');
        }
      } else {
        if (mounted) showAppMessage(context, 'Pencarian gagal. Coba lagi.');
      }
    } catch (e) {
      await LogService.instance.log('Search Failed', detail: e.toString());
      if (mounted) {
        showAppMessage(context,
            'Pencarian gagal (cek internet). Bisa ketuk peta atau koordinat manual.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _goTo(LatLng target, {double zoom = 17}) {
    _center = target;
    _map.move(target, zoom);
    setState(() => _results = const []);
  }

  Future<void> _confirm() async {
    setState(() => _resolving = true);
    String address = '';
    try {
      address = await GeocodingService.instance
          .getAddress(_center.latitude, _center.longitude);
    } catch (_) {/* offline → koordinat saja */}
    if (!mounted) return;
    Navigator.of(context).pop(
      MapPickResult(_center.latitude, _center.longitude, address),
    );
  }

  Future<void> _manualEntry() async {
    final latC = TextEditingController(text: _center.latitude.toString());
    final lngC = TextEditingController(text: _center.longitude.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Koordinat manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latC,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            TextField(
              controller: lngC,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Longitude'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OK')),
        ],
      ),
    );
    if (ok == true) {
      final lat = double.tryParse(latC.text.trim());
      final lng = double.tryParse(lngC.text.trim());
      if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
        _goTo(LatLng(lat, lng), zoom: _map.camera.zoom);
      } else if (mounted) {
        showAppMessage(context, 'Koordinat tidak valid.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          IconButton(
            tooltip: 'Koordinat manual',
            icon: const Icon(Icons.edit_location_alt_outlined),
            onPressed: _manualEntry,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 16,
                    minZoom: 3,
                    maxZoom: 19,
                    onPositionChanged: (camera, hasGesture) {
                      _center = camera.center;
                      if (hasGesture) setState(() {});
                    },
                    // Ketuk peta untuk menaruh pin (pointing).
                    onTap: (tapPos, latlng) => _goTo(latlng,
                        zoom: _map.camera.zoom),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.timeproof.app',
                      maxZoom: 19,
                    ),
                  ],
                ),
                // Pin tetap di tengah layar.
                const Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Icon(Icons.location_on,
                      color: AppTheme.accent, size: 48),
                ),

                // ===== Search bar + hasil =====
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: _searchArea(),
                ),

                // Tombol "lokasi saya"
                Positioned(
                  right: 14,
                  bottom: 140,
                  child: FloatingActionButton.small(
                    backgroundColor: AppTheme.surface,
                    onPressed: () async {
                      final res = await LocationService.instance.getCurrent();
                      if (res.ok && mounted) {
                        _goTo(
                            LatLng(res.position!.latitude,
                                res.position!.longitude),
                            zoom: 16);
                      }
                    },
                    child: const Icon(Icons.my_location, color: AppTheme.primary),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _bottomBar(),
                ),
              ],
            ),
    );
  }

  Widget _searchArea() {
    return Column(
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.surface,
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runSearch(),
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Cari alamat atau tempat...',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.accent)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward,
                          color: AppTheme.accent),
                      onPressed: _runSearch,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 8),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Colors.black12),
              itemBuilder: (ctx, i) {
                final r = _results[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined,
                      color: AppTheme.accent, size: 20),
                  title: Text(
                    r.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  onTap: () => _goTo(LatLng(r.lat, r.lng)),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _bottomBar() {
    return Container(
      color: Colors.black.withOpacity(0.72),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app, size: 13, color: Colors.white38),
              const SizedBox(width: 6),
              Text('Ketuk peta atau geser untuk memindahkan pin',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            FormatUtils.coordinates(_center.latitude, _center.longitude),
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resolving ? null : _confirm,
              icon: _resolving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.check),
              label: Text(_resolving ? 'Memproses...' : 'Gunakan Lokasi Ini'),
            ),
          ),
        ],
      ),
    );
  }
}
