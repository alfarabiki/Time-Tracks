# Radjak Marketing v2.0 — Premium Redesign Spec

Date: 2026-06-12
Branch: `radjak-app`
Target release: v2.0.0 (repo `alfarabiki/Radjak-Marketing`, package `com.radjak.marketing`)
Status: Approved (design + mockup)
Mockup reference: `build/mockup/design.html` (Light Luxe dashboard + photo result)

## Context

Radjak Marketing currently shares TimeProof's structure (camera-first, utilitarian dark UI). User feedback: make it a **distinct premium product** ("1 million dollar design"), not a TimeProof reskin. TimeProof itself stays untouched (see [[two-app-architecture]]).

## Goals (in scope)

1. **Dashboard-first re-architecture** — app opens to a premium Home, not the camera.
2. **Light Luxe visual system** — Corporate Healthcare: white bg, glassmorphism cards, Radjak blue + gold accents.
3. **Premium typography** — Fraunces (serif headings/big numbers) + Inter (body/data), bundled offline.
4. **Integrity hardening** — remove the "Ubah Data" editor (no editing time/address/coords/data) and remove manual map location pick (GPS-only).
5. **Refined photo overlay** — header = transparent Radjak logo PNG only (no white band, no text); bottom bar premium (Inter), left accent line in **Radjak blue**, tracking number in **gold**.

## Non-goals (deferred — DO NOT build now)

- **RBAC / login / roles / manager-admin portal** — needs auth + backend; user said "nanti". Keep data model RBAC-friendly (staff in profile) but no auth now.
- iOS (separate phase — see [[ios-support-roadmap]]).
- Online sync / backend.

## Design system (Light Luxe)

| Token | Value |
|------|-------|
| primary (Biru Radjak) | `#1E40AF` |
| secondary (Hospital Blue) | `#3B82F6` |
| accent-blue (on-dark, overlay line) | `#4F9DF7` |
| gold | `#D4AF37` |
| bg | `#FFFFFF` |
| surface | `#F8FAFC` |
| card line | `#E8EDF5` |
| text primary / secondary | `#111827` / `#6B7280` |

- Cards: translucent white + `backdrop-filter: blur` (glassmorphism), radius **20**, soft shadow `rgba(30,64,175,.06–.14)`, optional thin gold top-border for highlight cards.
- Headings & large numbers: **Fraunces** (weight 600). Body, labels, data, coordinates, tracking: **Inter** (tabular figures for numbers).
- Reusable widgets (new): `LuxeCard`, `StatTile`, `PrimaryGradientButton`, `SectionHeader`, `VisitTile`, `LuxeBottomNav`, `LuxeScaffold`.

## Screens & flow (new — replaces camera-first)

1. **Home / Dashboard** (`home_screen.dart`, new — app entry after splash):
   - Header: Radjak logo (left) + avatar/initials (right).
   - Greeting (Fraunces): "Selamat pagi, <Nama Staf>"; subtitle date + role/branch.
   - Two glass stat cards: **Kunjungan hari ini** (count today), **Total bulan ini** (count this month). Gold-accent on the second.
   - **"Mulai Kunjungan"** primary gradient button → Start Visit flow.
   - "Kunjungan Terakhir" — recent visits (VisitTile: faskes, time·jenis, gold tracking number, day chip) → tap opens detail.
   - Bottom nav (glass): Beranda · Riwayat · Profil.
2. **Start Visit** (`start_visit_sheet.dart`/screen, new): form — Faskes/Tujuan (text), Jenis Kunjungan (dropdown). Staff auto from profile. "Lanjut → Kamera". *(This is the only place visit info is entered; it is NOT editable after capture.)*
3. **Camera** (`camera_screen.dart`, restyled premium): GPS auto; **no map button**; shutter/flip retained, styled to Light Luxe chrome. Receives the visit data from Start Visit.
4. **Preview** (`preview_screen.dart`, locked): photo + overlay; actions **Simpan / Ambil Ulang only**. Remove `_openEditor`/"Ubah Data" entirely (no editing of date/address/coords/custom). Tracking number assigned here (existing logic).
5. **History** (`history_screen.dart`, premium): timeline grouped by date, VisitTile styling, shows tracking + jenis + faskes; tap → detail (`photo_detail_screen.dart`, restyled).
6. **Profile / Settings** (`profile_screen.dart` wrapping current settings): staff name, overlay toggles (header/visit-info/watermark + sizes), about + check-update. Light Luxe styling.

Splash → Home (not camera).

## Photo overlay (timemark_overlay.dart changes)

- **Header**: replace the white band with a **transparent Radjak logo PNG only** (top-left, no background, no "RADJAK HOSPITAL · Salemba" text). Gated by `showHeader`.
- **Bottom info bar**: Inter font, tabular figures, refined spacing. Left accent border = **`#4F9DF7`** (Radjak blue, replaces gold line). Rows: date · address · `coords · ±Nm` · `Staff · Jenis · Faskes` · tracking. **Tracking number stays gold `#D4AF37`.**
- **Corner**: "Radjak / Verified" (kept from v1.4.1; Fraunces brand + small "Verified").
- Baked via existing RepaintBoundary capture.

## Assets

- **Transparent logo PNG**: produce `assets/branding/radjak_logo.png` with transparent background (current `.webp` has a white background — must be removed/converted). Used in overlay header + dashboard. Keep `.webp` for places where white bg is fine, but overlay/header use the transparent PNG.
- **Fonts**: bundle **Fraunces** (e.g. `Fraunces.ttf` variable or 400/600/700) and **Inter** (`Inter.ttf` 400/500/600/700) under `assets/fonts/`, registered in `pubspec.yaml`. Inter already partially referenced; ensure both ship.

## Data (local, SQLite — RBAC-ready but no auth)

New `DatabaseService` queries:
- `countToday()` — visits where timestamp within today.
- `countThisMonth()` — visits in current calendar month.
- `recent(int n)` — latest n PhotoRecords.
Dashboard reads these; all offline. No schema change required beyond v2 columns already added (staff/facility/visit_type/tracking_number).

## Removed

- `lib/screens/map_picker/map_picker_screen.dart` (+ its nav entry / manual-location code paths in camera & preview).
- `_openEditor()` "Ubah Data" sheet in preview (and the edit affordances).

## Versioning & release

- `radjak-app` branch. Release **v2.0.0** to repo `Radjak-Marketing` (assets `RadjakMarketing-<abi>.apk`). pubspec `2.0.0+3000` (versionCode base 3000 → arm64 5000 > current 4012). TimeProof (`Time-Tracks`, `main`) untouched.

## Testing

- **Golden**: overlay v2 (transparent logo header, blue accent line, gold tracking) — regenerate `test/goldens/`.
- **Widget**: Home dashboard renders stat cards + CTA + recent list from a seeded in-memory dataset; bottom nav present.
- **Unit**: `DatabaseService.countToday/countThisMonth/recent` against an in-memory sqflite (or seeded records).
- Existing tracking/version/round-trip tests stay green (update brand expectations already done in v1.4.1).
- `flutter analyze` clean; build splits + universal; verify arm64 vc 5000, package `com.radjak.marketing`, label "Radjak Marketing".

## Files (estimate)

Create: `lib/screens/home/home_screen.dart`, `lib/screens/start_visit/start_visit_screen.dart`, `lib/widgets/luxe/*` (luxe_card, stat_tile, primary_button, section_header, visit_tile, bottom_nav), `assets/branding/radjak_logo.png`, `assets/fonts/Fraunces.ttf`, `assets/fonts/Inter.ttf`.
Modify: `lib/utils/app_theme.dart` (Fraunces/Inter + luxe tokens), `lib/main.dart` (splash → Home), `lib/screens/splash/splash_screen.dart`, `lib/screens/camera/camera_screen.dart` (premium chrome, remove map, accept visit data), `lib/screens/preview/preview_screen.dart` (locked, remove editor), `lib/screens/history/*` (premium), `lib/screens/settings/settings_screen.dart` → Profile, `lib/widgets/timemark_overlay.dart` (transparent logo header, blue line), `lib/models/overlay_settings.dart` (fontFamily default → Inter), `lib/services/database_service.dart` (stat queries), `pubspec.yaml` (fonts + version).
Delete: `lib/screens/map_picker/map_picker_screen.dart`.
