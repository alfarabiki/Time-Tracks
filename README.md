# TimeProof

Aplikasi Android untuk dokumentasi kehadiran, kunjungan lapangan, survey, inspeksi,
dan aktivitas kerja dengan **bukti foto** ber-overlay: timestamp, alamat, koordinat
GPS, dan kode verifikasi unik — meniru template **Timemark**.

Single codebase Flutter, berjalan **offline** setelah instalasi, mendukung
**Android 8 (API 26) s/d Android 15**.

---

## 1. Prasyarat

- **Flutter 3.24+** (stable). Cek: `flutter --version`
- **Android SDK** (via Android Studio) — Platform 35 + Build-Tools terbaru
- Perangkat/emulator Android 8+

> Saat repo ini dibuat, Flutter belum terpasang di mesin. Pasang dulu:
> https://docs.flutter.dev/get-started/install/windows

## 2. Setup Pertama Kali

Karena proyek di-_author_ manual, jalankan sekali untuk membuat **Gradle wrapper**
(`gradlew`, `gradle-wrapper.jar`) dan file platform yang hilang. Perintah ini
**tidak menimpa** file yang sudah ada (lib, AndroidManifest, dll.):

```powershell
cd "d:\Al Farabi\Timetrack"
flutter create . --platforms=android --org com.timeproof --project-name timeproof
flutter pub get
```

## 3. Google Maps API Key (gratis)

Map Picker memakai **Maps SDK for Android** (tier gratis). Reverse-geocoding (alamat)
memakai geocoder bawaan Android — **tidak** butuh API berbayar.

1. Buka https://console.cloud.google.com/ → buat Project (mis. `TimeProof`).
2. **APIs & Services → Library →** aktifkan **Maps SDK for Android**.
3. **Credentials → Create Credentials → API key**.
4. (Disarankan) batasi key: Application restriction → **Android apps**
   - Package name: `com.timeproof.app`
   - SHA-1: jalankan `cd android && ./gradlew signingReport` lalu salin SHA-1 `debug`.
5. Tempel key di [`android/app/src/main/res/values/secrets.xml`](android/app/src/main/res/values/secrets.xml)
   menggantikan `YOUR_GOOGLE_MAPS_API_KEY`.

> Tanpa key, seluruh aplikasi tetap berjalan; hanya tampilan peta di Map Picker yang
> kosong. Sebagai cadangan tersedia input **koordinat manual** di layar peta.

## 4. Menjalankan

```powershell
flutter run               # debug ke perangkat
flutter build apk --release
```

APK hasil: `build/app/outputs/flutter-apk/app-release.apk`

---

## Struktur Proyek

```
lib/
├── main.dart                      # entry, init locale/log/settings, error guard
├── models/
│   ├── photo_record.dart          # baris tabel photo_history (+ hash, accuracy)
│   ├── overlay_settings.dart      # toggle, template, kualitas, branding
│   └── capture_data.dart          # data capture sementara + DRAFT recovery
├── services/
│   ├── location_service.dart      # GPS + timeout 15s + izin (Feature 3)
│   ├── geocoding_service.dart     # reverse geocode, offline-first (Feature 4)
│   ├── verification_service.dart  # kode acak 14 char (Feature 5)
│   ├── database_service.dart      # sqflite photo_history (+ index)
│   ├── gallery_service.dart       # simpan ke /DCIM/TimeProof (gal)
│   ├── photo_save_service.dart    # composite→JPEG→SHA256→galeri→DB
│   ├── settings_service.dart      # shared_preferences
│   ├── draft_service.dart         # recovery foto belum selesai
│   ├── storage_service.dart       # cek sisa storage (StatFs via MethodChannel)
│   └── log_service.dart           # log internal 30 hari
├── widgets/
│   └── timemark_overlay.dart      # OVERLAY persis template gambar (dinamis)
├── screens/
│   ├── splash/                    # logo → kamera
│   ├── camera/                    # preview kamera, shutter, peta, template
│   ├── preview/                   # composite overlay + Simpan/Ambil Ulang
│   ├── history/                   # daftar + detail (hash, koordinat)
│   ├── settings/                  # toggle, template, kualitas, branding, log
│   └── map_picker/                # Google Maps + pin tengah (Feature 8)
└── utils/                         # konstanta, format tanggal id_ID, tema
```

## Pemetaan Fitur (CLAUDE.md)

| Fitur | Implementasi |
|---|---|
| 1. Take Photo | `camera_screen.dart` (ResolutionPreset.veryHigh = 1080p) |
| 2. Timestamp | `format_utils.dart` → `EEEE, dd MMMM yyyy HH:mm` (id_ID) |
| 3. GPS Coordinate | `location_service.dart` → `6.185037°S, 106.863431°E` |
| 4. Address Lookup | `geocoding_service.dart` (gaya Indonesia, offline-safe) |
| 5. Verification Code | `verification_service.dart` (14 char A–Z0–9, acak) |
| 6. Custom Wording | Settings → `customText` |
| 7. Template Overlay | Template A/B/C di Settings |
| 8. Manual Location Picker | `map_picker_screen.dart` |
| Overlay | `timemark_overlay.dart` — meniru gambar Timemark |
| Database | `database_service.dart` (tabel `photo_history`) |
| Export | `/DCIM/TimeProof/IMG_yyyyMMdd_HHmmss.jpg` |

## Pemenuhan Quality Requirements

| Target | Penanganan |
|---|---|
| Stabilitas / tanpa force-close | Semua I/O & permission dibungkus try/catch + pesan ramah; `FlutterError.onError` global |
| GPS mati / izin ditolak / timeout 15s | Dialog "Tanpa lokasi / Pilih di peta", tidak freeze |
| Internet mati | Offline-first: alamat di-skip, koordinat tetap tampil |
| Kamera gagal | UI error + tombol "Coba lagi" / "Buka Pengaturan" |
| Storage penuh | Peringatan < 500 MB (StatFs) + tangani gagal simpan |
| Dynamic layout & font scaling | Overlay proporsional ke lebar; alamat auto-wrap (tak terpotong) |
| Image quality | JPEG 95/90/80% (default 90%), capture upscale ke resolusi asli |
| Battery | GPS sekali pakai, tanpa continuous tracking |
| ≤ 3 klik | Foto → Simpan |
| Recovery | Draft tersimpan; saat dibuka lagi "Lanjutkan foto sebelumnya?" |
| Logging | `log_service.dart`, retensi 30 hari (lihat di Settings) |
| Security (anti-ubah) | **SHA256** tiap foto disimpan di DB & ditampilkan di Detail |
| Device compat | minSdk 26, targetSdk 34, compileSdk 35 |

## Catatan Teknis

- **Overlay** dirender sebagai widget Flutter (Roboto, ikon, teks vertikal, bar amber)
  lalu di-_composite_ ke foto via `RepaintBoundary.toImage` — hasil jauh lebih mirip
  contoh dibanding menggambar teks dengan package `image`.
- **Kode verifikasi = id** record (unik).
- Foto disimpan 2 tempat: salinan aplikasi (untuk riwayat & integritas) dan galeri
  album `TimeProof` (untuk dibagikan).

## Roadmap V2 (opsional)

Sinkronisasi cloud (NestJS + PostgreSQL atau Firebase), share foto, watermark logo,
multi-bahasa.
