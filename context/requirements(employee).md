# Requirements — Cofflow Employee Cashier App

## Introduction

Dokumen ini mendefinisikan semua requirements dalam bentuk user stories dan acceptance criteria menggunakan notasi EARS (Easy Approach to Requirements Syntax).

Format acceptance criteria:
```
WHEN [kondisi/event]
THE SYSTEM SHALL [perilaku yang diharapkan]
```

---

## REQ-EMP-01: Autentikasi Kasir

**User Story:**
Sebagai kasir, saya ingin login ke aplikasi menggunakan akun staff saya, sehingga saya bisa mengakses fitur kasir sesuai shift saya.

### Acceptance Criteria

1. WHEN kasir membuka aplikasi dan belum login
   THE SYSTEM SHALL menampilkan halaman Login sebagai halaman pertama

2. WHEN kasir memasukkan email dan password yang benar dengan role `kasir`
   THE SYSTEM SHALL menyimpan token ke secure storage, menyimpan FCM token ke server via `PATCH /auth/fcm-token`, dan mengarahkan ke halaman POS

3. WHEN kasir memasukkan email atau password yang salah
   THE SYSTEM SHALL menampilkan pesan error "Email atau password salah" tanpa mereset form

4. WHEN email yang dimasukkan adalah akun dengan role `customer`
   THE SYSTEM SHALL menampilkan error "Akun ini bukan akun staff"

5. WHEN akun kasir telah dinonaktifkan oleh admin
   THE SYSTEM SHALL menampilkan error "Akun kamu dinonaktifkan" dan tidak menyimpan token

6. WHEN aplikasi dibuka dan token tersimpan masih valid
   THE SYSTEM SHALL langsung mengarahkan ke halaman POS tanpa login ulang

7. WHEN token tersimpan expired atau API mengembalikan 401
   THE SYSTEM SHALL menghapus token dari secure storage dan mengarahkan ke halaman Login

8. WHEN kasir menekan tombol Logout
   THE SYSTEM SHALL memanggil `POST /auth/logout`, menghapus token dari secure storage, dan mengarahkan ke halaman Login

---

## REQ-EMP-02: POS Walk-in — Tampilan Menu

**User Story:**
Sebagai kasir, saya ingin melihat semua menu yang tersedia dalam tampilan grid yang kompak, sehingga saya bisa mencari dan memilih item dengan cepat saat melayani pelanggan langsung.

### Acceptance Criteria

1. WHEN kasir membuka halaman POS
   THE SYSTEM SHALL menampilkan semua menu aktif dalam grid 3 kolom

2. WHEN halaman POS sedang memuat data menu
   THE SYSTEM SHALL menampilkan shimmer loading placeholder untuk setiap item grid

3. WHEN kasir memilih filter kategori di bagian atas layar
   THE SYSTEM SHALL memfilter grid menu secara lokal (tanpa API call ulang) hanya menampilkan menu kategori yang dipilih

4. WHEN kasir mengetik di search bar
   THE SYSTEM SHALL memfilter menu secara real-time berdasarkan nama menu

5. WHEN sebuah menu berstatus tidak aktif (is_active = false)
   THE SYSTEM SHALL tidak menampilkan menu tersebut di grid POS

6. WHEN tidak ada menu yang cocok dengan filter atau pencarian
   THE SYSTEM SHALL menampilkan empty state dengan ikon dan pesan "Tidak ada menu yang ditemukan"

---

## REQ-EMP-03: POS Walk-in — Memilih Item dan Condiment

**User Story:**
Sebagai kasir, saya ingin menambahkan item ke order dengan cepat, dengan opsi untuk memilih condiment jika tersedia, sehingga pesanan pelanggan tercatat dengan benar.

### Acceptance Criteria

1. WHEN kasir menekan item menu yang tidak memiliki condiment group terkait
   THE SYSTEM SHALL langsung menambahkan item ke order summary dengan quantity 1

2. WHEN kasir menekan item menu yang memiliki satu atau lebih condiment group terkait
   THE SYSTEM SHALL menampilkan CondimentBottomSheet yang berisi semua condiment group dan opsinya

3. WHEN CondimentBottomSheet ditampilkan
   THE SYSTEM SHALL menampilkan setiap condiment group sebagai seksi terpisah dengan label nama grup dan tipe (Radio untuk single_select, Checkbox untuk multi_select)

4. WHEN sebuah condiment group bertipe `single_select`
   THE SYSTEM SHALL menampilkan opsi dalam bentuk Radio Button — hanya satu opsi yang bisa dipilih per grup

5. WHEN sebuah condiment group bertipe `multi_select`
   THE SYSTEM SHALL menampilkan opsi dalam bentuk Checkbox — lebih dari satu opsi dapat dipilih

6. WHEN sebuah condiment option memiliki `additional_price > 0`
   THE SYSTEM SHALL menampilkan "+ Rp [harga]" di sebelah kanan nama opsi pada baris condiment (sesuai komponen Figma Button variant dengan Container harga)

7. WHEN kasir menekan "Tambah ke Order" di CondimentBottomSheet tanpa mengisi condiment group yang `is_required = true`
   THE SYSTEM SHALL menampilkan tanda error merah pada grup yang belum diisi dan tidak menutup bottom sheet

8. WHEN kasir menekan "Tambah ke Order" dengan semua condiment required telah dipilih
   THE SYSTEM SHALL menambahkan item beserta pilihan condiment ke order summary dan menutup bottom sheet

9. WHEN kasir menekan item yang sama yang sudah ada di order summary
   THE SYSTEM SHALL menambahkan item baru sebagai baris terpisah (untuk mengakomodasi pilihan condiment yang berbeda)

---

## REQ-EMP-04: POS Walk-in — Order Summary dan Pembayaran

**User Story:**
Sebagai kasir, saya ingin melihat ringkasan order dan memproses pembayaran dengan mudah, sehingga transaksi berjalan cepat dan akurat.

### Acceptance Criteria

1. WHEN kasir menambahkan item ke order summary
   THE SYSTEM SHALL menampilkan panel order summary (di bagian bawah atau tab terpisah) berisi daftar item, summary condiment per item, subtotal, dan total

2. WHEN kasir menekan tombol tambah (+) atau kurang (-) pada item di order summary
   THE SYSTEM SHALL memperbarui quantity item dan menghitung ulang total secara real-time

3. WHEN kasir menekan tombol hapus pada item di order summary
   THE SYSTEM SHALL menghapus item tersebut dari order summary

4. WHEN kasir menekan "Proses Pembayaran"
   THE SYSTEM SHALL menampilkan halaman ConfirmPaymentScreen dengan ringkasan order, toggle metode bayar (Cash / QRIS / Virtual Account), dan total

5. WHEN kasir memilih metode Cash dan mengisi field "Uang Diterima"
   THE SYSTEM SHALL menghitung dan menampilkan kembalian secara real-time dengan rumus: kembalian = uang diterima - total

6. WHEN jumlah uang diterima kurang dari total order
   THE SYSTEM SHALL menampilkan kembalian bernilai negatif berwarna merah dan menonaktifkan tombol "Konfirmasi Bayar"

7. WHEN kasir menekan "Konfirmasi Bayar" dengan metode Cash
   THE SYSTEM SHALL memanggil `POST /api/orders` dengan `payment_method = cash`, menampilkan nomor antrian, dan mengarahkan ke ReceiptScreen

8. WHEN kasir memilih metode QRIS
   THE SYSTEM SHALL memanggil `POST /api/orders` dengan `payment_method = qris`, menerima `qr_code_url`, dan menampilkan QRISPaymentScreen

9. WHEN kasir memilih metode Virtual Account dan memilih bank
   THE SYSTEM SHALL memanggil `POST /api/orders` dengan `payment_method = virtual_account` dan `payment_channel`, menerima nomor VA, dan menampilkan VAPaymentScreen

10. WHEN kasir menekan "Pesanan Baru" di ReceiptScreen
    THE SYSTEM SHALL mereset order summary menjadi kosong dan kembali ke halaman POS

---

## REQ-EMP-05: Pembayaran QRIS (Walk-in)

**User Story:**
Sebagai kasir, saya ingin menampilkan QR code kepada pelanggan dan menunggu konfirmasi pembayaran secara otomatis, sehingga tidak perlu cek manual.

### Acceptance Criteria

1. WHEN QRISPaymentScreen ditampilkan
   THE SYSTEM SHALL menampilkan QR Code dari `qr_code_url` yang diterima API, total yang harus dibayar, dan status "Menunggu Pembayaran"

2. WHEN QRISPaymentScreen aktif
   THE SYSTEM SHALL melakukan polling ke `GET /api/orders/{id}/payment-status` setiap 3 detik

3. WHEN polling mengembalikan `payment_status = paid`
   THE SYSTEM SHALL menghentikan polling dan menampilkan ReceiptScreen dengan status bayar sukses

4. WHEN kasir menekan tombol "Batalkan" di QRISPaymentScreen
   THE SYSTEM SHALL menampilkan dialog konfirmasi sebelum membatalkan order

5. WHEN kasir mengkonfirmasi pembatalan di QRISPaymentScreen
   THE SYSTEM SHALL memanggil `DELETE /api/orders/{id}`, menghentikan polling, dan kembali ke halaman POS

---

## REQ-EMP-06: Pembayaran Virtual Account (Walk-in)

**User Story:**
Sebagai kasir, saya ingin menampilkan nomor Virtual Account kepada pelanggan, sehingga pembayaran transfer dapat dilakukan dan terkonfirmasi otomatis.

### Acceptance Criteria

1. WHEN VAPaymentScreen ditampilkan
   THE SYSTEM SHALL menampilkan nama bank, nomor VA, total yang harus dibayar, dan instruksi singkat transfer

2. WHEN VAPaymentScreen aktif
   THE SYSTEM SHALL melakukan polling ke `GET /api/orders/{id}/payment-status` setiap 5 detik

3. WHEN polling mengembalikan `payment_status = paid`
   THE SYSTEM SHALL menghentikan polling dan menampilkan ReceiptScreen

4. WHEN kasir menekan tombol "Batalkan" di VAPaymentScreen
   THE SYSTEM SHALL menampilkan dialog konfirmasi sebelum membatalkan order

---

## REQ-EMP-07: Struk dan Nomor Antrian

**User Story:**
Sebagai kasir, saya ingin melihat konfirmasi transaksi dan nomor antrian setelah pembayaran berhasil, sehingga pelanggan mendapat informasi yang jelas.

### Acceptance Criteria

1. WHEN ReceiptScreen ditampilkan setelah pembayaran berhasil
   THE SYSTEM SHALL menampilkan nomor antrian dalam format 3 digit (contoh: 007) dengan ukuran font besar, ringkasan item yang dipesan, total yang dibayar, dan metode pembayaran

2. WHEN metode pembayaran adalah Cash
   THE SYSTEM SHALL juga menampilkan jumlah uang diterima dan kembalian pada ReceiptScreen

3. WHEN kasir menekan tombol "Pesanan Baru" di ReceiptScreen
   THE SYSTEM SHALL mereset semua state POS (order summary kosong, filter reset) dan kembali ke halaman POS

---

## REQ-EMP-08: Pesanan Masuk (Pre-order dari Customer App)

**User Story:**
Sebagai kasir, saya ingin melihat semua pre-order yang masuk dari pelanggan dan memrosesnya secara berurutan, sehingga pesanan siap tepat waktu.

### Acceptance Criteria

1. WHEN kasir membuka tab Pesanan Masuk
   THE SYSTEM SHALL memanggil `GET /api/staff/orders?type=preorder` dan menampilkan semua pre-order yang belum selesai, diurutkan dari `created_at` terlama (terlama di atas)

2. WHEN halaman Pesanan Masuk sedang memuat
   THE SYSTEM SHALL menampilkan shimmer loading card sebagai placeholder

3. WHEN daftar pesanan masuk kosong
   THE SYSTEM SHALL menampilkan empty state dengan ikon dan pesan "Belum ada pesanan masuk"

4. WHEN kasir memilih filter tab (Semua / Pending / Diproses / Siap)
   THE SYSTEM SHALL memfilter daftar order berdasarkan status yang dipilih tanpa API call ulang

5. WHEN kasir menekan tombol "Mulai Proses" pada order berstatus `pending`
   THE SYSTEM SHALL memanggil `PATCH /api/staff/orders/{id}/status` dengan status `processing` dan memperbarui tampilan card

6. WHEN kasir menekan tombol "Siap Diambil" pada order berstatus `processing`
   THE SYSTEM SHALL memanggil `PATCH /api/staff/orders/{id}/status` dengan status `ready` dan memperbarui tampilan card

7. WHEN kasir menekan tombol "Selesai" pada order berstatus `ready`
   THE SYSTEM SHALL memanggil `PATCH /api/staff/orders/{id}/status` dengan status `completed` dan menghapus order dari daftar aktif

8. WHEN kasir menekan tombol "Batalkan" pada order
   THE SYSTEM SHALL menampilkan dialog konfirmasi dengan field input alasan pembatalan sebelum mengeksekusi

9. WHEN kasir mengkonfirmasi pembatalan dengan mengisi alasan
   THE SYSTEM SHALL memanggil `PATCH /api/staff/orders/{id}/status` dengan status `cancelled` beserta alasan, dan memperbarui tampilan

10. WHEN kasir menekan sebuah order card
    THE SYSTEM SHALL menampilkan halaman OrderDetailScreen berisi detail lengkap: nama customer, nomor antrian, waktu pesan, daftar item + condiment, total, status pembayaran

---

## REQ-EMP-09: Push Notification Pesanan Baru

**User Story:**
Sebagai kasir, saya ingin menerima notifikasi otomatis saat ada pre-order baru masuk, sehingga tidak perlu memeriksa aplikasi secara manual.

### Acceptance Criteria

1. WHEN ada pre-order baru dibuat oleh customer
   THE SYSTEM SHALL menerima push notification FCM dengan judul "Pesanan Baru Masuk" berisi nama customer dan nomor antrian

2. WHEN notifikasi FCM diterima saat aplikasi dalam foreground
   THE SYSTEM SHALL menampilkan local notification banner dan jika halaman aktif adalah Pesanan Masuk: me-refresh daftar order secara otomatis

3. WHEN notifikasi FCM diterima saat aplikasi dalam background atau terminated
   THE SYSTEM SHALL menampilkan notifikasi di system tray perangkat

4. WHEN kasir menekan notifikasi dari system tray
   THE SYSTEM SHALL membuka aplikasi dan langsung navigasi ke halaman Pesanan Masuk

5. WHEN tab Pesanan Masuk memiliki order baru yang belum dilihat
   THE SYSTEM SHALL menampilkan badge count merah pada icon tab Pesanan Masuk di bottom navigation

---

## REQ-EMP-10: Antrian Aktif

**User Story:**
Sebagai kasir, saya ingin melihat daftar antrian yang sedang aktif hari ini, sehingga pelanggan dapat dipanggil berdasarkan nomor antrian.

### Acceptance Criteria

1. WHEN kasir membuka tab Antrian
   THE SYSTEM SHALL memanggil `GET /api/queue/active` dan menampilkan semua order aktif hari ini dengan nomor antrian besar

2. WHEN halaman Antrian aktif
   THE SYSTEM SHALL melakukan refresh otomatis setiap 10 detik untuk memperbarui daftar

3. WHEN sebuah order di halaman Antrian berstatus `processing`
   THE SYSTEM SHALL menampilkan badge "Sedang Diproses" dengan warna primary pada card tersebut

4. WHEN sebuah order di halaman Antrian berstatus `ready`
   THE SYSTEM SHALL menampilkan badge "Siap Diambil" dengan warna accent dan highlight card dengan border hijau

5. WHEN halaman Antrian menampilkan estimasi
   THE SYSTEM SHALL menampilkan hasil `GET /api/queue/estimate` sebagai informasi "Estimasi tunggu: X menit"

6. WHEN tidak ada antrian aktif hari ini
   THE SYSTEM SHALL menampilkan empty state dengan pesan "Belum ada antrian aktif hari ini"

---

## REQ-EMP-11: Navigasi dan Layout

**User Story:**
Sebagai kasir, saya ingin navigasi yang jelas antara tiga fungsi utama (POS, Pesanan Masuk, Antrian), sehingga bisa berpindah antar halaman dengan cepat saat sibuk melayani.

### Acceptance Criteria

1. WHEN kasir berhasil login
   THE SYSTEM SHALL menampilkan bottom navigation bar dengan tiga tab: POS (ikon kasir), Pesanan Masuk (ikon inbox + badge), Antrian (ikon queue)

2. WHEN kasir berada di sembarang tab
   THE SYSTEM SHALL menampilkan AppBar dengan judul halaman aktif, warna background primary (`#3E2723`), dan ikon logout di kanan

3. WHEN kasir menekan ikon logout di AppBar
   THE SYSTEM SHALL menampilkan dialog konfirmasi "Yakin ingin logout?" sebelum mengeksekusi logout

4. WHEN kasir menekan tab yang sudah aktif
   THE SYSTEM SHALL men-scroll halaman ke atas (scroll to top) tanpa navigasi ulang

---

## REQ-EMP-12: Penanganan Error dan Koneksi

**User Story:**
Sebagai kasir, saya ingin aplikasi tetap memberikan informasi yang jelas ketika terjadi error atau koneksi terputus, sehingga saya tahu apa yang harus dilakukan.

### Acceptance Criteria

1. WHEN request API gagal karena timeout (lebih dari 30 detik)
   THE SYSTEM SHALL menampilkan snackbar error "Koneksi timeout. Coba lagi." dan tidak crash

2. WHEN API mengembalikan response error 5xx
   THE SYSTEM SHALL menampilkan snackbar "Terjadi kesalahan di server. Coba beberapa saat lagi."

3. WHEN API mengembalikan response error 422 (validasi gagal, misal stok tidak cukup)
   THE SYSTEM SHALL menampilkan pesan error spesifik dari field `message` di response API

4. WHEN order gagal dibuat karena stok tidak cukup
   THE SYSTEM SHALL menampilkan dialog error dengan nama menu dan bahan yang habis, serta membiarkan kasir kembali ke POS

5. WHEN status update order gagal karena transisi tidak valid
   THE SYSTEM SHALL menampilkan snackbar "Perubahan status tidak valid" dan me-refresh tampilan order ke status terkini
