# Konco Space Employee Cashier App

Aplikasi Flutter Android untuk kasir & staff **Konco Space** coffee shop. Berkomunikasi dengan backend Laravel melalui REST API. Tidak ada koneksi langsung ke database — semua data lewat API.

> **Wajib:** jalankan **`cofflow-webadmin` lebih dulu** (`php artisan serve --host=127.0.0.1 --port=8000`). Database dan API ada di sana; tanpa itu login akan gagal. Lihat [Quick Start](#quick-start-lokal).

---

## Quick Start (Lokal)

Urutan dari nol sampai app tampil di Chrome:

1. **Jalankan webadmin** di terminal 1 (setup pertama kali ada di README `cofflow-webadmin`):
   ```powershell
   cd ..\cofflow-webadmin
   php artisan serve --host=127.0.0.1 --port=8000
   ```
   Pastikan http://127.0.0.1:8000/login bisa dibuka.

2. **Install dependency employee** di terminal 2 (sekali saja):
   ```powershell
   cd ..\cofflow-employee
   flutter pub get
   ```

3. **Jalankan app** sesuai target:

   | Target | Perintah |
   |---|---|
   | Chrome (paling cepat untuk dev) | `flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api` |
   | Android emulator | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api` |
   | HP fisik (satu Wi-Fi) | `flutter run --dart-define=API_BASE_URL=http://<IP-LAN-laptop>:8000/api` |

   Untuk HP fisik, webadmin harus listen di semua interface: `php artisan serve --host=0.0.0.0 --port=8000`.

4. **Login** dengan akun di bagian [Test Account](#test-account).

5. **Berhenti:** tekan `q` di terminal Flutter, lalu `Ctrl+C` di terminal webadmin.

Log `[FcmService] init skipped: ... FirebaseOptions cannot be null` saat jalan di Chrome itu **normal** — push notification hanya aktif di Android dengan `google-services.json`. App tetap berfungsi.

---

## Fitur

### Role Kasir
- Login dengan akun staff (role `kasir` atau `admin`) — akun customer ditolak client-side
- **POS Walk-in** — grid menu 3 kolom, search, filter kategori, condiment selection
  - **Integrasi Condiment BOM**: Pemilihan condiment terhubung langsung dengan pemotongan stok bahan baku di backend (BOM menu + Condiment BOM).
  - **Multi-select**: tap menu berulang kali → menu sama tanpa condiment akan bump quantity baris yang sudah ada. Menu dengan condiment set berbeda dipisah jadi row tersendiri (bisa coexist).
  - Card layout pakai `Expanded` flex split (image flex 5 / text flex 4) + `childAspectRatio: 0.62` fixed → **no RenderFlex overflow di layar manapun** (sebelumnya overflow 17px di phone narrow). Hindari `LayoutBuilder` di sini karena bentrok dengan `RefreshIndicator` saat `CartController.notifyListeners` trigger setState (assert `_debugRelayoutBoundaryAlreadyMarkedNeedsLayout`).
- **Cart Page** (`/cart`) — tab di bottom nav (badge count item). List item, qty stepper per row, hapus per row, kosongkan all (confirm dialog), total + tombol "Lanjut ke Pembayaran". Replace bottom sheet lama.
- **Payment Mockup** (`/payment-mockup`) — halaman visual mockup metode bayar (Cash / QRIS / VA) untuk demo & design review. Tidak hit backend. Setelah "Bayar Sekarang" → success dialog → cart cleared → balik ke POS.
- **Pembayaran (real flow)** — Cash (real-time kembalian), QRIS (polling 3 detik), Virtual Account (polling 5 detik, tap to copy nomor VA). Trigger via `ConfirmPaymentScreen` (`/confirm-payment`) saat butuh persist ke backend.
- **Receipt** — nomor antrian format 3 digit dengan animasi elastic scale-in
- **Pesanan Masuk** — list pre-order dari Customer App, filter status, status transition (pending → processing → ready → completed), cancel dengan alasan
- **Order Detail** — info pelanggan, items + condiment, payment, timeline status log
- **Antrian Aktif** — auto-refresh tiap 10 detik, ready order highlight border hijau. Nomor antrian responsive: lebar kolom mengikuti panjang nomor dan otomatis mengecil (`FittedBox`) supaya tidak menimpa nama; ukuran font 28 / 34 / 40 untuk HP / tablet / desktop; nama panjang dipotong "…"

### Push Notification (FCM)
- `new_order` → auto-refresh daftar Pesanan Masuk + update badge count
- `order_status` → silent refresh order list
- Tap notifikasi → navigate ke Pesanan Masuk

### Out of Scope
- Admin features (CRUD menu, stok, pegawai) — dilakukan via Web Admin Dashboard
- Loyalty point system — dikelola di Web Admin + Customer App. Catatan: poin member diberikan backend otomatis saat kasir mengubah status pre-order customer menjadi **completed**, dan voucher customer kembali jika pesanan dibatalkan. Walk-in tidak mendapat poin.
- Customer App features

---

## Tech Stack

| Layer | Teknologi |
|-------|-----------|
| Framework | Flutter 3.44.x (Dart 3.12) — target Android; Chrome dipakai untuk dev lokal |
| Min Android SDK | 23 (`flutter_secure_storage` requirement) |
| State Management | `StatefulWidget` + `setState` + `ChangeNotifier` singleton |
| HTTP | `dio` ^5.4 |
| Routing | `go_router` ^13.0 |
| Secure Storage | `flutter_secure_storage` ^9.0 (EncryptedSharedPreferences) |
| Push Notification | `firebase_messaging` ^15.0 + `firebase_core` ^3.0 |
| Local Notification | `flutter_local_notifications` ^17.0 |
| Image | `cached_network_image` ^3.3 |
| Fonts | `google_fonts` ^6.0 (Poppins heading, Roboto body) |
| Loading Skeleton | `shimmer` ^3.0 |
| Format | `intl` ^0.19 |

---

## Struktur Folder

```
lib/
├── core/
│   ├── constants/          ← app_colors, app_typography, app_spacing, app_radius, app_constants
│   ├── theme/              ← app_theme.dart (Material 3, locked light mode)
│   ├── network/            ← api_client.dart (Dio + AuthInterceptor), api_endpoints.dart
│   ├── services/           ← auth, fcm, local_notification, notification_event_bus
│   └── utils/              ← currency_formatter, snackbar_helper, json_parse
│
├── features/
│   ├── auth/               ← services + screens (splash, login)
│   ├── pos/                ← models + services + state + screens (pos, condiment sheet,
│   │                          cart, payment mockup, confirm payment, qris, va, receipt)
│   ├── orders/             ← models + services + state + screens (incoming, detail, action helper)
│   └── queue/              ← service + screen
│
├── shared/widgets/         ← main_scaffold, brew_button, brew_text_field, status_badge,
│                              shimmer_loader, empty_state_widget, confirm_dialog
├── router/                 ← app_router.dart (go_router + ShellRoute + redirect)
└── main.dart
```

---

## Setup

### 1. Prerequisites

- **Flutter SDK 3.44.x** (Dart 3.12). Direkomendasikan install di path **tanpa spasi** (lihat Troubleshooting).
- **Android Studio** + Android SDK 23+ + emulator/device fisik
- **Firebase project** untuk FCM (atau lewati jika belum perlu push notification)
- Backend API running — `cofflow-webadmin` di `http://127.0.0.1:8000` (lokal) atau URL cloud
- Chrome (untuk `flutter run -d chrome`)

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Konfigurasi backend URL

Backend URL diatur via `--dart-define` saat build/run. **Jangan hardcode URL production di source code.**

```bash
# Chrome (web) di laptop yang sama dengan webadmin
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api

# Local development (Android emulator → host)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Local development (device fisik via LAN)
flutter run --dart-define=API_BASE_URL=http://<host-LAN-ip>:8000/api

# Production
flutter run --dart-define=API_BASE_URL=https://<api-host>/api
```

Default fallback (jika tidak ada `--dart-define`) = `http://10.0.2.2:8000/api` (Android emulator), di `lib/core/constants/app_constants.dart`. Untuk Chrome **wajib** isi `--dart-define`, karena `10.0.2.2` tidak bisa diakses dari browser.

### 4. Firebase setup (untuk FCM)

1. Buat Android app di Firebase Console dengan package name yang sama dengan `applicationId` di `android/app/build.gradle.kts`
2. Download `google-services.json` dari Firebase Console
3. Letakkan di `android/app/google-services.json`

**File `google-services.json` JANGAN di-commit ke repository public** — tambahkan ke `.gitignore`. File ini mengandung Firebase API key yang scope-nya bisa di-misuse jika auth rule lemah.

Jika belum siap pakai Firebase — `FcmService.initialize()` membungkus error dalam try/catch, app tetap jalan tanpa push. Tapi Gradle build TETAP butuh file ini ada (plugin `com.google.gms.google-services` enforce). Sementara bisa comment out plugin di `android/app/build.gradle.kts` dan `android/settings.gradle.kts`.

### 5. Run

```bash
flutter run --dart-define=API_BASE_URL=<your-api-url>
```

---

## Test Account

Akun staff dapat menggunakan akun seeded atau dibuat oleh admin via Web Admin Dashboard / tinker di backend. **App tidak menyediakan fitur register** (sesuai design — staff dikelola admin).

Kredensial seeded bawaan:
| Role | Email | Password |
|---|---|---|
| **Kasir** | `kasir@cofflow.test` | `password` |
| **Admin** | `admin@cofflow.test` | `password` |

Untuk testing role gate:
- Login akun dengan role `kasir` atau `admin` → masuk
- Login akun dengan role `customer` (misal: `customer@cofflow.test`) → ditolak: "Akun ini bukan akun staff"
- Login akun dengan `is_active = false` → ditolak: "Akun kamu dinonaktifkan"
- Wrong credentials → "Email atau password salah" (form tidak reset)

Jangan share credential test via channel public — gunakan password manager tim.

---

## Test Flow End-to-End

1. Login akun kasir → POS grid muncul
2. Tap menu tanpa condiment → langsung masuk cart (tap lagi = item line baru)
3. Tap menu dengan condiment → bottom sheet → pilih opsi wajib → Tambah
4. Tap beberapa menu berbeda → verify cart bar bawah update jumlah + total
5. Tap Cart Bar (atau tombol "Bayar") → masuk **Cart Page** (`/cart`)
6. Di Cart Page: ubah qty per item, hapus item, atau Kosongkan all → tombol "Lanjut ke Pembayaran"
7. **Payment Mockup** (`/payment-mockup`) muncul → pilih Cash/QRIS/VA → "Bayar Sekarang" → success dialog → cart cleared → balik ke /pos
8. (Real flow) Untuk persist ke backend: trigger `/confirm-payment` — pilih Cash → input uang → kembalian terhitung real-time → Konfirmasi → Receipt
9. Test QRIS real: pilih QRIS → QR muncul → batalkan via dialog
10. Test VA real: pilih VA + bank → nomor VA tampil → tap to copy
11. Tab Pesanan Masuk → pre-order dari Customer App → tap "Mulai Proses" → status flip ke "Diproses"
12. Tap card order → Order Detail → coba Batalkan dengan alasan
13. Tab Antrian → auto refresh 10 detik, order ready border hijau
14. Putar device ke landscape + test di berbagai ukuran (small phone 360dp, tablet 800dp) → POS card tidak overflow
15. Logout → token cleared → balik ke /login

---

## Keamanan

### Storage

- Auth token disimpan via `flutter_secure_storage` (Android: EncryptedSharedPreferences, AES-256 di Keystore)
- **Jangan simpan password user atau data sensitif lain di SecureStorage** — token saja
- Logout selalu hapus token + user data dari storage

### Network

- Semua API request via HTTPS di production
- `Authorization: Bearer <token>` di-attach via `AuthInterceptor` ke semua request authenticated
- Response 401 → otomatis clear token + redirect `/login` (handle token revoke / expiry)
- Timeout 30 detik (connect + receive) — tidak hang
- `cleartextTraffic="true"` di `AndroidManifest.xml` hanya untuk local dev — **matikan sebelum release** jika tidak butuh HTTP

### Role enforcement

- Client-side role gate: tolak `role == 'customer'` di login screen
- Backend juga enforce role (sudah handle oleh API) — client gate ini second layer
- 401 dari backend handle sebagai token revoked → force logout

### Secrets

- **Jangan commit** ke repository:
  - `google-services.json` (Firebase config)
  - `.env` file dengan API URL production
  - Signing keystore + passwords untuk release build
- URL production di-inject via `--dart-define`, bukan hardcode
- Release signing config harus pakai key terpisah dari debug

### Logging

- `LogInterceptor` Dio aktif HANYA di debug mode (`kDebugMode` flag). Otomatis off di release.
- Tidak ada `print` di production code untuk data sensitif

---

## Design System

| Token | Value | Pemakaian |
|-------|-------|-----------|
| Primary | `#3E2723` Espresso Brown | AppBar, tombol utama, badge processing |
| Secondary | `#F5F5DC` Oatmeal Cream | Background halaman |
| Accent | `#81C784` Matcha Green | Status "Siap", success, badge accent |
| Alert | `#E57373` Cinnamon Red | Error, status "Dibatalkan", stok kritis, cancel button |
| Heading | Poppins | AppBar title, card heading |
| Body | Roboto | Body text, table, form |
| Icon | Material Icons (`Icons.*`) | Semua icon |
| Logo | `assets/images/koncospace_logo.svg` | Login screen + kiri atas sidebar (tablet/desktop) |

App ini adalah **acuan tema** ekosistem Konco Space. Warna dan icon di `cofflow-customer` dan `cofflow-webadmin` mengikuti tabel di atas. Kalau mengubah warna di [lib/core/constants/app_colors.dart](lib/core/constants/app_colors.dart), samakan juga di `cofflow-customer/lib/main.dart` (`kBrand*`) dan `cofflow-webadmin/resources/css/app.css` (`@theme`).

---

## Routes

| Path | Screen | Auth | Notes |
|------|--------|------|-------|
| `/splash` | SplashScreen | open | check token, redirect |
| `/login` | LoginScreen | open | role gate kasir/admin |
| `/pos` | POSScreen | required | inside `ShellRoute` (bottom nav). Multi-select menu via repeated tap. |
| `/incoming-orders` | IncomingOrdersScreen | required | inside `ShellRoute`. Nav label = "Order" (badge pending count) |
| `/queue` | QueueScreen | required | inside `ShellRoute` |
| `/cart` | CartScreen | required | inside `ShellRoute` (bottom nav tab dengan badge count). Qty stepper, hapus, kosongkan, total |
| `/payment-mockup` | PaymentMockupScreen | required | visual mockup, **no backend call**. Cash/QRIS/VA radio + success dialog |
| `/confirm-payment` | ConfirmPaymentScreen | required | real payment flow, hit backend, uses cart singleton |
| `/qris-payment` | QRISPaymentScreen | required | extra: `Order` |
| `/va-payment` | VAPaymentScreen | required | extra: `Order` |
| `/receipt` | ReceiptScreen | required | extra: `{order, cash_received?}` |
| `/order-detail/:id` | OrderDetailScreen | required | full-screen detail |

Redirect logic: tidak ada token → `/login`. Sudah login + akses `/login` → redirect ke `/pos`.

---

## Build

### Debug
```bash
flutter run --dart-define=API_BASE_URL=<api-url>
```

### Release APK
```bash
flutter build apk --release --dart-define=API_BASE_URL=<api-url>
```

Hasil di `build/app/outputs/flutter-apk/app-release.apk`.

**Sebelum release:**
- Setup signing config di `android/app/build.gradle.kts` (jangan pakai debug keystore untuk release)
- Verifikasi `google-services.json` mengarah ke Firebase project production (bukan dev)
- Pastikan `API_BASE_URL` mengarah ke endpoint production HTTPS
- Pertimbangkan disable `cleartextTraffic` di `AndroidManifest.xml`

### Verify lint
```bash
flutter analyze
```

Expected: `No issues found!`

---

## Lisensi

Internal use only — Proyek **Konco Space**.
