import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/geocoding_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/format_utils.dart';

/// Hasil pemilihan lokasi manual.
class MapPickResult {
  final double lat;
  final double lng;
  final String address;
  const MapPickResult(this.lat, this.lng, this.address);
}

/// Manual Location Picker (Feature 8). Geser peta, pin tetap di tengah.
class MapPickerScreen extends StatefulWidget {
  final MapPickResult? initial;
  const MapPickerScreen({super.key, this.initial});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _fallback = LatLng(-6.185037, 106.863431); // Jakarta

  GoogleMapController? _map;
  LatLng _center = _fallback;
  bool _resolving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initCenter();
  }

  Future<void> _initCenter() async {
    if (widget.initial != null) {
      _center = LatLng(widget.initial!.lat, widget.initial!.lng);
      setState(() => _loading = false);
      return;
    }
    final res = await LocationService.instance.getCurrent();
    if (res.ok) {
      _center = LatLng(res.position!.latitude, res.position!.longitude);
    }
    if (mounted) setState(() => _loading = false);
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            TextField(
              controller: lngC,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
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
        setState(() => _center = LatLng(lat, lng));
        await _map?.animateCamera(CameraUpdate.newLatLng(_center));
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
                GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: _center, zoom: 16),
                  myLocationButtonEnabled: true,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (c) => _map = c,
                  onCameraMove: (pos) => _center = pos.target,
                  onCameraIdle: () => setState(() {}),
                ),
                // Pin tetap di tengah layar.
                const Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Icon(Icons.location_on,
                      color: AppTheme.accent, size: 48),
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

  Widget _bottomBar() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }
}
