# Cofflow — Employee Cashier App
## Project Prompt

### Overview

Employee Cashier App adalah aplikasi Flutter Android yang digunakan oleh kasir coffee shop untuk:
1. Memproses transaksi walk-in langsung di meja kasir (POS)
2. Menerima dan memproses pre-order yang masuk dari Customer App
3. Mengelola antrian dan status pesanan secara real-time

Aplikasi ini berkomunikasi sepenuhnya melalui REST API backend Laravel yang sudah dibangun di `cofflow-api`. Tidak ada koneksi langsung ke database.

### Target User

**Kasir / Pegawai** yang sedang bertugas di coffee shop. Satu device digunakan bergantian oleh kasir yang bertugas di shift tersebut.

### Tech Stack

| Layer | Teknologi |
|-------|-----------|
| Framework | Flutter (Dart) — Android only |
| State Management | StatefulWidget + setState (no Riverpod/BLoC) |
| HTTP Client | `dio` ^5.x |
| Routing | `go_router` ^13.x |
| Secure Storage | `flutter_secure_storage` ^9.x |
| Push Notification | `firebase_messaging` ^15.x |
| Image Loading | `cached_network_image` ^3.x |
| Fonts | `google_fonts` ^6.x |
| Local Notification | `flutter_local_notifications` ^17.x |

### Design System

Identik dengan design system Cofflow — wajib diikuti tanpa modifikasi.

| Token | Value | Penggunaan |
|-------|-------|------------|
| Primary | `#3E2723` | AppBar, tombol utama, sidebar |
| Secondary | `#F5F5DC` | Background halaman, card background |
| Accent | `#81C784` | Status "Siap", badge sukses, active state |
| Alert | `#E57373` | Error, status "Dibatalkan", stok kritis |
| Font Heading | Poppins | AppBar title, card title, label besar |
| Font Body | Roboto | Body text, tabel, form input |

Komponen Figma yang sudah ada (dari `Cofflow_Employee_App_Design_Figma.md`):
- **Button** condiment row — 175×40px, row layout, padding 9px 12px, teks condiment option di kiri
- **Button** condiment row (variant dengan harga) — 175×38px, padding 8px 12px, teks option + container harga di kanan
- Semua komponen ini adalah condiment selection row di dalam CondimentBottomSheet

### Core Features

#### Kasir (Role: kasir)
1. Login dengan akun kasir
2. POS walk-in — grid menu 3 kolom, pilih item, pilih condiment, konfirmasi pembayaran
3. Pembayaran cash — kalkulasi kembalian real-time
4. Pembayaran QRIS — tampilkan QR code, polling status
5. Pembayaran Virtual Account — tampilkan nomor VA + bank
6. Lihat dan proses incoming pre-order dari Customer App
7. Update status pesanan (pending → processing → ready → completed)
8. Batalkan pesanan dengan alasan
9. Display antrian aktif hari ini

#### Push Notification
- Terima FCM saat ada pre-order baru masuk
- Auto-refresh daftar pesanan masuk saat notifikasi diterima
- Badge count pada tab Pesanan Masuk

### Out of Scope

- Fitur admin (CRUD menu, stok, pegawai) — dilakukan via Web Admin Dashboard
- Customer App features
- Loyalty point system (dihapus dari rancangan)
- Analytics dashboard (hanya di Web Admin)

### API Backend

Semua data diambil dari: `https://{railway-domain}/api`

Endpoint yang digunakan Employee App:
- `POST /auth/login` — login
- `POST /auth/logout` — logout
- `PATCH /auth/fcm-token` — update FCM token
- `GET /menus` — ambil menu aktif
- `GET /categories` — ambil kategori
- `POST /orders` — buat order baru (walk-in)
- `GET /staff/orders` — list semua order
- `GET /staff/orders/{id}` — detail order
- `PATCH /staff/orders/{id}/status` — update status
- `GET /queue/active` — antrian aktif
- `GET /queue/estimate` — estimasi tunggu

### Related Specs

- `cofflow-backend-admin/` — Backend API spec (sumber kebenaran untuk semua endpoint)
- `cofflow-customer-app/` — Customer App spec
