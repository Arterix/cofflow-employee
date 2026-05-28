# Tasks — Cofflow Employee Cashier App

## Status Legend
- `[ ]` Belum dikerjakan
- `[~]` Sedang dikerjakan
- `[x]` Selesai

## Priority Legend
- **P0** = Blocker — harus selesai sebelum apapun
- **P1** = Core — harus selesai sebelum phase berikutnya
- **P2** = Important — diselesaikan setelah P1
- **P3** = Nice to have

> **Catatan:** Semua task di sini bergantung pada backend (`cofflow-api`) yang sudah berjalan.
> Pastikan `TASK-BE-001` hingga `TASK-BE-003` di spec backend sudah selesai dan dapat diakses sebelum memulai phase 2 ke atas.

---

## PHASE 1 — Foundation & Setup

### TASK-EMP-001: Project Setup
**Priority:** P0 | **Estimasi:** 1 hari | **Deps:** -

- [ ] Init Flutter project: `flutter create cofflow_employee`
- [ ] Update `pubspec.yaml` — tambahkan semua dependency sesuai `design.md §11`
- [ ] Jalankan `flutter pub get`, pastikan tidak ada error
- [ ] Buat struktur folder sesuai `design.md §2` secara lengkap
- [ ] Tambahkan `google-services.json` dari Firebase Console ke `android/app/`
- [ ] Konfigurasi `android/app/build.gradle` untuk Firebase dan minimal SDK 23
- [ ] Buat `lib/core/constants/app_colors.dart` sesuai `design.md §3.1`
- [ ] Buat `lib/core/constants/app_typography.dart` sesuai `design.md §3.2`
- [ ] Buat `lib/core/constants/app_spacing.dart` sesuai `design.md §3.3`
- [ ] Buat `lib/core/constants/app_radius.dart` (nilai: 8.0, 12.0, 16.0)
- [ ] Buat `lib/core/theme/app_theme.dart` — ThemeData lengkap menggunakan semua konstanta di atas
- [ ] Buat `lib/core/utils/currency_formatter.dart` — fungsi `formatRupiah(double amount)`
- [ ] Buat `lib/core/utils/snackbar_helper.dart` — `showErrorSnackbar` dan `showSuccessSnackbar`

**Acceptance:** `flutter run` berhasil, app tampil dengan warna dan font yang benar

---

### TASK-EMP-002: Network Layer & Auth Service
**Priority:** P0 | **Estimasi:** 1 hari | **Deps:** TASK-EMP-001

- [ ] Buat `lib/core/network/api_endpoints.dart` — semua URL constant sesuai `design.md §6.2`
- [ ] Buat `lib/core/network/api_client.dart` — Dio instance dengan:
  - [ ] `BaseOptions`: baseUrl dari const, connectTimeout 30s, receiveTimeout 30s
  - [ ] `AuthInterceptor`: attach token dari SecureStorage ke header, handle 401 → hapus token → navigate login
  - [ ] `LogInterceptor`: aktif hanya di debug mode
- [ ] Buat `lib/core/services/auth_service.dart`:
  - [ ] `saveToken(String token)` — tulis ke `flutter_secure_storage`
  - [ ] `getToken()` — baca dari secure storage, return null jika tidak ada
  - [ ] `clearToken()` — hapus token
  - [ ] `saveUser(Map user)` — simpan data user sebagai JSON string
  - [ ] `getUser()` — baca dan parse data user
- [ ] Buat `lib/core/constants/app_constants.dart` — `baseUrl` (baca dari `const String.fromEnvironment` atau hardcoded untuk dev)

**Acceptance:** Dio dapat mengirim request ke backend lokal, token tersimpan di secure storage

---

### TASK-EMP-003: Router & Main Scaffold
**Priority:** P0 | **Estimasi:** 0.5 hari | **Deps:** TASK-EMP-002

- [ ] Buat `lib/router/app_router.dart` sesuai `design.md §8`:
  - [ ] Route `/splash`, `/login`
  - [ ] `ShellRoute` untuk main screen (POS, Incoming Orders, Queue)
  - [ ] Route individual untuk payment screens dan receipt
  - [ ] Route `/order-detail/:id`
  - [ ] `redirect` logic: cek token → arahkan ke login atau POS
- [ ] Buat `MainScaffold` widget dengan `BottomNavigationBar`:
  - [ ] Tab 0: POS (ikon point_of_sale)
  - [ ] Tab 1: Pesanan Masuk (ikon inbox, dengan badge count)
  - [ ] Tab 2: Antrian (ikon format_list_numbered)
  - [ ] AppBar title berubah sesuai tab aktif
  - [ ] Ikon logout di AppBar → confirm dialog → logout
- [ ] Update `main.dart`: `MaterialApp.router` dengan `AppTheme` dan `router`
- [ ] Buat `SplashScreen`: cek token → navigate replace ke `/login` atau `/pos`

**Acceptance:** Routing berfungsi, bottom nav dapat berpindah antar tab, splash screen mengecek token

---

### TASK-EMP-004: Shared Widgets
**Priority:** P1 | **Estimasi:** 1 hari | **Deps:** TASK-EMP-001

- [ ] `lib/shared/widgets/brew_button.dart`:
  - [ ] Parameter: `label`, `onPressed`, `isLoading`, `isFullWidth`, `color` (default primary)
  - [ ] Tampilkan `CircularProgressIndicator` di dalam tombol saat `isLoading = true`
  - [ ] Disabled state saat `onPressed == null` atau `isLoading = true`
- [ ] `lib/shared/widgets/brew_text_field.dart`:
  - [ ] Parameter: `label`, `controller`, `obscureText`, `keyboardType`, `errorText`
  - [ ] Toggle visibility untuk password field
  - [ ] Error text tampil di bawah field berwarna alert
- [ ] `lib/shared/widgets/status_badge.dart`:
  - [ ] Parameter: `status` (String)
  - [ ] Map status ke warna: pending→alert, processing→primary, ready→accent, completed→grey, cancelled→alert
  - [ ] Tampilkan teks terjemahan: pending→"Menunggu", processing→"Diproses", ready→"Siap", completed→"Selesai", cancelled→"Dibatalkan"
- [ ] `lib/shared/widgets/shimmer_loader.dart`:
  - [ ] `ShimmerCard(width, height)` — satu placeholder card
  - [ ] `ShimmerGrid(crossAxisCount, itemCount)` — grid placeholder
  - [ ] `ShimmerList(itemCount)` — list placeholder
- [ ] `lib/shared/widgets/empty_state_widget.dart`:
  - [ ] Parameter: `icon`, `message`, `onRetry` (optional)
  - [ ] Tampilkan ikon + pesan + tombol "Coba Lagi" jika `onRetry` tidak null
- [ ] `lib/shared/widgets/confirm_dialog.dart`:
  - [ ] Parameter: `title`, `message`, `confirmLabel`, `onConfirm`, `isDangerous`
  - [ ] Tombol confirm berwarna alert jika `isDangerous = true`

**Acceptance:** Semua shared widget dapat di-render tanpa error

---

### TASK-EMP-005: FCM Service
**Priority:** P1 | **Estimasi:** 1 hari | **Deps:** TASK-EMP-002

- [ ] Buat `lib/core/services/fcm_service.dart` sesuai `design.md §7`:
  - [ ] `initialize()`: init Firebase, request permission, get & upload token ke server
  - [ ] Setup `onTokenRefresh` listener → upload token baru
  - [ ] Setup foreground handler → tampilkan local notification
  - [ ] Setup `onMessageOpenedApp` handler → navigate ke IncomingOrdersScreen
  - [ ] Setup `getInitialMessage` untuk terminated state tap
- [ ] Setup `flutter_local_notifications`:
  - [ ] `LocalNotificationService.initialize()`
  - [ ] `LocalNotificationService.show(RemoteMessage message)` — tampilkan notifikasi di foreground
- [ ] Buat `NotificationEventBus` (simple `StreamController.broadcast()`):
  - [ ] `emit(String type, Map data)` — broadcast event
  - [ ] Screen yang relevan subscribe ke stream ini
- [ ] Panggil `FcmService.initialize()` di `main()` sebelum `runApp()`

**Acceptance:** FCM token terupload ke server saat login, local notification muncul saat app foreground

---

## PHASE 2 — Auth Screen

### TASK-EMP-006: Login Screen
**Priority:** P0 | **Estimasi:** 1 hari | **Deps:** TASK-EMP-002, TASK-EMP-004

- [ ] Buat `lib/features/auth/screens/login_screen.dart` sesuai `design.md §4.1`:
  - [ ] Logo/ilustrasi di atas (asset lokal atau placeholder)
  - [ ] TextField email + TextField password menggunakan `BrewTextField`
  - [ ] BrewButton "Masuk" — disabled saat field kosong, loading saat request berlangsung
  - [ ] Error message di bawah tombol
- [ ] Implementasi login logic:
  - [ ] `POST /auth/login` via Dio
  - [ ] Validasi role: jika bukan `kasir` atau `admin`, tampilkan error
  - [ ] Validasi `is_active`: jika false, tampilkan error
  - [ ] Simpan token via `AuthService.saveToken()`
  - [ ] Simpan user data via `AuthService.saveUser()`
  - [ ] Upload FCM token via `PATCH /auth/fcm-token`
  - [ ] Navigate replace ke `/pos`

**Acceptance:** Kasir dapat login, token tersimpan, navigasi ke POS berhasil

---

## PHASE 3 — POS Feature

### TASK-EMP-007: Menu Service & Models
**Priority:** P1 | **Estimasi:** 1 hari | **Deps:** TASK-EMP-002

- [ ] Buat model `Menu`, `MenuCategory`, `CondimentGroup`, `CondimentOption` sesuai `design.md §5`
  - [ ] Semua model memiliki `fromJson(Map<String, dynamic> json)` factory constructor
- [ ] Buat `OrderItemDraft` model sesuai `design.md §5` dengan kalkulasi `subtotal` getter
- [ ] Buat `lib/features/pos/services/menu_service.dart`:
  - [ ] `getMenus()` → `GET /menus` → `List<Menu>`
  - [ ] `getCategories()` → `GET /categories` → `List<MenuCategory>`
  - [ ] Handle response error, throw Exception dengan pesan dari API

**Acceptance:** `MenuService.getMenus()` mengembalikan list menu dari API

---

### TASK-EMP-008: POS Screen
**Priority:** P1 | **Estimasi:** 2 hari | **Deps:** TASK-EMP-007, TASK-EMP-004

- [ ] Buat `lib/features/pos/screens/pos_screen.dart` sesuai `design.md §4.2`:
  - [ ] State: `List<Menu> _allMenus`, `List<Menu> _filteredMenus`, `List<OrderItemDraft> _cartItems`, `bool _isLoading`
  - [ ] `initState()`: panggil `MenuService.getMenus()` dan `getCategories()`
  - [ ] Shimmer loading saat `_isLoading = true`
  - [ ] GridView 3 kolom — setiap card: CachedNetworkImage + nama + harga
  - [ ] Filter chips horizontal (semua kategori + "Semua")
  - [ ] Search bar — filter `_filteredMenus` secara lokal berdasarkan nama
  - [ ] Order summary panel di bagian bawah:
    - [ ] Tersembunyi jika `_cartItems` kosong
    - [ ] Tampil saat ada item: jumlah item, total, tombol "Proses Pembayaran"
- [ ] Tap item tanpa condiment → langsung tambah ke `_cartItems`
- [ ] Tap item dengan condiment → buka `CondimentBottomSheet`
- [ ] Order summary panel tap/expand → tampilkan daftar item lengkap dengan qty control

**Acceptance:** Menu tampil dalam grid 3 kolom, filter dan search berfungsi lokal

---

### TASK-EMP-009: Condiment Bottom Sheet
**Priority:** P1 | **Estimasi:** 1.5 hari | **Deps:** TASK-EMP-008

- [ ] Buat `lib/features/pos/screens/condiment_bottom_sheet.dart` sesuai `design.md §4.3`:
  - [ ] Gunakan `DraggableScrollableSheet`
  - [ ] Handle bar + nama menu + deskripsi singkat
  - [ ] State: `Map<int, List<int>> _selectedOptions` (groupId → selected optionIds)
  - [ ] Render setiap `CondimentGroup`:
    - [ ] Label nama grup + badge "Wajib" merah jika `is_required = true`
    - [ ] Jika `type = single_select`: `RadioListTile` per opsi
    - [ ] Jika `type = multi_select`: `CheckboxListTile` per opsi
    - [ ] Setiap baris opsi: nama kiri + harga kanan (sesuai komponen Figma Button)
  - [ ] Quantity counter (+/-) di atas tombol Tambah
  - [ ] Validasi saat tap "Tambah ke Order":
    - [ ] Semua group `is_required = true` harus memiliki pilihan
    - [ ] Jika tidak valid: tandai grup yang belum diisi dengan border/teks merah
    - [ ] Jika valid: panggil `onConfirm(selectedCondiments, quantity)` callback dan close bottom sheet

**Acceptance:** Single-select dan multi-select condiment berfungsi, validasi required bekerja

---

### TASK-EMP-010: Confirm Payment Screen
**Priority:** P1 | **Estimasi:** 1.5 hari | **Deps:** TASK-EMP-008

- [ ] Buat `lib/features/pos/screens/confirm_payment_screen.dart` sesuai `design.md §4.4`:
  - [ ] Terima `List<OrderItemDraft>` dari POSScreen via `go_router` extras
  - [ ] State: `String _paymentMethod` (default 'cash'), `String? _paymentChannel`, `double _cashReceived`
  - [ ] Tampilkan ringkasan item + condiment per item + total
  - [ ] `SegmentedButton` untuk pilih metode: Cash | QRIS | Virtual Account
  - [ ] Jika Cash:
    - [ ] TextField "Uang Diterima" (numeric)
    - [ ] Text kembalian real-time, merah jika `cashReceived < total`
    - [ ] Tombol "Konfirmasi Bayar" disabled jika kembalian negatif
  - [ ] Jika Virtual Account:
    - [ ] Dropdown pilih bank: BCA, BNI, BRI, Mandiri
  - [ ] Tombol "Konfirmasi Bayar":
    - [ ] Bangun payload sesuai `design.md §9`
    - [ ] `POST /api/orders`
    - [ ] Loading state di tombol saat request
    - [ ] Jika cash: navigate ke ReceiptScreen
    - [ ] Jika qris: navigate ke QRISPaymentScreen dengan `qr_code_url` dari response
    - [ ] Jika va: navigate ke VAPaymentScreen dengan `va_number` + `bank`
    - [ ] Jika error 422 (stok habis): tampilkan dialog error, kembali ke POS

**Acceptance:** Semua tiga metode pembayaran dapat diinisiasi, kembalian cash kalkulasi real-time

---

### TASK-EMP-011: QRIS Payment Screen
**Priority:** P1 | **Estimasi:** 1 hari | **Deps:** TASK-EMP-010

- [ ] Buat `lib/features/pos/screens/qris_payment_screen.dart` sesuai `design.md §4.5`:
  - [ ] State: `bool _isPaid`, `Timer? _pollingTimer`
  - [ ] `initState()`: mulai polling timer setiap 3 detik
  - [ ] `dispose()`: cancel timer
  - [ ] Polling: `GET /api/orders/{id}/payment-status`
  - [ ] Jika `payment_status = paid`: cancel timer, navigate replace ke ReceiptScreen
  - [ ] QR image dari `qr_code_url` menggunakan `Image.network`
  - [ ] Pulsing loading indicator saat menunggu
  - [ ] Tombol "Batalkan Pesanan": tampilkan `ConfirmDialog` → jika confirm: `DELETE /orders/{id}` → navigate pop ke POS
  - [ ] WillPopScope: cegah back button hardware

**Acceptance:** Polling berjalan, saat payment confirmed navigate ke receipt, batalkan berfungsi

---

### TASK-EMP-012: VA Payment Screen
**Priority:** P1 | **Estimasi:** 0.5 hari | **Deps:** TASK-EMP-010

- [ ] Buat `lib/features/pos/screens/va_payment_screen.dart` sesuai `design.md §4.6`:
  - [ ] Tampilkan nama bank + nomor VA (tap to copy via Clipboard.setData)
  - [ ] Tampilkan total
  - [ ] Polling setiap 5 detik
  - [ ] Saat paid: navigate ke ReceiptScreen
  - [ ] Tombol batalkan dengan confirm dialog

**Acceptance:** Nomor VA tampil, copy berfungsi, polling mendeteksi pembayaran

---

### TASK-EMP-013: Receipt Screen
**Priority:** P1 | **Estimasi:** 0.5 hari | **Deps:** TASK-EMP-010

- [ ] Buat `lib/features/pos/screens/receipt_screen.dart` sesuai `design.md §4.7`:
  - [ ] Ikon check circle warna accent, ukuran 64
  - [ ] Nomor antrian 72sp bold, format 3 digit
  - [ ] Ringkasan item: nama + qty + harga
  - [ ] Baris total
  - [ ] Baris kembalian (hanya jika cash)
  - [ ] Tombol "Pesanan Baru": reset cart, navigate replace ke `/pos`

**Acceptance:** Receipt tampil dengan nomor antrian besar, tombol pesanan baru mereset state POS

---

## PHASE 4 — Incoming Orders Feature

### TASK-EMP-014: Order Service & Models
**Priority:** P1 | **Estimasi:** 1 hari | **Deps:** TASK-EMP-002

- [ ] Buat model `Order` dan `OrderItem` sesuai `design.md §5`
  - [ ] `fromJson` factory constructor untuk keduanya
  - [ ] `Order.statusLabel` getter: map status ke teks Indonesia
  - [ ] `Order.statusColor` getter: map status ke `AppColors`
- [ ] Buat `lib/features/orders/services/order_service.dart`:
  - [ ] `getStaffOrders({String? status, String? type})` → `GET /staff/orders` dengan query params → `List<Order>`
  - [ ] `getOrderDetail(int id)` → `GET /staff/orders/{id}` → `Order`
  - [ ] `updateOrderStatus(int id, String status)` → `PATCH /staff/orders/{id}/status` → `Order`

**Acceptance:** `OrderService` dapat fetch dan update order dari API

---

### TASK-EMP-015: Incoming Orders Screen
**Priority:** P1 | **Estimasi:** 2 hari | **Deps:** TASK-EMP-014, TASK-EMP-005

- [ ] Buat `lib/features/orders/screens/incoming_orders_screen.dart` sesuai `design.md §4.8`:
  - [ ] State: `List<Order> _orders`, `String _activeFilter`, `bool _isLoading`
  - [ ] `initState()`: fetch `GET /staff/orders?type=preorder`, subscribe ke `NotificationEventBus`
  - [ ] `dispose()`: unsubscribe dari NotificationEventBus
  - [ ] Saat menerima event `new_order` dari NotificationEventBus: panggil refresh
  - [ ] Filter tabs: Semua | Pending | Diproses | Siap — filter lokal dari `_orders`
  - [ ] Shimmer loading saat `_isLoading`
  - [ ] Empty state jika tidak ada order
  - [ ] Pull to refresh
  - [ ] Order card sesuai `design.md §4.8`:
    - [ ] Left accent bar berwarna sesuai status
    - [ ] Nomor antrian, nama customer, item count, total, waktu, tipe
    - [ ] StatusBadge
    - [ ] Tombol aksi sesuai status:
        - pending → "Mulai Proses" + "Batalkan"
        - processing → "Siap Diambil" + "Batalkan"
        - ready → "Selesai" + "Batalkan"
  - [ ] Tap "Mulai Proses": `updateOrderStatus(id, 'processing')` → update UI
  - [ ] Tap "Siap Diambil": `updateOrderStatus(id, 'ready')` → update UI
  - [ ] Tap "Selesai": `updateOrderStatus(id, 'completed')` → hapus dari list
  - [ ] Tap "Batalkan": tampilkan `ConfirmDialog` dengan TextField alasan → kirim status `cancelled` + notes
  - [ ] Tap card: navigate ke `/order-detail/{id}`
- [ ] Update badge count di `MainScaffold`: jumlah order dengan status `pending`

**Acceptance:** Order masuk tampil, status dapat diupdate, FCM auto-refresh berfungsi, badge count akurat

---

### TASK-EMP-016: Order Detail Screen
**Priority:** P1 | **Estimasi:** 1 hari | **Deps:** TASK-EMP-014

- [ ] Buat `lib/features/orders/screens/order_detail_screen.dart` sesuai `design.md §4.9`:
  - [ ] Fetch `GET /staff/orders/{id}` saat `initState()`
  - [ ] Card Info Pelanggan: nama, telepon, waktu pesan, tipe, waktu pickup
  - [ ] Card Nomor Antrian + StatusBadge
  - [ ] Card Daftar Item: per item → nama + qty + condiment list + harga
  - [ ] Card Pembayaran: metode, status, total
  - [ ] Timeline status log (sederhana: vertikal dengan timestamp)
  - [ ] Footer tombol aksi jika status masih aktif (sama dengan card di IncomingOrdersScreen)
  - [ ] Shimmer loading saat fetch

**Acceptance:** Detail pesanan tampil lengkap termasuk condiment dan status log

---

## PHASE 5 — Queue Feature

### TASK-EMP-017: Queue Service & Screen
**Priority:** P1 | **Estimasi:** 1 hari | **Deps:** TASK-EMP-002

- [ ] Buat `lib/features/queue/services/queue_service.dart`:
  - [ ] `getActiveQueue()` → `GET /queue/active` → `List<Order>`
  - [ ] `getEstimate()` → `GET /queue/estimate` → `{estimated_minutes, active_count}`
- [ ] Buat `lib/features/queue/screens/queue_screen.dart` sesuai `design.md §4.10`:
  - [ ] State: `List<Order> _queue`, `int _estimateMinutes`, `Timer? _refreshTimer`
  - [ ] `initState()`: fetch data, mulai Timer.periodic setiap 10 detik
  - [ ] `dispose()`: cancel timer
  - [ ] Estimasi tunggu di atas
  - [ ] ListView queue cards: nomor antrian besar + StatusBadge + nama customer
  - [ ] Card dengan border accent jika status = ready
  - [ ] Empty state
  - [ ] Pull to refresh

**Acceptance:** Antrian tampil dan auto-refresh setiap 10 detik, timer di-cancel saat screen di-dispose

---

## PHASE 6 — Polish & Error Handling

### TASK-EMP-018: Error Handling Global
**Priority:** P1 | **Estimasi:** 1 hari | **Deps:** semua feature tasks

- [ ] Update `AuthInterceptor`:
  - [ ] Error 5xx → tampilkan snackbar "Terjadi kesalahan di server"
  - [ ] Error timeout → tampilkan snackbar "Koneksi timeout. Coba lagi."
  - [ ] Error 422 → return error message dari `response.data.message` ke caller (jangan handle di interceptor)
- [ ] Wrap semua `OrderService` calls dalam try-catch yang meaningful
- [ ] Pastikan semua screen memiliki error state (tidak hanya loading dan data)
- [ ] Test kasus: stok habis saat order → dialog spesifik menampilkan nama menu

**Acceptance:** Semua error case ditangani dengan pesan yang jelas, app tidak crash

---

### TASK-EMP-019: UI Polish
**Priority:** P2 | **Estimasi:** 1 hari | **Deps:** semua feature tasks

- [ ] Pastikan semua screen memiliki shimmer loading state (tidak ada spinner kosong)
- [ ] Pastikan semua screen memiliki empty state dengan ikon relevan
- [ ] Animasi transisi halaman: `FadeTransition` untuk semua route di go_router
- [ ] Status badge animasi ringan: scale in saat pertama tampil
- [ ] ReceiptScreen: nomor antrian tampil dengan animasi scale in
- [ ] Cek konsistensi padding (gunakan `AppSpacing`) di semua screen
- [ ] Cek konsistensi warna di semua komponen (tidak ada hardcoded color)
- [ ] Test di beberapa ukuran layar Android (360dp, 390dp, 412dp width)

**Acceptance:** UI konsisten, tidak ada hardcoded color, semua screen punya loading dan empty state

---

### TASK-EMP-020: Build & Test
**Priority:** P1 | **Estimasi:** 1 hari | **Deps:** TASK-EMP-019

- [ ] Update `AppConstants.baseUrl` ke URL Railway production
- [ ] Jalankan `flutter analyze` — nol error, nol warning kritis
- [ ] Jalankan `flutter build apk --release`
- [ ] Install APK di device fisik Android
- [ ] Test flow lengkap walk-in: POS → pilih item → condiment → cash → receipt
- [ ] Test flow walk-in QRIS: POS → pilih item → QRIS → scan (Midtrans Sandbox) → receipt
- [ ] Test flow walk-in VA: POS → pilih item → VA → konfirmasi dari simulator → receipt
- [ ] Test incoming orders: buat pre-order dari Customer App → terima notif → proses → selesai
- [ ] Test antrian: order masuk → cek di queue screen → nomor urut benar
- [ ] Test logout: token terhapus, tidak bisa akses tanpa login ulang

**Acceptance:** APK release terinstall dan semua flow berjalan end-to-end dengan backend production

---

## Summary

| Phase | Task | Estimasi Total |
|-------|------|----------------|
| Phase 1 — Foundation | 5 tasks | 4.5 hari |
| Phase 2 — Auth | 1 task | 1 hari |
| Phase 3 — POS | 7 tasks | 8 hari |
| Phase 4 — Incoming Orders | 3 tasks | 4 hari |
| Phase 5 — Queue | 1 task | 1 hari |
| Phase 6 — Polish & Build | 3 tasks | 3 hari |
| **TOTAL** | **20 tasks** | **~21.5 hari** |

## Critical Path

```
TASK-EMP-001 (Setup)
  → TASK-EMP-002 (Network)
    → TASK-EMP-003 (Router)
      → TASK-EMP-006 (Login)
        → TASK-EMP-007 (Menu Models)
          → TASK-EMP-008 (POS Screen)      ← core POS
            → TASK-EMP-009 (Condiment)
              → TASK-EMP-010 (Confirm Payment)
                → TASK-EMP-011 (QRIS)
                → TASK-EMP-012 (VA)
                → TASK-EMP-013 (Receipt)
        → TASK-EMP-014 (Order Models)     ← core incoming
          → TASK-EMP-015 (Incoming Orders)
            → TASK-EMP-016 (Order Detail)
        → TASK-EMP-017 (Queue)
```

## Notes

- Jangan gunakan `BuildContext` di luar widget tree — gunakan `GlobalKey` atau callback untuk navigasi dari service
- Semua `Timer.periodic` wajib di-cancel di `dispose()` untuk mencegah memory leak
- `flutter_secure_storage` memerlukan `minSdkVersion 23` di Android
- Jangan simpan data sensitif (password, full order data) di SecureStorage — hanya token
- Test di device fisik untuk FCM — emulator sering bermasalah dengan push notification
- Gunakan `WillPopScope` di screen pembayaran (QRIS/VA) untuk mencegah back button tidak sengaja
