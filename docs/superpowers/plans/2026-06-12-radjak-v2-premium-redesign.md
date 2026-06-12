# Radjak Marketing v2.0 — Premium Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform Radjak Marketing from a TimeProof-style camera-first app into a distinct, premium **dashboard-first** product (Light Luxe: white + Radjak blue/gold, glassmorphism, Fraunces+Inter), with hardened integrity (no data editing, no manual map) and a refined photo overlay.

**Architecture:** Pure-Flutter, offline. New entry = Home/Dashboard (reads local SQLite stats). New flow: Home → Start Visit form → Camera (GPS-only) → Preview (locked, Save/Retake only) → saved. A reusable "luxe" widget kit + a Fraunces/Inter theme drive the look. Backend services (location, geocoding, tracking, DB, photo-save, update) are reused unchanged.

**Tech Stack:** Flutter, sqflite, shared_preferences, image, crypto, google-fonts ttf bundled offline. Spec: `docs/superpowers/specs/2026-06-12-radjak-v2-premium-redesign-design.md`. Visual source of truth: `build/mockup/design.html`. Branch: `radjak-app`. Package: `com.radjak.marketing`. Release target: repo `alfarabiki/Radjak-Marketing` v2.0.0.

**Environment (Windows):** Flutter not on PATH — prepend `$env:Path = "D:\flutter\bin;" + $env:Path` (PowerShell) or `export PATH="/d/flutter/bin:$PATH"` (bash). JAVA_HOME for builds: `D:\jdk17\jdk-17.0.19+10`. Do NOT switch branches. Commit on `radjak-app`.

---

## File Structure

- `assets/fonts/Fraunces.ttf`, `assets/fonts/Inter.ttf` — bundled premium fonts (offline).
- `assets/branding/radjak_logo.png` — **transparent** logo for overlay header + dashboard.
- `lib/utils/app_theme.dart` — Light Luxe tokens + Fraunces/Inter textTheme (rewrite).
- `lib/widgets/luxe/` — reusable kit: `luxe_card.dart`, `stat_tile.dart`, `primary_button.dart`, `section_header.dart`, `visit_tile.dart`, `luxe_bottom_nav.dart`.
- `lib/screens/home/home_screen.dart` — dashboard (new entry).
- `lib/screens/start_visit/start_visit_screen.dart` — visit form (new).
- `lib/screens/shell/app_shell.dart` — bottom-nav shell hosting Home/History/Profile (new).
- `lib/services/database_service.dart` — add stat queries.
- `lib/widgets/timemark_overlay.dart` — transparent logo header + blue accent line.
- `lib/screens/camera/camera_screen.dart` — premium chrome, remove map, accept visit data.
- `lib/screens/preview/preview_screen.dart` — locked (remove editor).
- `lib/screens/history/history_screen.dart`, `photo_detail_screen.dart` — premium restyle.
- `lib/screens/settings/settings_screen.dart` — wrapped as Profile.
- `lib/main.dart`, `lib/screens/splash/splash_screen.dart` — route splash → AppShell.
- Delete: `lib/screens/map_picker/map_picker_screen.dart`.

---

## Task 1: Bundle premium fonts (Fraunces + Inter)

**Files:** Create `assets/fonts/Fraunces.ttf`, `assets/fonts/Inter.ttf`; Modify `pubspec.yaml`.

- [ ] **Step 1: Download the TTFs (machine has internet)**

```bash
mkdir -p assets/fonts
curl -L -o assets/fonts/Inter.ttf "https://github.com/google/fonts/raw/main/ofl/inter/Inter%5Bopsz,wght%5D.ttf"
curl -L -o assets/fonts/Fraunces.ttf "https://github.com/google/fonts/raw/main/ofl/fraunces/Fraunces%5BSOFT,WONK,opsz,wght%5D.ttf"
ls -la assets/fonts/Inter.ttf assets/fonts/Fraunces.ttf
```
Expected: both files exist, > 100 KB each. If a URL 404s, fall back to: Inter `https://github.com/rsms/inter/raw/master/docs/font-files/Inter-Regular.otf` is NOT ttf — prefer the google/fonts path; if blocked, report BLOCKED with the curl error (do not invent a font).

- [ ] **Step 2: Register fonts in `pubspec.yaml`**

Under `flutter:` → `fonts:` (replace the existing fonts block so the app ships Fraunces + Inter; keep Roboto too for overlay legacy):
```yaml
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter.ttf
    - family: Fraunces
      fonts:
        - asset: assets/fonts/Fraunces.ttf
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto.ttf
```
(If `assets/fonts/Roboto.ttf` doesn't exist on this branch, omit the Roboto entry.)

- [ ] **Step 3: Verify**

Run: `flutter pub get`
Expected: resolves, no asset errors.

- [ ] **Step 4: Commit**

```bash
git add assets/fonts/Inter.ttf assets/fonts/Fraunces.ttf pubspec.yaml
git commit -m "chore(radjak): bundle Fraunces + Inter fonts"
```

---

## Task 2: Transparent Radjak logo PNG

**Files:** Create `assets/branding/radjak_logo.png` (transparent); Modify `pubspec.yaml` (ensure `assets/branding/` registered — likely already).

- [ ] **Step 1: Generate a transparent PNG from the white-bg source**

The source `Rumah_Sakit_Radjak_Hospital_Salemba.webp` (repo root) has a white background. Write a one-off Dart script `tool/make_logo.dart` that decodes it and makes near-white pixels transparent:
```dart
import 'dart:io';
import 'package:image/image.dart' as img;
void main() {
  final src = img.decodeWebP(File('Rumah_Sakit_Radjak_Hospital_Salemba.webp').readAsBytesSync())!;
  final out = src.convert(numChannels: 4);
  for (final p in out) {
    // near-white -> transparent (threshold 238)
    if (p.r >= 238 && p.g >= 238 && p.b >= 238) {
      p.a = 0;
    }
  }
  File('assets/branding/radjak_logo.png').writeAsBytesSync(img.encodePng(out));
  stdout.writeln('wrote assets/branding/radjak_logo.png ${out.width}x${out.height}');
}
```
Run: `dart run tool/make_logo.dart`
Expected: prints dimensions; file exists > 5 KB.

- [ ] **Step 2: Sanity-check transparency**

Run: `dart -e "import 'dart:io';import 'package:image/image.dart' as img;void main(){final i=img.decodePng(File('assets/branding/radjak_logo.png').readAsBytesSync())!;final c=i.getPixel(0,0);print('corner alpha=\${c.a}');}"`
Expected: `corner alpha=0` (top-left corner transparent). If not 0, raise the threshold slightly (e.g. 232) and re-run Step 1.

- [ ] **Step 3: Ensure pubspec lists `assets/branding/`** (it should from v1.4.x). If missing, add under `assets:`.

- [ ] **Step 4: Commit**

```bash
git add assets/branding/radjak_logo.png tool/make_logo.dart pubspec.yaml
git commit -m "chore(radjak): transparent logo PNG for overlay/dashboard"
```

> Note: programmatic white-removal may leave faint edges. Acceptable for MVP; a vendor-supplied transparent asset can replace it later without code changes (same path).

---

## Task 3: Light Luxe theme (Fraunces + Inter)

**Files:** Modify `lib/utils/app_theme.dart` (rewrite).

- [ ] **Step 1: Rewrite `lib/utils/app_theme.dart`**

```dart
import 'package:flutter/material.dart';

/// Tema "Light Luxe" korporat Radjak. (UI app, bukan overlay foto.)
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1E40AF); // Biru Radjak
  static const Color secondary = Color(0xFF3B82F6); // Hospital Blue
  static const Color accentBlue = Color(0xFF4F9DF7); // biru terang (di atas gelap)
  static const Color gold = Color(0xFFD4AF37);
  static const Color accent = gold; // alias mundur-kompatibel

  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color line = Color(0xFFE8EDF5);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static const String fontHeading = 'Fraunces';
  static const String fontBody = 'Inter';

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = base.colorScheme.copyWith(
      primary: primary, secondary: secondary, surface: surface,
      onPrimary: Colors.white, onSurface: textPrimary,
    );
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      fontFamily: fontBody,
      textTheme: base.textTheme.apply(
        fontFamily: fontBody, bodyColor: textPrimary, displayColor: textPrimary,
      ).copyWith(
        headlineLarge: const TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: const TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: const TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg, foregroundColor: textPrimary, elevation: 0, centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, fontSize: 20, color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          textStyle: const TextStyle(fontFamily: fontBody, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  /// Alias mundur-kompatibel (kode lama memanggil AppTheme.dark).
  static ThemeData get dark => light;
}

void showAppMessage(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
    ?..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? const Color(0xFFB3261E) : AppTheme.primary,
      duration: const Duration(seconds: 3),
    ));
}
```

- [ ] **Step 2: Verify + commit**

Run: `flutter analyze lib/utils/app_theme.dart` → No issues.
```bash
git add lib/utils/app_theme.dart
git commit -m "feat(radjak): Light Luxe theme (Fraunces headings + Inter body)"
```

---

## Task 4: Luxe widget kit

**Files:** Create `lib/widgets/luxe/luxe_card.dart`, `stat_tile.dart`, `primary_button.dart`, `section_header.dart`, `visit_tile.dart`, `luxe_bottom_nav.dart`. Test: `test/luxe_widgets_test.dart`.

- [ ] **Step 1: Write a widget test first**

```dart
// test/luxe_widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeproof/widgets/luxe/stat_tile.dart';
import 'package:timeproof/widgets/luxe/primary_button.dart';

void main() {
  testWidgets('StatTile shows number + label', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body:
      StatTile(value: '12', label: 'Kunjungan hari ini', icon: Icons.place))));
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Kunjungan hari ini'), findsOneWidget);
  });

  testWidgets('PrimaryButton fires onTap', (t) async {
    var tapped = false;
    await t.pumpWidget(MaterialApp(home: Scaffold(body:
      PrimaryGradientButton(title: 'Mulai', subtitle: 'x', icon: Icons.camera_alt,
        onTap: () => tapped = true))));
    await t.tap(find.text('Mulai'));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run → fails (widgets undefined)**

Run: `flutter test test/luxe_widgets_test.dart` → FAIL (imports not found).

- [ ] **Step 3: Implement the widgets**

`lib/widgets/luxe/luxe_card.dart`:
```dart
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Kartu kaca (glassmorphism) Light Luxe.
class LuxeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool goldTop;
  const LuxeCard({super.key, required this.child,
    this.padding = const EdgeInsets.all(18), this.goldTop = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.06),
          blurRadius: 24, offset: const Offset(0, 10))],
      ),
      foregroundDecoration: goldTop
        ? const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.gold, width: 2)),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)))
        : null,
      child: child,
    );
  }
}
```

`lib/widgets/luxe/stat_tile.dart`:
```dart
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'luxe_card.dart';

class StatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final bool gold;
  const StatTile({super.key, required this.value, required this.label,
    required this.icon, this.gold = false});
  @override
  Widget build(BuildContext context) {
    final tint = gold ? AppTheme.gold : AppTheme.primary;
    return LuxeCard(goldTop: gold, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 19, color: tint)),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontFamily: AppTheme.fontHeading,
          fontSize: 34, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1)),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500)),
      ],
    ));
  }
}
```

`lib/widgets/luxe/primary_button.dart`:
```dart
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class PrimaryGradientButton extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const PrimaryGradientButton({super.key, required this.title, required this.subtitle,
    required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: Ink(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.34),
          blurRadius: 30, offset: const Offset(0, 16))]),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontFamily: AppTheme.fontHeading,
            color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        ])),
        Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35))),
          child: Icon(icon, color: Colors.white)),
      ]),
    ));
  }
}
```

`lib/widgets/luxe/section_header.dart`:
```dart
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontFamily: AppTheme.fontHeading,
        fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      if (actionLabel != null) GestureDetector(onTap: onAction,
        child: Text(actionLabel!, style: const TextStyle(color: AppTheme.primary,
          fontSize: 12.5, fontWeight: FontWeight.w600))),
    ]);
  }
}
```

`lib/widgets/luxe/visit_tile.dart`:
```dart
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class VisitTile extends StatelessWidget {
  final String facility, meta, trackingNumber, chip;
  final VoidCallback? onTap;
  const VisitTile({super.key, required this.facility, required this.meta,
    required this.trackingNumber, this.chip = '', this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line)),
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(colors: [Color(0xFFEEF3FF), Color(0xFFDCE7FF)])),
          child: const Icon(Icons.local_hospital_outlined, size: 21, color: AppTheme.primary)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(facility, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(meta, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
          if (trackingNumber.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2),
            child: Text(trackingNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: Color(0xFFB8902A), letterSpacing: 0.3))),
        ])),
        if (chip.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7)),
          child: Text(chip, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary))),
      ]),
    ));
  }
}
```

`lib/widgets/luxe/luxe_bottom_nav.dart`:
```dart
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class LuxeBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const LuxeBottomNav({super.key, required this.index, required this.onChanged});
  static const _items = [
    (Icons.home_outlined, 'Beranda'),
    (Icons.history, 'Riwayat'),
    (Icons.person_outline, 'Profil'),
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      height: 66,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.line),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.14),
          blurRadius: 30, offset: const Offset(0, 12))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final on = i == index;
          final c = on ? AppTheme.primary : AppTheme.textSecondary;
          return GestureDetector(onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(_items[i].$1, size: 22, color: c), const SizedBox(height: 4),
                Text(_items[i].$2, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: c))]));
        })),
    );
  }
}
```

- [ ] **Step 4: Run tests → pass**

Run: `flutter test test/luxe_widgets_test.dart` → PASS (2 tests). `flutter analyze lib/widgets/luxe` → No issues.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/luxe test/luxe_widgets_test.dart
git commit -m "feat(radjak): luxe widget kit (card, stat, button, header, visit tile, bottom nav)"
```

---

## Task 5: DatabaseService stat queries

**Files:** Modify `lib/services/database_service.dart`; Test `test/database_stats_test.dart`.

- [ ] **Step 1: Write failing tests** (use sqflite_common_ffi in-memory)

```dart
// test/database_stats_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timeproof/models/photo_record.dart';
import 'package:timeproof/services/database_service.dart';

PhotoRecord rec(String id, DateTime t) => PhotoRecord(id: id, imagePath: '/x.jpg',
  address: '', latitude: 0, longitude: 0, accuracy: 0, timestamp: t,
  verificationCode: id, customText: '', imageHash: 'H', trackingNumber: 'TP-x');

void main() {
  setUpAll(() { sqfliteFfiInit(); databaseFactory = databaseFactoryFfi; });

  test('countToday / countThisMonth / recent', () async {
    final now = DateTime(2026, 6, 12, 9);
    await DatabaseService.instance.debugReset(); // see Step 3
    await DatabaseService.instance.insert(rec('a', now));
    await DatabaseService.instance.insert(rec('b', now.subtract(const Duration(days: 1))));
    await DatabaseService.instance.insert(rec('c', DateTime(2026, 5, 30)));

    expect(await DatabaseService.instance.countToday(now: now), 1);
    expect(await DatabaseService.instance.countThisMonth(now: now), 2); // a + b (June)
    final r = await DatabaseService.instance.recent(2);
    expect(r.length, 2);
    expect(r.first.id, 'a'); // newest first
  });
}
```

- [ ] **Step 2: Run → fails** (`countToday` undefined). Add `sqflite_common_ffi` to `dev_dependencies` in pubspec if absent (`flutter pub add --dev sqflite_common_ffi`), then `flutter pub get`.

- [ ] **Step 3: Implement the queries** in `database_service.dart` (add methods to the class):

```dart
  Future<int> countToday({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, n.day).millisecondsSinceEpoch;
    final end = start + const Duration(days: 1).inMilliseconds;
    return _countBetween(start, end);
  }

  Future<int> countThisMonth({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, 1).millisecondsSinceEpoch;
    final end = DateTime(n.year, n.month + 1, 1).millisecondsSinceEpoch;
    return _countBetween(start, end);
  }

  Future<int> _countBetween(int startMs, int endMs) async {
    try {
      final db = await _database;
      final r = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $_table WHERE timestamp >= ? AND timestamp < ?',
        [startMs, endMs]);
      return (r.first['c'] as int?) ?? 0;
    } catch (_) { return 0; }
  }

  Future<List<PhotoRecord>> recent(int n) async {
    try {
      final db = await _database;
      final rows = await db.query(_table, orderBy: 'timestamp DESC', limit: n);
      return rows.map(PhotoRecord.fromMap).toList();
    } catch (_) { return <PhotoRecord>[]; }
  }

  /// Khusus test: tutup & hapus db agar fresh.
  Future<void> debugReset() async {
    try { await (await _database).delete(_table); } catch (_) {}
  }
```

- [ ] **Step 4: Run → pass.** `flutter test test/database_stats_test.dart` → PASS. `flutter analyze lib/services/database_service.dart` → No issues.

- [ ] **Step 5: Commit**

```bash
git add lib/services/database_service.dart test/database_stats_test.dart pubspec.yaml pubspec.lock
git commit -m "feat(radjak): dashboard stat queries (countToday/countThisMonth/recent)"
```

---

## Task 6: Overlay v2 — transparent logo header + blue accent line

**Files:** Modify `lib/widgets/timemark_overlay.dart`, `lib/models/overlay_settings.dart`; regenerate `test/goldens/`.

- [ ] **Step 1: Default overlay font → Inter**

In `lib/models/overlay_settings.dart`, change constructor default `this.fontFamily = 'Roboto'` → `this.fontFamily = 'Inter'`, and the `fromJson` fallback `'Roboto'` → `'Inter'`. Ensure `kOverlayFonts` contains `'Inter'` (it does).

- [ ] **Step 2: Header = transparent logo only**

In `timemark_overlay.dart` `_radjakHeader()`, replace the white `Container` band with a bare transparent logo (no background, no text):
```dart
  Widget _radjakHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 14, left: 14),
      child: Image.asset('assets/branding/radjak_logo.png', height: 34),
    );
  }
```
Keep the mount `if (settings.showHeader) Align(alignment: Alignment.topLeft, child: _radjakHeader())` (change alignment topCenter → topLeft).

- [ ] **Step 3: Bottom accent line → Radjak blue; tracking stays gold**

Find the bottom info block's container that has the gold left border (added in earlier work) and change its left border color to `AppTheme.accentBlue` (`Color(0xFF4F9DF7)`). Keep the tracking-number text color gold `Color(0xFFD4AF37)`. If the info block has no explicit left-border container, wrap the bottom Column in:
```dart
Container(
  decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF4F9DF7), width: 4))),
  padding: const EdgeInsets.only(left: 10),
  child: /* existing bottom column */,
)
```
(Import `app_theme.dart` if you reference `AppTheme.accentBlue`, else use the literal `Color(0xFF4F9DF7)`.)

- [ ] **Step 4: Regenerate goldens + run**

Run: `flutter test --update-goldens test/overlay_golden_test.dart` then `flutter test test/overlay_golden_test.dart`
Expected: PASS. (The golden's `radjak_logo` may render blank in tests if PNG asset precache fails — the existing test already precaches images; keep that.)

- [ ] **Step 5: analyze + commit**

Run: `flutter analyze lib/widgets/timemark_overlay.dart lib/models/overlay_settings.dart` → No issues.
```bash
git add lib/widgets/timemark_overlay.dart lib/models/overlay_settings.dart test/goldens
git commit -m "feat(radjak): overlay v2 - transparent logo header, blue accent line, Inter"
```

---

## Task 7: Home / Dashboard screen

**Files:** Create `lib/screens/home/home_screen.dart`.

- [ ] **Step 1: Implement the dashboard** (reads stats; uses luxe kit; matches `build/mockup/design.html` left phone)

```dart
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

class _HomeScreenState extends State<HomeScreen> with RouteAware {
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
    _load(); // refresh after returning
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
          else if (_recent.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 18),
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

  bool _isToday(DateTime t) { final n = DateTime.now(); return t.year==n.year && t.month==n.month && t.day==n.day; }
  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'M';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0,1) + parts.last.substring(0,1)).toUpperCase();
  }
}
```

> NOTE: `PhotoDetailScreen` must accept `{required PhotoRecord record}`. If the current constructor differs, adapt the call in Task 10 to match (and update here). Verify the existing signature before wiring.

- [ ] **Step 2: analyze + commit**

Run: `flutter analyze lib/screens/home/home_screen.dart` → resolve missing-symbol errors only after Tasks 4/5/8 exist (StartVisitScreen comes in Task 8-pre). If `StartVisitScreen` not yet present, this task can be committed after Task 8. **Order: do Task 8 (Start Visit) before finalizing Task 7's analyze.** Commit:
```bash
git add lib/screens/home/home_screen.dart
git commit -m "feat(radjak): premium dashboard/home screen"
```

---

## Task 8: Start Visit screen (visit form)

**Files:** Create `lib/screens/start_visit/start_visit_screen.dart`.

- [ ] **Step 1: Implement** — collects Faskes + Jenis (staff from profile), then pushes Camera with the data, returns result up.

```dart
import 'package:flutter/material.dart';
import '../../models/capture_data.dart';
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
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CameraScreen(
      facility: _facility.text.trim(), visitType: _type, staffName: staff)));
    if (mounted) Navigator.of(context).pop(); // back to Home after camera flow
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
```

- [ ] **Step 2: analyze (after Task 9 adjusts CameraScreen ctor) + commit**

Run: `flutter analyze lib/screens/start_visit/start_visit_screen.dart` (will error until CameraScreen accepts the new params — Task 9). Commit after Task 9:
```bash
git add lib/screens/start_visit/start_visit_screen.dart
git commit -m "feat(radjak): start-visit form (faskes + jenis)"
```

---

## Task 9: Camera screen — accept visit data, remove map, premium chrome

**Files:** Modify `lib/screens/camera/camera_screen.dart`.

- [ ] **Step 1: Add constructor params** for the visit data:

```dart
class CameraScreen extends StatefulWidget {
  final String facility, visitType, staffName;
  const CameraScreen({super.key, this.facility = '', this.visitType = '', this.staffName = ''});
  ...
}
```

- [ ] **Step 2: Remove the map button + manual-location flow.** In `_buildControls()`, delete the left `_circleButton(icon: Icons.map_outlined ...)` and its `_pickManualLocation` usage. Remove the `_pickManualLocation` method and the import of `map_picker_screen.dart`. Keep shutter + the right button (repurpose the right `tune` button to open Settings/Profile or remove — keep `tune`→Settings).

- [ ] **Step 3: Pass visit data into the preview.** Where the captured `CaptureData` is built before navigating to `PreviewScreen`, set the new fields:
```dart
final data = baseCaptureData.copyWith(
  facility: widget.facility, visitType: widget.visitType,
);
// staffName lives in settings; ensure settings.staffName is used at save time (already).
```
If staffName should override the profile for this capture, also `SettingsService.instance` value is used at save; if `widget.staffName` differs, set it on settings copy passed to preview. Simplest: rely on profile staffName (already wired in PhotoSaveService). Pass facility+visitType via CaptureData.

- [ ] **Step 4: Premium chrome (light).** Restyle the controls bar background from pure black to a translucent dark glass only over the camera (keep camera preview legibility): change `_buildControls()` container color to `Colors.black.withValues(alpha: 0.82)` and the shutter border to `AppTheme.gold`/`AppTheme.primary` per taste; AppBar transparent. (Camera preview stays dark by nature — that's fine and not "white-on-white".)

- [ ] **Step 5: analyze + commit**

Run: `flutter analyze lib/screens/camera/camera_screen.dart lib/screens/start_visit/start_visit_screen.dart` → No issues (now that ctor matches).
```bash
git add lib/screens/camera/camera_screen.dart
git commit -m "feat(radjak): camera accepts visit data, manual map removed, premium chrome"
```

---

## Task 10: Preview screen — locked (remove editor)

**Files:** Modify `lib/screens/preview/preview_screen.dart`.

- [ ] **Step 1: Remove the "Ubah Data" editor.** Delete the AppBar `TextButton.icon` "Ubah Data" action, the `_openEditor()` method, `_editDateTime()`, and the `_label`/`_dec` helpers only used by the editor. Keep tracking-number assignment (`_assignTracking`) and the default visitType logic.

- [ ] **Step 2: Take facility/visitType from the incoming CaptureData** (set by Camera/StartVisit). Remove any in-preview editing of facility/visitType/address/coords/time. The preview is display-only + Save/Retake.

- [ ] **Step 3: Update the bottom hint text** from "Ketuk Ubah Data..." to "Foto terkunci — data tidak dapat diubah (anti-pemalsuan)." Keep Save/Retake buttons.

- [ ] **Step 4: analyze + commit**

Run: `flutter analyze lib/screens/preview/preview_screen.dart` → No issues.
```bash
git add lib/screens/preview/preview_screen.dart
git commit -m "feat(radjak): preview terkunci (hapus Ubah Data) - anti-pemalsuan"
```

---

## Task 11: History + detail premium restyle

**Files:** Modify `lib/screens/history/history_screen.dart`, `lib/screens/history/photo_detail_screen.dart`.

- [ ] **Step 1: History list uses `VisitTile`.** Replace each row's bespoke tile with `VisitTile(facility: r.facility.isEmpty ? "—" : r.facility, meta: "${DateFormat('dd MMM yyyy, HH:mm','id_ID').format(r.timestamp)} · ${r.visitType}", trackingNumber: r.trackingNumber, onTap: ...)`. Keep the existing empty-state but restyle to Light Luxe (textSecondary). Wrap the screen in a Scaffold with AppBar title "Riwayat" (Fraunces via theme).

- [ ] **Step 2: Detail screen** — confirm/define constructor `PhotoDetailScreen({required PhotoRecord record})`. Restyle rows to Light Luxe (label `textSecondary`, value `textPrimary`), show the photo, and the existing field rows (Nomor Tracking, Nama Staf, Faskes, Jenis, address, coords). No edit controls.

- [ ] **Step 3: analyze + commit**

Run: `flutter analyze lib/screens/history` → No issues.
```bash
git add lib/screens/history
git commit -m "feat(radjak): history + detail premium restyle"
```

---

## Task 12: App shell (bottom nav) + Profile + splash routing

**Files:** Create `lib/screens/shell/app_shell.dart`; Modify `lib/screens/settings/settings_screen.dart` (Profile title/wrapping), `lib/main.dart`, `lib/screens/splash/splash_screen.dart`; Delete `lib/screens/map_picker/map_picker_screen.dart`.

- [ ] **Step 1: App shell** hosting Home / History / Profile via `LuxeBottomNav`:

```dart
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxe/luxe_bottom_nav.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final pages = const [HomeScreen(), HistoryScreen(), SettingsScreen()];
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(index: _i, children: pages),
      bottomNavigationBar: LuxeBottomNav(index: _i, onChanged: (v) => setState(() => _i = v)),
    );
  }
}
```
(If `HistoryScreen`/`SettingsScreen` are not `const`-constructible, drop `const`.)

- [ ] **Step 2: Splash → AppShell.** In `splash_screen.dart`, change the post-delay navigation target from `CameraScreen` to `const AppShell()`. In `main.dart`, ensure home route leads to splash → AppShell. Settings screen AppBar title → "Profil".

- [ ] **Step 3: Delete map picker.** `git rm lib/screens/map_picker/map_picker_screen.dart`. Grep for remaining imports: `grep -rn map_picker lib` → must be empty (Task 9 removed the camera import).

- [ ] **Step 4: analyze + commit**

Run: `flutter analyze` (whole project) → 0 errors (pre-existing infos OK).
```bash
git add lib/screens/shell lib/screens/settings/settings_screen.dart lib/main.dart lib/screens/splash/splash_screen.dart
git rm lib/screens/map_picker/map_picker_screen.dart
git commit -m "feat(radjak): app shell bottom-nav, splash->Home, profil; remove map picker"
```

---

## Task 13: Dashboard widget test

**Files:** Test `test/home_screen_test.dart`.

- [ ] **Step 1: Write the test** (seed sqflite-ffi, pump HomeScreen, expect stat values + CTA)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeproof/models/photo_record.dart';
import 'package:timeproof/services/database_service.dart';
import 'package:timeproof/services/settings_service.dart';
import 'package:timeproof/screens/home/home_screen.dart';

void main() {
  setUpAll(() async { sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('id_ID', null); SharedPreferences.setMockInitialValues({}); });

  testWidgets('dashboard shows CTA + recent visit', (t) async {
    await DatabaseService.instance.debugReset();
    await SettingsService.instance.load();
    await DatabaseService.instance.insert(PhotoRecord(id:'a', imagePath:'/x.jpg', address:'',
      latitude:0, longitude:0, accuracy:0, timestamp: DateTime.now(), verificationCode:'a',
      customText:'', imageHash:'H', facility:'RS Mitra Keluarga', visitType:'Sales Visit', trackingNumber:'TP-2026-000017'));
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: HomeScreen())));
    await t.pumpAndSettle();
    expect(find.text('Mulai Kunjungan'), findsOneWidget);
    expect(find.text('RS Mitra Keluarga'), findsOneWidget);
    expect(find.text('TP-2026-000017'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run → pass.** `flutter test test/home_screen_test.dart` → PASS.

- [ ] **Step 3: Commit**

```bash
git add test/home_screen_test.dart
git commit -m "test(radjak): dashboard renders stats + recent visit"
```

---

## Task 14: Version bump + full verify + build

**Files:** Modify `pubspec.yaml`.

- [ ] **Step 1: Bump version** → `version: 2.0.0+3000`.

- [ ] **Step 2: Full analyze + tests.**
Run: `flutter analyze` → 0 errors. `flutter test` → all pass (luxe, db stats, home, overlay golden, tracking, version, smoke). Fix any breakage (e.g. smoke/golden expectations) before proceeding.

- [ ] **Step 3: Build.**
```
flutter build apk --release --split-per-abi
flutter build apk --release
```
Verify (aapt) arm64: package `com.radjak.marketing`, versionName `2.0.0`, versionCode `5000` (base 3000 + 2000), label "Radjak Marketing".

- [ ] **Step 4: Commit version**
```bash
git add pubspec.yaml
git commit -m "chore(radjak): v2.0.0"
git push origin radjak-app
```

---

## Task 15: Release v2.0.0 (user-confirmed)

**Files:** none (publish step).

- [ ] **Step 1: Stage assets** as `RadjakMarketing-<abi>.apk` (arm64/armeabi-v7a/x86_64/universal), write notes.
- [ ] **Step 2: Publish** `gh release create v2.0.0 --repo alfarabiki/Radjak-Marketing --target main --title "Radjak Marketing v2.0.0" --notes-file <notes> <4 apks>`.
- [ ] **Step 3: Verify** `gh api repos/alfarabiki/Radjak-Marketing/releases/latest --jq .tag_name` == `v2.0.0`, 4 assets.

> Do NOT publish without explicit user confirmation. TimeProof (`Time-Tracks`) stays untouched.

---

## Self-Review Notes

- **Spec coverage:** dashboard-first (T7,T12), Light Luxe theme (T3) + luxe kit (T4), Fraunces+Inter (T1,T3), transparent logo (T2,T6), blue accent line / gold TP (T6), no "Ubah Data" (T10), no map (T9,T12), Start-Visit form (T8), premium history/detail (T11), stat queries (T5), splash→Home (T12), v2.0.0 release (T14,T15). All spec sections mapped. RBAC/iOS correctly deferred (no task).
- **Type consistency:** `CameraScreen({facility,visitType,staffName})` (T8 call ↔ T9 def); `PhotoDetailScreen({required PhotoRecord record})` (T7/T11 — verify existing signature, adapt once); `StatTile(value,label,icon,gold)`, `PrimaryGradientButton(title,subtitle,icon,onTap)`, `VisitTile(facility,meta,trackingNumber,chip,onTap)`, `LuxeBottomNav(index,onChanged)` used consistently; `DatabaseService.countToday/countThisMonth/recent/debugReset` defined T5, used T7/T13.
- **Ordering caveat (flagged in tasks):** Tasks 7 & 8 cross-reference (Home→StartVisit→Camera). Implement T4,T5 → T8,T9 (camera ctor) → T7 (home) → T10,T11,T12, so analyze passes. Subagent controller should follow this order.
- **No placeholders:** every code step has real code; asset/font acquisition has concrete URLs + fallback + BLOCKED instruction.
