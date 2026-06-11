# Radjak Marketing MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand the offline TimeProof app to "Radjak Marketing" — Radjak blue/gold theme, Radjak logo header on every photo, three visit fields (staff, facility, visit type), and a sequential tracking number `TP-YYYY-NNNNNN` — with no backend.

**Architecture:** Pure-Flutter, local-only. The photo overlay is a Flutter widget screenshotted via `RepaintBoundary` in `preview_screen.dart`, so the logo is just an `Image.asset` inside the overlay. New visit data flows `CaptureData`/`OverlaySettings` → overlay widget → `PhotoSaveService` → `PhotoRecord` (SQLite, migrated to v2). Tracking numbers come from a new local counter service.

**Tech Stack:** Flutter 3.x, Dart, sqflite, shared_preferences, image, crypto. Spec: `docs/superpowers/specs/2026-06-11-radjak-mvp-design.md`.

---

## File Structure

- **Create** `lib/services/tracking_service.dart` — sequential `TP-YYYY-NNNNNN` counter (testable core + persistence).
- **Create** `test/tracking_service_test.dart` — unit tests for format/increment/year-reset.
- **Create** `assets/branding/radjak_logo.png` — Radjak logo for overlay header + splash.
- **Modify** `lib/models/overlay_settings.dart` — add `staffName`, `showHeader`, `showVisitInfo`; default `showVerification=false`.
- **Modify** `lib/models/capture_data.dart` — add `facility`, `visitType`, `trackingNumber`.
- **Modify** `lib/models/photo_record.dart` — add `staffName`, `facility`, `visitType`, `trackingNumber`.
- **Modify** `lib/services/database_service.dart` — bump to v2, `onUpgrade` ALTER TABLE.
- **Modify** `lib/services/photo_save_service.dart` — persist new fields into `PhotoRecord`.
- **Modify** `lib/utils/app_theme.dart` — Radjak light blue/gold theme.
- **Modify** `lib/widgets/timemark_overlay.dart` — Layout B: Radjak header + visit-info line + tracking number.
- **Modify** `lib/screens/preview/preview_screen.dart` — assign tracking number; visit fields in the edit sheet.
- **Modify** `lib/screens/settings/settings_screen.dart` — staff name (profile), default visit type, header/visit toggles.
- **Modify** `lib/screens/history/history_screen.dart` + `photo_detail_screen.dart` — show new fields.
- **Modify** `lib/screens/splash/splash_screen.dart` — Radjak logo + name.
- **Modify** `pubspec.yaml` — register `assets/branding/`, bump version to `1.4.0`.
- **Modify** `android/app/src/main/AndroidManifest.xml` — `android:label="Radjak Marketing"`.
- **Modify** `test/overlay_golden_test.dart` — golden for Layout B.

---

## Task 1: TrackingService (sequential TP-YYYY-NNNNNN)

**Files:**
- Create: `lib/services/tracking_service.dart`
- Test: `test/tracking_service_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/tracking_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:timeproof/services/tracking_service.dart';

void main() {
  group('TrackingService.format', () {
    test('zero-pads to 6 digits with year', () {
      expect(TrackingService.format(2026, 17), 'TP-2026-000017');
      expect(TrackingService.format(2026, 1), 'TP-2026-000001');
      expect(TrackingService.format(2026, 123456), 'TP-2026-123456');
    });
  });

  group('TrackingService.nextSeq (pure increment)', () {
    test('first of a fresh year starts at 1', () {
      final r = TrackingService.nextSeq(storedYear: 0, storedSeq: 0, currentYear: 2026);
      expect(r.year, 2026);
      expect(r.seq, 1);
    });

    test('same year increments', () {
      final r = TrackingService.nextSeq(storedYear: 2026, storedSeq: 17, currentYear: 2026);
      expect(r.year, 2026);
      expect(r.seq, 18);
    });

    test('new year resets to 1', () {
      final r = TrackingService.nextSeq(storedYear: 2026, storedSeq: 999, currentYear: 2027);
      expect(r.year, 2027);
      expect(r.seq, 1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run (Windows PowerShell; flutter on PATH may need `$env:Path = "D:\flutter\bin;" + $env:Path`):
`flutter test test/tracking_service_test.dart`
Expected: FAIL — `tracking_service.dart` / `TrackingService` not found.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/services/tracking_service.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Hasil hitung urutan tracking (tahun + nomor urut).
class TrackingSeq {
  final int year;
  final int seq;
  const TrackingSeq(this.year, this.seq);
}

/// Nomor tracking lokal berurutan: TP-YYYY-NNNNNN.
/// Counter disimpan di shared_preferences, reset otomatis tiap tahun.
class TrackingService {
  TrackingService._();
  static final TrackingService instance = TrackingService._();

  static const String _kYear = 'tracking_year';
  static const String _kSeq = 'tracking_seq';

  /// Format nomor tracking final.
  static String format(int year, int seq) =>
      'TP-$year-${seq.toString().padLeft(6, '0')}';

  /// Inti murni (mudah dites): hitung urutan berikutnya.
  static TrackingSeq nextSeq({
    required int storedYear,
    required int storedSeq,
    required int currentYear,
  }) {
    if (storedYear != currentYear) return TrackingSeq(currentYear, 1);
    return TrackingSeq(currentYear, storedSeq + 1);
  }

  /// Ambil nomor tracking berikutnya & simpan counter. [year] dari timestamp foto.
  Future<String> next(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final storedYear = prefs.getInt(_kYear) ?? 0;
    final storedSeq = prefs.getInt(_kSeq) ?? 0;
    final r = nextSeq(storedYear: storedYear, storedSeq: storedSeq, currentYear: year);
    await prefs.setInt(_kYear, r.year);
    await prefs.setInt(_kSeq, r.seq);
    return format(r.year, r.seq);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/tracking_service_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/tracking_service.dart test/tracking_service_test.dart
git commit -m "feat: TrackingService nomor tracking TP-YYYY-NNNNNN berurutan"
```

---

## Task 2: Extend OverlaySettings (staffName, showHeader, showVisitInfo)

**Files:**
- Modify: `lib/models/overlay_settings.dart`

- [ ] **Step 1: Add three fields to the class**

In the field block (after `watchmarkStyle`/before constructor), add:

```dart
  /// Nama staf/marketing (profil) — muncul otomatis di overlay.
  final String staffName;

  /// Tampilkan header Radjak di atas foto.
  final bool showHeader;

  /// Tampilkan baris info kunjungan (staf · jenis · faskes).
  final bool showVisitInfo;
```

- [ ] **Step 2: Update the constructor defaults**

Add to the const constructor parameter list:

```dart
    this.staffName = '',
    this.showHeader = true,
    this.showVisitInfo = true,
```

Change the existing `showVerification` default from `true` to `false`:

```dart
    this.showVerification = false,
```

- [ ] **Step 3: Update `copyWith`**

Add params `String? staffName, bool? showHeader, bool? showVisitInfo,` and in the returned object:

```dart
      staffName: staffName ?? this.staffName,
      showHeader: showHeader ?? this.showHeader,
      showVisitInfo: showVisitInfo ?? this.showVisitInfo,
```

- [ ] **Step 4: Update `toJson`**

Add:

```dart
        'staffName': staffName,
        'showHeader': showHeader,
        'showVisitInfo': showVisitInfo,
```

- [ ] **Step 5: Update `fromJson` (fallback-safe)**

Add:

```dart
      staffName: (j['staffName'] ?? '') as String,
      showHeader: (j['showHeader'] ?? true) as bool,
      showVisitInfo: (j['showVisitInfo'] ?? true) as bool,
```

And change `showVerification` line to default false:

```dart
      showVerification: (j['showVerification'] ?? false) as bool,
```

- [ ] **Step 6: Verify it compiles**

Run: `flutter analyze lib/models/overlay_settings.dart`
Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add lib/models/overlay_settings.dart
git commit -m "feat: OverlaySettings tambah staffName + toggle header/visit-info; verifikasi default off"
```

---

## Task 3: Extend CaptureData (facility, visitType, trackingNumber)

**Files:**
- Modify: `lib/models/capture_data.dart`

- [ ] **Step 1: Add fields**

After `locationAvailable;` add:

```dart
  final String facility;
  final String visitType;
  final String trackingNumber;
```

- [ ] **Step 2: Update constructor**

Add to the const constructor:

```dart
    this.facility = '',
    this.visitType = '',
    this.trackingNumber = '',
```

(These are optional with defaults so existing call sites still compile.)

- [ ] **Step 3: Update `copyWith`**

Add params `String? facility, String? visitType, String? trackingNumber,` and in the returned object set:

```dart
      facility: facility ?? this.facility,
      visitType: visitType ?? this.visitType,
      trackingNumber: trackingNumber ?? this.trackingNumber,
```

- [ ] **Step 4: Update `toJson` and `fromJson`**

`toJson` add: `'facility': facility, 'visitType': visitType, 'trackingNumber': trackingNumber,`
`fromJson` add:

```dart
        facility: (j['facility'] ?? '') as String,
        visitType: (j['visitType'] ?? '') as String,
        trackingNumber: (j['trackingNumber'] ?? '') as String,
```

- [ ] **Step 5: Verify & commit**

Run: `flutter analyze lib/models/capture_data.dart` → No issues.

```bash
git add lib/models/capture_data.dart
git commit -m "feat: CaptureData tambah facility/visitType/trackingNumber"
```

---

## Task 4: Extend PhotoRecord + DB migration to v2

**Files:**
- Modify: `lib/models/photo_record.dart`
- Modify: `lib/services/database_service.dart`

- [ ] **Step 1: Add fields to PhotoRecord**

After `imageHash;` add:

```dart
  final String staffName;
  final String facility;
  final String visitType;
  final String trackingNumber;
```

Add to the const constructor (with defaults to keep old call sites valid):

```dart
    this.staffName = '',
    this.facility = '',
    this.visitType = '',
    this.trackingNumber = '',
```

- [ ] **Step 2: Update `toMap`**

Add:

```dart
      'staff_name': staffName,
      'facility': facility,
      'visit_type': visitType,
      'tracking_number': trackingNumber,
```

- [ ] **Step 3: Update `fromMap` (fallback-safe)**

Add:

```dart
      staffName: (map['staff_name'] ?? '') as String,
      facility: (map['facility'] ?? '') as String,
      visitType: (map['visit_type'] ?? '') as String,
      trackingNumber: (map['tracking_number'] ?? '') as String,
```

- [ ] **Step 4: Bump DB version + add onCreate columns + onUpgrade**

In `database_service.dart` `_open()`, change `version: 1` to `version: 2`.

Inside `onCreate`'s `CREATE TABLE`, add the four columns before the closing `)`:

```sql
            custom_text TEXT,
            image_hash TEXT,
            staff_name TEXT,
            facility TEXT,
            visit_type TEXT,
            tracking_number TEXT
```

Add an `onUpgrade` callback to `openDatabase(...)` (right after the `onCreate` block):

```dart
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          for (final col in const [
            'staff_name',
            'facility',
            'visit_type',
            'tracking_number',
          ]) {
            try {
              await db.execute('ALTER TABLE $_table ADD COLUMN $col TEXT');
            } catch (_) {
              // kolom mungkin sudah ada — aman diabaikan
            }
          }
        }
      },
```

- [ ] **Step 5: Verify compiles**

Run: `flutter analyze lib/models/photo_record.dart lib/services/database_service.dart`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/models/photo_record.dart lib/services/database_service.dart
git commit -m "feat: PhotoRecord + migrasi DB v2 (staff/facility/visit_type/tracking_number)"
```

---

## Task 5: Persist new fields in PhotoSaveService

**Files:**
- Modify: `lib/services/photo_save_service.dart:95-106`

- [ ] **Step 1: Pass the new fields into the PhotoRecord**

In `finalize(...)`, in the `PhotoRecord(...)` construction (currently ends at `imageHash: hash,`), add:

```dart
        staffName: settings.staffName,
        facility: data.facility,
        visitType: data.visitType,
        trackingNumber: data.trackingNumber,
```

- [ ] **Step 2: Verify & commit**

Run: `flutter analyze lib/services/photo_save_service.dart` → No issues.

```bash
git add lib/services/photo_save_service.dart
git commit -m "feat: simpan field kunjungan + tracking number ke PhotoRecord"
```

---

## Task 6: Logo asset + pubspec registration + version bump

**Files:**
- Create: `assets/branding/radjak_logo.png`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Produce the logo PNG**

Convert the provided `Rumah_Sakit_Radjak_Hospital_Salemba.webp` (repo root) into `assets/branding/radjak_logo.png`. Use any of:
- ImageMagick: `magick "Rumah_Sakit_Radjak_Hospital_Salemba.webp" assets/branding/radjak_logo.png`
- Or a one-off Dart script using the `image` package: decode the webp bytes with `img.decodeWebP`, then `File('assets/branding/radjak_logo.png').writeAsBytes(img.encodePng(decoded))`.

Confirm the file exists and is a valid PNG (non-zero size, > 5 KB).

- [ ] **Step 2: Register the asset in pubspec.yaml**

Under `flutter:` → `assets:`, add (keep existing entries):

```yaml
    - assets/branding/
```

- [ ] **Step 3: Bump version**

Change the `version:` line to:

```yaml
version: 1.4.0+2011
```

(Minor feature bump; `flutter build` will derive versionCode + ABI offsets from this base.)

- [ ] **Step 4: pub get + verify**

Run: `flutter pub get`
Expected: resolves with no errors; asset path valid.

- [ ] **Step 5: Commit**

```bash
git add assets/branding/radjak_logo.png pubspec.yaml
git commit -m "chore: aset logo Radjak + daftar di pubspec; versi 1.4.0"
```

---

## Task 7: Radjak light theme (app_theme.dart)

**Files:**
- Modify: `lib/utils/app_theme.dart`

- [ ] **Step 1: Replace the theme with Radjak light palette**

Replace the whole file body with (keeps the `AppTheme` API + `showAppMessage`; note `accent` is retained as the gold token so existing references in other screens still compile):

```dart
import 'package:flutter/material.dart';

/// Tema terang korporat Radjak (UI aplikasi, bukan overlay foto).
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1E40AF); // Biru Radjak
  static const Color secondary = Color(0xFF3B82F6); // Hospital Blue
  static const Color gold = Color(0xFFD4AF37); // Luxury Gold

  /// Token aksen lama (dipakai layar lain) -> emas Radjak.
  static const Color accent = gold;

  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  /// Alias mundur-kompatibel: kode lama memanggil AppTheme.dark.
  static ThemeData get dark => light;
}

/// Helper tampil pesan ramah (tanpa stack trace ke user).
void showAppMessage(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFB3261E) : AppTheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
}
```

- [ ] **Step 2: Ensure `main.dart` uses the light theme**

In `lib/main.dart`, if it references `AppTheme.dark`, leave as-is (aliased to light) OR change to `AppTheme.light`. Also set `themeMode: ThemeMode.light` if a `MaterialApp.themeMode` is present. Run `flutter analyze lib/main.dart` after.

- [ ] **Step 3: Verify & commit**

Run: `flutter analyze lib/utils/app_theme.dart lib/main.dart` → No issues.

```bash
git add lib/utils/app_theme.dart lib/main.dart
git commit -m "feat: tema terang korporat Radjak (biru/emas)"
```

---

## Task 8: Overlay Layout B — Radjak header + visit line + tracking number

**Files:**
- Modify: `lib/widgets/timemark_overlay.dart`

> Read the full file first. It composes the bottom info bar and the top-right brand watermark. You will (a) add a Radjak header band at the top, (b) add a visit-info line and tracking number to the bottom bar.

- [ ] **Step 1: Add the Radjak header band**

Add this helper widget method inside the overlay's State/class (uses the registered asset):

```dart
  Widget _radjakHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white.withOpacity(0.92),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/branding/radjak_logo.png', height: 22),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'RADJAK HOSPITAL · Salemba',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
```

Wrap with a thin gold bottom border by putting the `Container` child inside a `DecoratedBox`/by adding `border: const Border(bottom: BorderSide(color: Color(0xFFD4AF37), width: 2))` to the header `Container` decoration (convert `color:` to `decoration: BoxDecoration(color: ..., border: ...)`).

- [ ] **Step 2: Mount the header at the top of the overlay stack**

In the overlay `build`, place the header at the top edge gated by the toggle. If the overlay root is a `Stack`, add:

```dart
        if (settings.showHeader)
          Align(
            alignment: Alignment.topCenter,
            child: _radjakHeader(),
          ),
```

If the root is a `Column` for the bottom bar, wrap the whole thing so the header sits at `Alignment.topCenter` over the photo (the photo is behind, in `preview_screen.dart`'s Stack). Keep the existing bottom bar as-is.

- [ ] **Step 3: Add the visit-info line + tracking number to the bottom bar**

In the bottom info bar (where date/address/coordinate `Text` widgets are built), after the coordinate line add:

```dart
        if (settings.showVisitInfo &&
            (settings.staffName.isNotEmpty ||
                data.visitType.isNotEmpty ||
                data.facility.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              [
                if (settings.staffName.isNotEmpty) settings.staffName,
                if (data.visitType.isNotEmpty) data.visitType,
                if (data.facility.isNotEmpty) data.facility,
              ].join('  ·  '),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11 * settings.fontSize.scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (data.trackingNumber.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              data.trackingNumber,
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                fontSize: 11 * settings.fontSize.scale,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
```

> Match the exact `Text` styling pattern already used in the file (font family via `settings.fontFamily`, opacity) so it looks consistent. The `11 * scale` sizes above are a guide — align them to the file's existing base sizes.

- [ ] **Step 4: Keep the random verification code hidden by default**

The existing "Kode Foto" block is already gated by `settings.showVerification`, which now defaults to `false` (Task 2). No code change needed beyond confirming the gate exists.

- [ ] **Step 5: Verify & commit**

Run: `flutter analyze lib/widgets/timemark_overlay.dart` → No issues.

```bash
git add lib/widgets/timemark_overlay.dart
git commit -m "feat: overlay Layout B - header Radjak + baris kunjungan + nomor tracking"
```

---

## Task 9: Assign tracking number + visit fields in PreviewScreen

**Files:**
- Modify: `lib/screens/preview/preview_screen.dart`

- [ ] **Step 1: Assign a tracking number when the preview opens**

Add import: `import '../../services/tracking_service.dart';`

In `initState()` after `_settings = SettingsService.instance.current;`, kick off async assignment:

```dart
    _assignTracking();
```

Add the method:

```dart
  Future<void> _assignTracking() async {
    if (_data.trackingNumber.isNotEmpty) return; // draft sudah punya
    final tn = await TrackingService.instance.next(_data.timestamp.year);
    if (!mounted) return;
    setState(() => _data = _data.copyWith(trackingNumber: tn));
  }
```

- [ ] **Step 2: Add visit fields to the edit sheet**

In `_openEditor()`, the existing sheet has the "Custom Text" field. Add three controls before the "Selesai" button:

- **Nama Staf** (prefilled from `_settings.staffName`, editable; writes back via `_settings = _settings.copyWith(staffName: v)`).
- **Faskes/Tujuan** `TextField` → `_data = _data.copyWith(facility: v)`. Prefill controller from `_data.facility`.
- **Jenis Kunjungan** `DropdownButtonFormField<String>` over `const ['Sales Visit','Maintenance','Audit Internal','Follow-up','Survey','Lainnya']`, value `_data.visitType.isEmpty ? 'Sales Visit' : _data.visitType` → `_data = _data.copyWith(visitType: v)`.

Use the existing `_label(...)` and `_dec(...)` helpers for consistent styling. Wrap state writes in `setState`/`setSheet` exactly like the existing Custom Text field does.

- [ ] **Step 3: Default visit type so the first photo is never blank**

In `_assignTracking()` (or `initState`), if `_data.visitType.isEmpty` set it to the saved default:

```dart
    if (_data.visitType.isEmpty) {
      _data = _data.copyWith(visitType: 'Sales Visit');
    }
```

(Place this in `initState` synchronously before `_assignTracking()` so the overlay shows it immediately.)

- [ ] **Step 4: Verify & commit**

Run: `flutter analyze lib/screens/preview/preview_screen.dart` → No issues.

```bash
git add lib/screens/preview/preview_screen.dart
git commit -m "feat: preview - assign nomor tracking + input staf/faskes/jenis kunjungan"
```

---

## Task 10: Settings — staff profile + default visit type + toggles

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`

> Read the file first to match its section/SwitchTile patterns.

- [ ] **Step 1: Add a "Profil Marketing" section**

Add a `TextField` (or ListTile-with-dialog) for **Nama Staf** bound to `_s.staffName`, saved via `SettingsService.instance.save(_s.copyWith(staffName: v))` using the same save pattern the screen already uses for other settings.

- [ ] **Step 2: Add a default "Jenis Kunjungan" selector (optional)**

If desired, persist a default visit type. MVP-simple: reuse the same dropdown list as Task 9; store it in `staffName`-adjacent prefs is NOT needed — the preview already defaults to 'Sales Visit'. Skip persistence here unless trivial. (No-op allowed; note it in the commit.)

- [ ] **Step 3: Add toggles for the new overlay elements**

Add two `SwitchListTile`s matching the existing toggle style:
- "Header Radjak (atas foto)" ↔ `_s.showHeader`
- "Info Kunjungan (staf · jenis · faskes)" ↔ `_s.showVisitInfo`

Each writes via `setState` + `SettingsService.instance.save(...)` exactly like the existing toggles (e.g. the watermark toggle).

- [ ] **Step 4: Verify & commit**

Run: `flutter analyze lib/screens/settings/settings_screen.dart` → No issues.

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "feat: settings - profil nama staf + toggle header/info kunjungan"
```

---

## Task 11: History + detail show new fields

**Files:**
- Modify: `lib/screens/history/history_screen.dart`
- Modify: `lib/screens/history/photo_detail_screen.dart`

- [ ] **Step 1: Show tracking number on the history list**

In the history list item subtitle, where the verification code / date is shown, prefer `record.trackingNumber` when non-empty (fallback to existing code). Match the existing text style.

- [ ] **Step 2: Show full visit info on the detail screen**

In `photo_detail_screen.dart`, add rows for `staffName`, `facility`, `visitType`, `trackingNumber` (only when non-empty), using the same label/value row pattern already present for address/coordinate.

- [ ] **Step 3: Verify & commit**

Run: `flutter analyze lib/screens/history/history_screen.dart lib/screens/history/photo_detail_screen.dart` → No issues.

```bash
git add lib/screens/history/history_screen.dart lib/screens/history/photo_detail_screen.dart
git commit -m "feat: riwayat & detail tampilkan nomor tracking + info kunjungan"
```

---

## Task 12: Splash + app label branding

**Files:**
- Modify: `lib/screens/splash/splash_screen.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Splash uses Radjak logo + name**

In `splash_screen.dart`, replace the logo image source with `assets/branding/radjak_logo.png` and the title text with `Radjak Marketing`. Keep the existing layout/animation. On the white theme, ensure text color is `AppTheme.textPrimary`.

- [ ] **Step 2: Launcher label**

In `AndroidManifest.xml`, set the `<application android:label="Radjak Marketing" ...>`. Do NOT change `applicationId` (stays `com.timeproof.app`) — this preserves auto-update over existing installs.

- [ ] **Step 3: Verify & commit**

Run: `flutter analyze lib/screens/splash/splash_screen.dart` → No issues.

```bash
git add lib/screens/splash/splash_screen.dart android/app/src/main/AndroidManifest.xml
git commit -m "feat: branding splash + label launcher Radjak Marketing"
```

---

## Task 13: Golden test for Layout B

**Files:**
- Modify: `test/overlay_golden_test.dart`

- [ ] **Step 1: Add a golden case for the Radjak Layout B overlay**

Add a test that builds `TimemarkOverlay` with `OverlaySettings(staffName: 'Budi S.', showHeader: true, showVisitInfo: true)` and a `CaptureData` having `facility: 'RS Mitra Keluarga'`, `visitType: 'Sales Visit'`, `trackingNumber: 'TP-2026-000017'`. Follow the existing pattern in this file: wrap in `Scaffold`, load the Roboto font via `FontLoader` (`import 'package:flutter/services.dart';`), call `initializeDateFormatting('id_ID')`, fixed surface size 3:4. Asset images in goldens render as empty boxes unless a test asset bundle is provided — that is acceptable; the golden verifies text layout, not the logo bitmap.

- [ ] **Step 2: Generate & run goldens**

Run: `flutter test --update-goldens test/overlay_golden_test.dart`
Then: `flutter test test/overlay_golden_test.dart`
Expected: PASS. New golden file under `test/goldens/`.

- [ ] **Step 3: Commit**

```bash
git add test/overlay_golden_test.dart test/goldens/
git commit -m "test: golden overlay Layout B Radjak"
```

---

## Task 14: Full verify + release build

**Files:** none (verification only)

- [ ] **Step 1: Analyze the whole project**

Run: `flutter analyze`
Expected: No issues (or only pre-existing warnings unrelated to this work).

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: all pass (tracking + version + golden).

- [ ] **Step 3: Build splits + universal**

Run:
```
flutter build apk --release --split-per-abi
flutter build apk --release
```
Expected: APKs in `build/app/outputs/flutter-apk/`. Verify versionName = 1.4.0 and versionCode rises above the currently installed build (arm64 should be base+2000 = 4011, > 4010 from v1.3.2).

- [ ] **Step 4: Commit any build-config changes** (only if local.properties-driven values were intentionally changed; local.properties itself is gitignored — do not commit it).

> Release to GitHub + landing is a separate, user-initiated step (same flow as prior releases: tag `v1.4.0`, upload the 4 ABI-named assets). Do NOT publish without user confirmation.

---

## Self-Review Notes

- **Spec coverage:** Theme (T7), logo+pubspec (T6), Layout B header+info+tracking (T8), visit fields (T2/T3/T9/T10), tracking number (T1/T9), DB migration (T4), history display (T11), splash/label (T12), tests (T1/T13/T14), branch+version (T6/T14). All spec sections mapped.
- **Type consistency:** `staffName`/`showHeader`/`showVisitInfo` (OverlaySettings); `facility`/`visitType`/`trackingNumber` (CaptureData + PhotoRecord, same names); `TrackingService.next(int year)` + `format`/`nextSeq` used consistently in T1/T9.
- **applicationId** unchanged everywhere (auto-update continuity) — stated in spec, T6, T12.
- **Verification code** default flipped to false in both constructor and fromJson (T2); overlay gate already exists (T8 step 4).
