# Design — Cofflow Employee Cashier App

## 1. App Architecture

```
Employee App (Flutter)
        │
        │ HTTPS REST API
        ▼
Laravel 11 API (Railway)
        │
   ┌────┴────┐
Supabase   Firebase FCM
(data)     (push notif)
```

State management: **StatefulWidget + setState** — tidak menggunakan Riverpod atau BLoC.
Semua state disimpan di dalam widget tree masing-masing screen.
Untuk state yang perlu dibagi antar widget (misal: cart/order summary), gunakan `InheritedWidget` atau pass via konstruktor.

---

## 2. Folder Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          ← semua color token
│   │   ├── app_typography.dart      ← TextStyle untuk heading dan body
│   │   ├── app_spacing.dart         ← spacing constants (4, 8, 12, 16, 24, 32)
│   │   └── app_radius.dart          ← border radius (8, 12, 16)
│   ├── theme/
│   │   └── app_theme.dart           ← ThemeData lengkap
│   ├── network/
│   │   ├── api_client.dart          ← Dio instance + interceptors
│   │   └── api_endpoints.dart       ← semua URL sebagai const String
│   ├── services/
│   │   ├── auth_service.dart        ← token read/write via SecureStorage
│   │   └── fcm_service.dart         ← FCM init, foreground handler, background handler
│   └── utils/
│       ├── currency_formatter.dart  ← formatRupiah(double amount) → "Rp 15.000"
│       └── snackbar_helper.dart     ← showErrorSnackbar, showSuccessSnackbar
│
├── features/
│   ├── auth/
│   │   └── screens/
│   │       └── login_screen.dart
│   │
│   ├── pos/
│   │   ├── models/
│   │   │   ├── menu.dart
│   │   │   ├── category.dart
│   │   │   ├── condiment_group.dart
│   │   │   ├── condiment_option.dart
│   │   │   └── order_item_draft.dart  ← item di cart sebelum di-POST
│   │   ├── services/
│   │   │   └── menu_service.dart      ← GET /menus, GET /categories
│   │   └── screens/
│   │       ├── pos_screen.dart
│   │       ├── condiment_bottom_sheet.dart
│   │       ├── confirm_payment_screen.dart
│   │       ├── qris_payment_screen.dart
│   │       ├── va_payment_screen.dart
│   │       └── receipt_screen.dart
│   │
│   ├── orders/
│   │   ├── models/
│   │   │   ├── order.dart
│   │   │   └── order_item.dart
│   │   ├── services/
│   │   │   └── order_service.dart     ← GET staff/orders, PATCH status, POST orders
│   │   └── screens/
│   │       ├── incoming_orders_screen.dart
│   │       └── order_detail_screen.dart
│   │
│   └── queue/
│       ├── services/
│       │   └── queue_service.dart     ← GET /queue/active, GET /queue/estimate
│       └── screens/
│           └── queue_screen.dart
│
├── shared/
│   └── widgets/
│       ├── brew_button.dart           ← primary CTA button
│       ├── brew_text_field.dart       ← styled TextField
│       ├── status_badge.dart          ← colored chip untuk order status
│       ├── shimmer_loader.dart        ← loading placeholder
│       ├── empty_state_widget.dart    ← icon + message
│       └── confirm_dialog.dart        ← reusable AlertDialog
│
├── router/
│   └── app_router.dart               ← go_router config
│
└── main.dart
```

---

## 3. Design System Implementation

### 3.1 Color Constants

```dart
// lib/core/constants/app_colors.dart
class AppColors {
  static const Color primary   = Color(0xFF3E2723); // Espresso Brown
  static const Color secondary = Color(0xFFF5F5DC); // Oatmeal/Cream
  static const Color accent    = Color(0xFF81C784); // Matcha Green
  static const Color alert     = Color(0xFFE57373); // Cinnamon Red

  // Derived
  static const Color primaryLight  = Color(0xFF6A4F4B);
  static const Color background    = Color(0xFFF5F5DC);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color onPrimary     = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider       = Color(0xFFE0E0E0);
}
```

### 3.2 Typography Constants

```dart
// lib/core/constants/app_typography.dart
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Poppins — heading
  static TextStyle heading1 = GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700);
  static TextStyle heading2 = GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle heading3 = GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle heading4 = GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600);

  // Roboto — body
  static TextStyle body1    = GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle body2    = GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle caption  = GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle label    = GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500);
}
```

### 3.3 Spacing Constants

```dart
// lib/core/constants/app_spacing.dart
class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 24.0;
  static const double xxl = 32.0;
}
```

---

## 4. Screen Specifications

### 4.1 LoginScreen

```
Layout: Column, center vertical
Components:
  - Logo/ilustrasi coffee shop di atas
  - Text "Selamat Datang" — heading2, color primary
  - Text "Masuk dengan akun kasir Anda" — body2, color textSecondary
  - TextField email (BrewTextField)
  - TextField password (BrewTextField, obscured, toggle visibility)
  - BrewButton "Masuk" (full width, primary)
  - Loading indicator di dalam tombol saat request berlangsung

Behavior:
  - Tombol disabled saat email atau password kosong
  - Error message ditampilkan di bawah tombol jika login gagal
  - Setelah sukses: navigate replace ke MainScreen (bottom nav)
```

### 4.2 POSScreen

```
Layout: Scaffold dengan AppBar + Column body
AppBar:
  - Title "POS" — heading3, onPrimary
  - Background: primary
  - Action: ikon logout (IconButton)

Body (Column):
  ┌─────────────────────────────────────┐
  │ SearchBar + Filter Chips (kategori) │
  ├─────────────────────────────────────┤
  │                                     │
  │  GridView menu (3 kolom)            │
  │  Setiap card:                       │
  │  - Image (CachedNetworkImage)       │
  │  - Nama menu (heading4)             │
  │  - Harga (body2, color primary)     │
  │                                     │
  ├─────────────────────────────────────┤
  │ Order Summary Panel (expandable)    │
  │ - Item count badge                  │
  │ - Total                             │
  │ - Tombol "Proses Pembayaran"        │
  └─────────────────────────────────────┘

Notes:
  - Order Summary Panel tertutup saat tidak ada item
  - Order Summary Panel terbuka minimal saat ada item (snap to 30% height)
  - Filter chips di-scroll horizontal
```

### 4.3 CondimentBottomSheet

```
Tipe: DraggableScrollableSheet, initial 60%, max 90%

Layout: Column
  - Handle bar (abu-abu, lebar 40px, height 4px, radius 2px)
  - Text "[Nama Menu]" — heading3
  - Text "Pilih pilihan untuk pesanan ini" — body2, textSecondary
  - ListView condiment groups:
      Setiap grup:
        - Label nama grup + badge "Wajib" merah jika is_required
        - Daftar opsi (Radio atau Checkbox)
        - Setiap baris opsi = komponen dari Figma:
            Row, padding 8-9px 12px, space-between
            Kiri: nama opsi (body2)
            Kanan: "+Rp X.XXX" jika additional_price > 0 (caption, accent)
  - Tombol "Tambah ke Order" — BrewButton full width, primary
  - Counter quantity (+/-) di atas tombol

Behavior:
  - Validasi required group sebelum tambah
  - Error state: label grup berwarna alert jika belum diisi
```

### 4.4 ConfirmPaymentScreen

```
AppBar: "Konfirmasi Pembayaran", background primary, back button

Body: ListView
  - Card "Ringkasan Pesanan"
      Setiap item: nama + condiment summary + harga × qty
  - Divider
  - Row Subtotal
  - Row Diskon (jika ada — tidak relevan untuk walk-in kasir)
  - Row Total (heading3, bold, primary)
  - Divider
  - Card "Metode Pembayaran"
      SegmentedButton: Cash | QRIS | Virtual Account
  - Jika Cash:
      TextField "Uang Diterima" (numeric keyboard)
      Row "Kembalian: Rp X.XXX" — realtime, merah jika negatif
  - Jika Virtual Account:
      Dropdown pilih bank (BCA, BNI, BRI, Mandiri)

Footer:
  - BrewButton "Konfirmasi Bayar" full width
  - Disabled jika Cash dan kembalian negatif
```

### 4.5 QRISPaymentScreen

```
AppBar: "Pembayaran QRIS", no back button (prevent accidental back)

Body: Column, center
  - Text "Scan QR Code berikut" — heading3
  - QR Image dari qr_code_url (Image.network, 220×220)
  - Text total — heading2, primary
  - Text "Menunggu pembayaran..." — body2, textSecondary
  - AnimatedContainer loading indicator (pulsing)
  - Tombol "Batalkan Pesanan" (TextButton, alert color)

Behavior:
  - Polling setiap 3 detik ke GET /orders/{id}/payment-status
  - Saat paid: navigate replace ke ReceiptScreen
  - Saat batalkan: confirm dialog → DELETE order → navigate ke POS
```

### 4.6 VAPaymentScreen

```
AppBar: "Pembayaran Virtual Account", no back button

Body: Column, center
  - Badge bank name (logo/text)
  - Text "Nomor Virtual Account" — label, textSecondary
  - Text [va_number] — heading1, primary, copyable (tap to copy)
  - Text total — heading2
  - Card instruksi transfer singkat
  - Text "Menunggu konfirmasi pembayaran..." — body2
  - Tombol "Batalkan Pesanan" (TextButton, alert color)

Behavior:
  - Polling setiap 5 detik
  - Saat paid: navigate replace ke ReceiptScreen
```

### 4.7 ReceiptScreen

```
AppBar: "Pesanan Diterima", no back button

Body: Column, center
  - Icon check circle (accent, size 64)
  - Text "Pembayaran Berhasil" — heading2, accent
  - Divider
  - Text "Nomor Antrian" — label, textSecondary
  - Text "[XXX]" — 72sp, bold, primary (3-digit leading zero)
  - Divider
  - Card ringkasan item: nama + qty + harga per baris
  - Row Total dibayar
  - Jika Cash: Row Kembalian

Footer:
  - BrewButton "Pesanan Baru" — primary, full width
```

### 4.8 IncomingOrdersScreen

```
AppBar: "Pesanan Masuk", background primary
  - Badge count di icon tab bottom nav (bukan di AppBar)

Body:
  - FilterTabBar: Semua | Pending | Diproses | Siap (horizontal scrollable)
  - ListView order cards:

Order Card Layout:
  ┌──────────────────────────────────────┐
  │ [accent left bar]  #001              │
  │                    Nama Customer     │
  │                    2 item · Rp 45K   │
  │                    12:30 · preorder  │
  │                    [StatusBadge]     │
  │                                      │
  │ [Batalkan]    [Mulai Proses / Siap] │
  └──────────────────────────────────────┘

  - Left accent bar warna sesuai status:
      pending    → alert (#E57373)
      processing → primary (#3E2723)
      ready      → accent (#81C784)
      completed  → grey

  - Tombol aksi per status:
      pending    → "Mulai Proses" (primary button)
      processing → "Siap Diambil" (accent button)
      ready      → "Selesai" (grey outlined)
      all        → "Batalkan" (alert outlined, kiri)

Behavior:
  - Pull to refresh
  - Tap card → navigasi ke OrderDetailScreen
  - Saat FCM masuk: jika halaman ini aktif, refresh otomatis
```

### 4.9 OrderDetailScreen

```
AppBar: "Detail Pesanan #[queue_number]", back button

Body: ListView
  - Card Info Pelanggan:
      Nama, nomor telepon (jika ada)
      Waktu pesan, tipe (preorder/walkin)
      Waktu pickup (jika preorder)
  - Card Info Pesanan:
      Nomor antrian besar
      StatusBadge status saat ini
  - Card Daftar Item:
      Setiap item: nama menu, qty, condiment list, harga
  - Card Pembayaran:
      Metode, status (Paid/Unpaid), total
  - Riwayat Status (log):
      Timeline sederhana dari order_status_logs

Footer (jika order masih aktif):
  - Tombol aksi sesuai status (sama dengan di IncomingOrdersScreen)
```

### 4.10 QueueScreen

```
AppBar: "Antrian Aktif", background primary

Body:
  - Text "Estimasi tunggu: X menit" — body2, textSecondary
  - ListView queue cards:

Queue Card:
  ┌──────────────────────────────────────┐
  │  001          [StatusBadge]          │
  │  ──────────────────────────────────  │
  │  Nama Customer · 2 item             │
  └──────────────────────────────────────┘

  - Nomor antrian: 48sp, bold, primary
  - Card dengan border accent jika status = ready

Behavior:
  - Auto refresh setiap 10 detik (Timer.periodic)
  - Cancel timer saat screen di-dispose
  - Pull to refresh manual
```

---

## 5. Data Models

```dart
// lib/features/pos/models/menu.dart
class Menu {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isActive;
  final MenuCategory category;
  final List<CondimentGroup> condimentGroups;

  // fromJson factory constructor
}

// lib/features/pos/models/order_item_draft.dart
// Digunakan untuk state cart di POSScreen (sebelum di-POST ke API)
class OrderItemDraft {
  final Menu menu;
  int quantity;
  final List<CondimentOption> selectedCondiments;
  String? notes;

  double get subtotal {
    double condimentTotal = selectedCondiments
        .fold(0, (sum, c) => sum + c.additionalPrice);
    return (menu.price + condimentTotal) * quantity;
  }
}

// lib/features/orders/models/order.dart
class Order {
  final int id;
  final String? customerName;
  final int? cashierId;
  final String orderType;       // preorder | walkin
  final String status;          // pending | processing | ready | completed | cancelled
  final String paymentMethod;   // cash | qris | virtual_account
  final String paymentStatus;   // unpaid | paid
  final int queueNumber;
  final double subtotal;
  final double discountAmount;
  final double total;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime? pickupTime;

  // fromJson factory constructor
}
```

---

## 6. Network Layer

### 6.1 Dio Setup

```dart
// lib/core/network/api_client.dart
class ApiClient {
  static Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));

    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(LogInterceptor()); // debug only
    return dio;
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AuthService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await AuthService.clearToken();
      // Navigate to login — gunakan GlobalKey<NavigatorState> atau go_router redirect
    }
    handler.next(err);
  }
}
```

### 6.2 API Endpoints

```dart
// lib/core/network/api_endpoints.dart
class ApiEndpoints {
  // Auth
  static const String login        = '/auth/login';
  static const String logout       = '/auth/logout';
  static const String me           = '/auth/me';
  static const String fcmToken     = '/auth/fcm-token';

  // Menu (public)
  static const String menus        = '/menus';
  static const String categories   = '/categories';

  // Orders (staff)
  static String menuDetail(int id)     => '/menus/$id';
  static const String createOrder      = '/orders';
  static const String staffOrders      = '/staff/orders';
  static String staffOrderDetail(int id) => '/staff/orders/$id';
  static String updateOrderStatus(int id) => '/staff/orders/$id/status';
  static String orderPaymentStatus(int id) => '/orders/$id/payment-status';
  static String cancelOrder(int id)    => '/orders/$id';

  // Queue
  static const String queueActive    = '/queue/active';
  static const String queueEstimate  = '/queue/estimate';
}
```

---

## 7. FCM Setup

```dart
// lib/core/services/fcm_service.dart
class FcmService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Request permission (Android 13+)
    await FirebaseMessaging.instance.requestPermission();

    // Update FCM token ke server
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _updateTokenToServer(token);

    // Listen token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_updateTokenToServer);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Terminated state tap
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Tampilkan local notification via flutter_local_notifications
    // Jika type = new_order: trigger refresh di IncomingOrdersScreen
    LocalNotificationService.show(message);
    NotificationEventBus.emit(message.data['type'], message.data);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'new_order') {
      // Navigate ke IncomingOrdersScreen
      AppRouter.router.go('/incoming-orders');
    }
  }
}
```

---

## 8. Router Configuration

```dart
// lib/router/app_router.dart
final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) async {
    final token = await AuthService.getToken();
    final isLoginPage = state.matchedLocation == '/login';
    final isSplash    = state.matchedLocation == '/splash';

    if (isSplash) return null;
    if (token == null && !isLoginPage) return '/login';
    if (token != null && isLoginPage) return '/pos';
    return null;
  },
  routes: [
    GoRoute(path: '/splash',     builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login',      builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/pos',             builder: (_, __) => const POSScreen()),
        GoRoute(path: '/incoming-orders', builder: (_, __) => const IncomingOrdersScreen()),
        GoRoute(path: '/queue',           builder: (_, __) => const QueueScreen()),
      ],
    ),
    GoRoute(
      path: '/confirm-payment',
      builder: (context, state) {
        final extra = state.extra as ConfirmPaymentArgs;
        return ConfirmPaymentScreen(args: extra);
      },
    ),
    GoRoute(
      path: '/qris-payment',
      builder: (context, state) {
        final extra = state.extra as QrisPaymentArgs;
        return QRISPaymentScreen(args: extra);
      },
    ),
    GoRoute(
      path: '/va-payment',
      builder: (context, state) {
        final extra = state.extra as VaPaymentArgs;
        return VAPaymentScreen(args: extra);
      },
    ),
    GoRoute(
      path: '/receipt',
      builder: (context, state) {
        final extra = state.extra as ReceiptArgs;
        return ReceiptScreen(args: extra);
      },
    ),
    GoRoute(
      path: '/order-detail/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return OrderDetailScreen(orderId: id);
      },
    ),
  ],
);
```

---

## 9. Order Creation Payload

```json
// POST /api/orders — Walk-in dari kasir
{
  "order_type": "walkin",
  "payment_method": "cash",
  "payment_channel": null,
  "items": [
    {
      "menu_id": 1,
      "quantity": 2,
      "condiment_option_ids": [3, 7],
      "notes": null
    }
  ],
  "promo_code": null,
  "notes": null
}

// POST /api/orders — Walk-in QRIS
{
  "order_type": "walkin",
  "payment_method": "qris",
  "items": [ ... ]
}

// POST /api/orders — Walk-in Virtual Account
{
  "order_type": "walkin",
  "payment_method": "virtual_account",
  "payment_channel": "bca",
  "items": [ ... ]
}
```

---

## 10. Sequence Diagrams

### 10.1 Walk-in Cash Payment

```
POSScreen         ConfirmPaymentScreen    Laravel API
    │                     │                    │
    │ tap menu             │                    │
    │ add to cart          │                    │
    │ "Proses Pembayaran"  │                    │
    │─────────────────────►│                    │
    │                      │ input uang         │
    │                      │ hitung kembalian   │
    │                      │ "Konfirmasi Bayar" │
    │                      │────────────────────►
    │                      │                    │ validate stock
    │                      │                    │ create order
    │                      │                    │ deduct stock
    │                      │ {order, queue_no} ◄│
    │                      │                    │
    │         ReceiptScreen │                    │
    │◄─────────────────────│                    │
```

### 10.2 Incoming Order Processing

```
FCM               IncomingOrdersScreen    Laravel API    Customer App
 │                       │                    │               │
 │ new_order notif        │                    │               │
 │──────────────────────►│                    │               │
 │                       │ refresh list       │               │
 │                       │────────────────────►              │
 │                       │◄── order list      │               │
 │                       │                    │               │
 │                       │ "Mulai Proses"     │               │
 │                       │────────────────────►              │
 │                       │                    │ update status │
 │                       │                    │ send FCM ────►│
 │                       │◄── 200 OK          │               │
 │                       │ update card UI     │               │
```

---

## 11. pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^13.0.0
  dio: ^5.0.0
  flutter_secure_storage: ^9.0.0
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^17.0.0
  cached_network_image: ^3.0.0
  google_fonts: ^6.0.0
  shimmer: ^3.0.0
  intl: ^0.19.0
```
