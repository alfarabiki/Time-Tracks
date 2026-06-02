TimeProof MVP

Aplikasi Android untuk dokumentasi kehadiran, kunjungan lapangan, survey, inspeksi, dan aktivitas kerja dengan bukti foto yang memiliki:

Timestamp
Alamat otomatis
Koordinat GPS
Kode Verifikasi
Custom Text
Template Overlay
Export Foto
Riwayat Foto
Objective

Membuat aplikasi Android ringan yang dapat:

Mengambil foto dari kamera
Menampilkan informasi lokasi pada foto
Menampilkan waktu pada foto
Menampilkan kode verifikasi unik
Menambahkan custom wording
Memilih titik lokasi secara manual
Menyimpan hasil foto ke galeri
Berjalan offline setelah instalasi

Target:

MVP 2-3 minggu development
APK Android 8 sampai Android 15
Tidak membutuhkan backend kompleks
Technology Stack
Frontend

Framework:

Flutter 3.x

Reason:

Single codebase
APK kecil
Support Android lama
Mudah publish

Packages:

camera
geolocator
geocoding
google_maps_flutter
image
path_provider
permission_handler
uuid
shared_preferences
Backend MVP

Pilihan 1 (Recommended)

Tidak ada backend.

Semua data tersimpan lokal.

Storage:

SQLite
atau
Hive

Keuntungan:

Cepat
Murah
Offline
Backend V2

Jika nanti diperlukan sinkronisasi:

NestJS
PostgreSQL
Docker

atau

Firebase
Core Features
Feature 1

Take Photo

User membuka kamera.

Flow:

Open App
↓
Camera Preview
↓
Take Photo
↓
Generate Overlay
↓
Save Image
Feature 2

Timestamp

Format:

Selasa, 02 Juni 2026 22:21

Format Indonesia.

Contoh:

DateFormat(
"EEEE, dd MMMM yyyy HH:mm",
"id_ID"
)
Feature 3

GPS Coordinate

Contoh:

6.185037°S, 106.863431°E

Data dari:

Geolocator.getCurrentPosition()
Feature 4

Address Lookup

Reverse Geocoding.

Contoh:

Gg. S No.7,
RT.4/RW.13,
Cempaka Putih Barat,
Kec. Cempaka Putih,
Jakarta Pusat,
DKI Jakarta 10520

Menggunakan:

placemarkFromCoordinates()
Feature 5

Verification Code

Generate random.

Format:

PDMM1DM1YHEYRG

Panjang:

14-16 karakter

Generator:

UUID

atau

Random Alpha Numeric
Feature 6

Custom Wording

User dapat menambahkan text.

Contoh:

Sales Visit

atau

Maintenance Site

atau

Audit Internal

Field editable.

Feature 7

Template Overlay

Template dapat diubah.

Contoh:

Template A

Tanggal
Alamat
Koordinat
Kode

Template B

Tanggal
Nama Pegawai
Lokasi
Koordinat

Template C

Custom Layout
Feature 8

Manual Location Picker

User dapat memilih titik sendiri.

Flow:

Current GPS
↓
Open Map
↓
Move Pin
↓
Confirm
↓
Generate Address

Menggunakan:

Google Maps Flutter
Overlay Design

Layout meniru TimeMark.

Contoh:

----------------------------------

Selasa, 02 Juni 2026 22:21

Jl. Sudirman No.10
Jakarta Selatan
DKI Jakarta

6.185037°S,106.863431°E

Kode Foto:
PDMM1DM1YHEYRG

----------------------------------
Overlay Configuration

Semua dapat diaktifkan/nonaktifkan.

Setting:

{
  "showTime": true,
  "showAddress": true,
  "showCoordinate": true,
  "showVerification": true,
  "showCustomText": true
}
Database Structure

Table:

PhotoHistory

CREATE TABLE photo_history(
 id TEXT PRIMARY KEY,
 image_path TEXT,
 address TEXT,
 latitude DOUBLE,
 longitude DOUBLE,
 timestamp DATETIME,
 verification_code TEXT,
 custom_text TEXT
);
Screen Design
Splash Screen
Logo
↓
Masuk Kamera
Camera Screen
+-------------------+
| Camera Preview    |
|                   |
|                   |
+-------------------+

[Take Photo]

[Template]

[Map]
Preview Screen
Photo Preview

[Save]
[Retake]
History Screen
List Foto

Foto 1
Foto 2
Foto 3
Settings Screen
Template
Custom Text
Watermark
Location Mode
Folder Structure
lib/

├── main.dart

├── screens
│
├── camera
│
├── history
│
├── settings
│
├── map_picker
│
├── services
│
├── widgets
│
└── models
Service Layer
Location Service
getCurrentLocation()
Geocoding Service
getAddress()
Verification Service
generateCode()
Overlay Service
drawOverlay()

Menggunakan package:

image

Untuk menulis text langsung ke foto.

Permissions

Android Manifest

CAMERA

ACCESS_FINE_LOCATION

ACCESS_COARSE_LOCATION

READ_MEDIA_IMAGES

WRITE_EXTERNAL_STORAGE
Export

Simpan ke:

/DCIM/TimeProof/

Format:

IMG_20260602_222100.jpg

### Workflow Skills (trigger-based)
| Trigger | Skill to Invoke |
|---------|----------------|
| Planning a feature / module | `make-plan` |
| Executing a plan | `do` |
| Any bug / test failure | `superpowers:systematic-debugging` |
| Implementing any feature | `superpowers:test-driven-development` |
| Before claiming work is done | `superpowers:verification-before-completion` |
| After major feature complete | `superpowers:requesting-code-review` |
| Building UI / dashboard | `ui-ux-pro-max` |
| 2+ independent tasks | `superpowers:dispatching-parallel-agents` |
| New feature design / architecture | `superpowers:brainstorming` |
| Exploring codebase | `smart-explore` |
| Searching past solutions | `mem-search` |
| Auth / RBAC / security decisions | `Security.md` rules (auto-applied) |
| Deployment / CI/CD | `vercel:deploy` + `vercel:deployments-cicd` |
| Updating CLAUDE.md | `claude-md-management:revise-claude-md` |
| **After ANY new feature** | **`qa-skills:/run-qa smoke` (MANDATORY auto-QA)** |
| Adversarial/edge-case audit | `qa-skills:/run-qa adversarial` |
| UX audit (flow friction) | `qa-skills:/run-qa ux` |
| Full QA sweep before release | `qa-skills:/run-qa all` |