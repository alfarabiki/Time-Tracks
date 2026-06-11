# Radjak Marketing MVP — Design Spec

Date: 2026-06-11
Branch: `feature/radjak-mvp`
Target release: v1.4.0
Status: Approved (design)

## Context

Aplikasi saat ini = **TimeProof MVP**: Flutter standalone, tanpa backend, simpan lokal (SQLite). Kamera → watermark overlay (waktu, alamat, GPS, akurasi, kode verifikasi, custom text) → simpan galeri + riwayat. Sudah ada auto-update + kill switch via GitHub.

Dokumen `android/Enchancement.md` mendeskripsikan platform enterprise penuh (NestJS + PostgreSQL + Redis + S3, RBAC 4 peran, portal manajer/admin, route tracking, anti-fake-GPS, KPI/MPI, approval, analitik, FCM, 10k+ user). Gap dengan kondisi sekarang sangat besar.

Keputusan: ambil **"intinya"** = akuntabilitas bukti kunjungan marketing rumah sakit ber-brand Radjak, **offline / tanpa backend**, ringan. Sisanya ditunda.

## Goals (in scope)

1. **Rebranding Radjak** — tema UI biru-emas terang + logo Radjak di setiap foto.
2. **Field kunjungan** — Nama Staf, Faskes/Tujuan, Jenis Kunjungan.
3. **Nomor Tracking** `TP-YYYY-NNNNNN` berurutan, jadi kode utama di foto.
4. **Riwayat** menampilkan field baru.

## Non-goals (ditunda, JANGAN dikerjakan sekarang)

Backend, login/JWT, RBAC, portal manajer/admin, route tracking GPS kontinu, anti-fake-GPS, KPI/MPI engine, approval workflow, analitik, notifikasi FCM, audit logs. Struktur data dibuat rapi agar siap-sinkron di fase berikutnya.

## Design

### 1. Tema aplikasi (biru Radjak terang)

`lib/utils/app_theme.dart` ditulis ulang dari dark-amber → light corporate:

| Token | Nilai |
|------|-------|
| primary | `#1E40AF` (Biru Radjak) |
| secondary | `#3B82F6` (Hospital Blue) |
| accent/gold | `#D4AF37` (Luxury Gold) |
| background | `#FFFFFF` |
| surface | `#F8FAFC` |
| text primary | `#111827` |
| text secondary | `#6B7280` |

- Tombol biru (foreground putih), aksen emas pada highlight, kartu rounded-16, soft shadow.
- `showAppMessage` snackbar disesuaikan ke palet baru.
- Layar pratinjau tetap berlatar hitam (kontras foto) — hanya aksen di-update.
- Nama tampilan app → **"Radjak Marketing"** (label launcher + judul AppBar/splash).
- **applicationId tetap `com.timeproof.app`** — wajib, agar auto-update di HP existing tidak putus.

### 2. Aset logo

- Konversi `Rumah_Sakit_Radjak_Hospital_Salemba.webp` → `assets/branding/radjak_logo.png` (versi warna, untuk header putih) + opsional `radjak_logo_mono.png`.
- Daftarkan di `pubspec.yaml` (`assets/branding/`).
- Splash & header overlay memakai aset ini.

### 3. Watermark foto — Layout B

Overlay = widget Flutter (`timemark_overlay.dart`) yang di-screenshot via RepaintBoundary di `preview_screen.dart`. Logo cukup `Image.asset` di dalam overlay → otomatis ikut terbakar ke JPEG. Tidak perlu menggambar via package `image`.

```
┌─ [logo] RADJAK HOSPITAL · Salemba ──────┐   header: pita PUTIH, garis bawah emas
│                                          │   (putih agar logo warna terbaca)
│            [ FOTO 3:4 ]                   │
│                                          │
├──────────────────────────────────────────┤   pita bawah: gelap transparan (existing)
│ Senin, 11 Jun 2026 14:32                 │
│ Jl. Salemba Raya, Jakarta Pusat          │
│ 6.18°S,106.86°E  ±5m                     │
│ Budi S. · Sales Visit · RS Mitra Keluarga│
│ TP-2026-000017                           │
└──────────────────────────────────────────┘
```

- Header putih (bukan biru) supaya logo multi-warna Radjak terbaca jelas; garis bawah tipis emas sebagai aksen brand.
- Semua elemen tetap bisa di-on/off lewat Settings (toggle existing + toggle baru untuk header & field kunjungan).
- Baris baru di pita bawah: `Nama Staf · Jenis Kunjungan · Faskes`.
- Baris kode: `TP-YYYY-NNNNNN` (menggantikan tampilan "Kode Foto" acak).

### 4. Field kunjungan

- **Nama Staf**: disimpan di profil (Settings), default muncul tiap foto. Bisa di-override per foto di sheet "Ubah Data".
- **Faskes/Tujuan**: teks bebas per foto; tampilkan saran dari nilai terakhir (shared_preferences "last facility").
- **Jenis Kunjungan**: dropdown — `Sales Visit, Maintenance, Audit Internal, Follow-up, Survey, Lainnya`. Default `Sales Visit`.
- Input di sheet "Ubah Data" pada `preview_screen.dart` (perluas form yang sudah ada).

### 5. Nomor Tracking

- Format `TP-{YYYY}-{NNNNNN}` (6 digit, zero-padded).
- Counter berurutan tersimpan lokal (shared_preferences), key per tahun; reset otomatis saat tahun berganti.
- Service baru `TrackingService.next(timestamp)` → mengembalikan & menaikkan counter (pure-testable core untuk format/increment).
- Tahun diambil dari `CaptureData.timestamp` (bukan jam sistem langsung) agar konsisten dengan foto.
- Kode verifikasi acak lama disembunyikan default (toggle off); **SHA256 image hash tetap dihitung & disimpan** untuk integritas/anti-ubah.

### 6. Database

Tabel `photo_history` ditambah kolom:

```sql
ALTER TABLE photo_history ADD COLUMN staff_name TEXT;
ALTER TABLE photo_history ADD COLUMN facility TEXT;
ALTER TABLE photo_history ADD COLUMN visit_type TEXT;
ALTER TABLE photo_history ADD COLUMN tracking_number TEXT;
```

- Naikkan `DatabaseService` version; `onUpgrade` menjalankan `ALTER TABLE` (aman jika kolom sudah ada → bungkus try-catch per kolom).
- `PhotoRecord` + `toMap`/`fromMap` ditambah keempat field (fromMap fallback-safe untuk record lama: string kosong).
- Layar riwayat & detail foto menampilkan field baru bila ada.

### 7. CaptureData / OverlaySettings

- `OverlaySettings`: tambah `staffName`, `showHeader` (default true), `showVisitInfo` (default true), `showVerification` default → false. copyWith/toJson/fromJson fallback-safe.
- `CaptureData`: tambah `facility`, `visitType`, `trackingNumber` (diisi saat capture/preview).

## Versioning & branch

- Branch `feature/radjak-mvp`; merge ke `main` setelah disetujui + QA.
- Rilis **v1.4.0** (minor: fitur baru, kompatibel). versionName 1.4.0; versionCode mengikuti pola pubspec + ABI offset.

## Testing

- **Unit**: `TrackingService` (format `TP-2026-000001`, increment, reset tahun baru).
- **Golden**: render overlay Layout B (header Radjak + field kunjungan + tracking number) → `test/goldens/`.
- **Migrasi DB**: buka DB versi lama → upgrade → kolom baru ada, record lama terbaca.
- Manual: `flutter analyze` bersih; build splits + universal; verifikasi versionCode naik.

## Files (perkiraan)

`lib/utils/app_theme.dart`, `lib/widgets/timemark_overlay.dart`, `lib/models/overlay_settings.dart`, `lib/models/capture_data.dart`, `lib/models/photo_record.dart`, `lib/services/database_service.dart`, `lib/services/photo_save_service.dart`, `lib/services/tracking_service.dart` (baru), `lib/services/settings_service.dart`, `lib/screens/preview/preview_screen.dart`, `lib/screens/settings/settings_screen.dart`, `lib/screens/history/*`, `lib/screens/splash/splash_screen.dart`, `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml` (label) / `strings`, `assets/branding/*`, `test/*`.
