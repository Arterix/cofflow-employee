# Cofflow Employee App — API Integration Contract

Authoritative reference for connecting the **Employee Flutter app** (kasir + admin roles) to the Cofflow Laravel API. All shapes pulled from real backend controllers.

Backend repo: `cofflowdashboard/` (Laravel 11 on Railway).

---

## 1. Base

```
Base URL (prod):  https://{railway-domain}/api
Base URL (dev):   http://10.0.2.2:8000/api   (Android emulator → host)
Content-Type:     application/json
Accept:           application/json
Auth header:      Authorization: Bearer {sanctum_token}
```

### Envelope (every response)
```json
{ "success": true,  "data": <any>,  "message": "OK" }
{ "success": false, "data": null,   "message": "..." }
```

### HTTP status
| Code | Meaning | Client action |
|------|---------|---------------|
| 200 | OK | proceed |
| 201 | Created | proceed |
| 401 | Token invalid / revoked | clear token → `/login` |
| 403 | Wrong role or inactive | show message, do NOT auto-logout if already logged in |
| 404 | Not found | show empty state |
| 422 | Business rule (invalid status transition, insufficient stock) | show `message` inline |
| 429 | Login rate-limited | show "coba lagi sebentar" |

Validation errors may carry `errors: { field: [msgs] }` alongside `message`.

---

## 2. Auth (with role gate)

The employee app **must** reject `role == "customer"` on login client-side. Backend does not block customers from `/auth/login` itself — only from `/staff/*` and `/admin/*` endpoints. The app is responsible for refusing to proceed when the wrong role logs in.

### 2.1 Login — `POST /auth/login` (public, rate-limited 10/min)

Request: `{ "email": "...", "password": "..." }`

Response 200:
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "user": {
      "id": 3, "name": "Kasir Andi", "email": "andi@cofflow.id",
      "phone": "08123...", "role": "kasir",
      "is_active": true, "avatar_url": null, "fcm_token": null,
      "created_at": "...", "updated_at": "..."
    },
    "token": "3|plaintext..."
  }
}
```

**Client-side gate (mandatory):**
```dart
if (user.role == 'customer') {
  await logout();
  throw 'Akun ini tidak memiliki akses ke aplikasi pegawai';
}
// allow: role == 'kasir' || role == 'admin'
```

Backend errors:
- 401 `"Email atau password salah"`
- 403 `"Akun kamu dinonaktifkan"`

### 2.2 Me — `GET /auth/me` (auth)

`data` = full user object. Call on cold start. If role drifts to `customer` (admin demoted them), force logout.

### 2.3 Logout — `POST /auth/logout` (auth)
`data: null`. Deletes current token only.

### 2.4 Change password — `PUT /auth/change-password` (auth)

Request: `{ "old_password": "...", "new_password": "min8" }`.

Response: `{ "data": { "token": "NEW_TOKEN" } }` — **all old tokens are revoked**. Replace stored token immediately.

### 2.5 FCM token — `PATCH /auth/fcm-token` (auth)

Request: `{ "fcm_token": "..." }` (string, max 500). Call after login + `onTokenRefresh`.

### Important: Admin can revoke this account
Admin endpoints `PATCH /admin/staff/{id}/toggle` and `PUT /admin/staff/{id}` (role change) wipe all Sanctum tokens for the affected user. The next API call from this app returns **401** → handle it as a normal token-expiry redirect to `/login`.

---

## 3. Queue Board (kasir + admin)

### 3.1 Active queue — `GET /queue/active`

Today's orders (`whereDate(created_at, today)`) with `status IN (pending, processing)`, sorted by `queue_number ASC`. Eager-loads `user` + `items.menu`.

```json
[
  {
    "id": 88,
    "user_id": 12,
    "cashier_id": null,
    "order_type": "preorder",
    "status": "pending",
    "payment_method": "qris",
    "payment_status": "paid",
    "payment_channel": null,
    "queue_number": 7,
    "pickup_time": "2026-05-19T14:30:00.000000Z",
    "subtotal": "61000.00",
    "discount_amount": "12200.00",
    "total": "48800.00",
    "notes": "Less ice",
    "created_at": "...", "updated_at": "...",
    "user": { "id": 12, "name": "Budi", "phone": "08123..." },
    "items": [
      { "id": 201, "menu_id": 12, "quantity": 2, "unit_price": "28000.00",
        "menu": { "id": 12, "name": "Cappuccino", "image_url": "..." } }
    ]
  }
]
```

Refresh strategy:
- Initial load on screen mount
- Pull-to-refresh (`RefreshIndicator`)
- On focus regained (`WidgetsBindingObserver`)
- On every incoming FCM with `type == "new_order"`

Do not poll continuously — wasteful. FCM is the push channel.

### 3.2 Estimate — `GET /queue/estimate`

```json
{ "success": true, "data": { "active_count": 4, "estimated_minutes": 20 } }
```
Formula: `active_count × 5`. Display as "Estimasi: ~20 menit".

---

## 4. Staff Order Management

### 4.1 List orders — `GET /staff/orders?status=&type=&date=`

Returns **all** orders (not filtered by current user). Eager-loads `user` + `items.menu` + `items.condiments`. Ordered by `created_at DESC`.

Query filters (all optional, combine as needed):
| Param | Values |
|-------|--------|
| `status` | `pending` \| `processing` \| `ready` \| `completed` \| `cancelled` |
| `type` | `preorder` \| `walkin` |
| `date` | `YYYY-MM-DD` |

Example: `/staff/orders?status=ready&date=2026-05-19`

### 4.2 Order detail — `GET /staff/orders/{id}`

Eager-loads: `user`, `cashier`, `items.menu`, `items.condiments`, `statusLogs.changedBy`.

```json
{
  "id": 88,
  "user_id": 12,
  "cashier_id": 3,
  "order_type": "preorder",
  "status": "processing",
  "payment_method": "qris",
  "payment_status": "paid",
  "queue_number": 7,
  "subtotal": "61000.00", "discount_amount": "12200.00", "total": "48800.00",
  "user": { "id": 12, "name": "Budi", "phone": "08...", "email": "budi@..." },
  "cashier": { "id": 3, "name": "Kasir Andi", "role": "kasir" },
  "items": [
    {
      "id": 201, "menu_id": 12, "quantity": 2,
      "unit_price": "28000.00", "applied_discount": "5600.00", "notes": null,
      "menu": { "id": 12, "name": "Cappuccino", "image_url": "..." },
      "condiments": [
        { "condiment_option_id": 7, "option_name": "Regular", "additional_price": "0.00" }
      ]
    }
  ],
  "status_logs": [
    { "id": 1, "status": "pending",    "changed_by": null,
      "changed_by_user": null,                                 "created_at": "..." },
    { "id": 2, "status": "processing", "changed_by": 3,
      "changed_by_user": { "id": 3, "name": "Kasir Andi" },    "created_at": "..." }
  ]
}
```

(Field name in eager-load is `statusLogs.changedBy` → serialized as `status_logs[].changed_by_user`. Use `changed_by` int for ownership, `changed_by_user` for display.)

### 4.3 Update status — `PATCH /staff/orders/{id}/status`

Request:
```json
{ "status": "processing", "notes": "optional reason" }
```

**Valid transitions (enforced by backend, also enforce client-side):**

| From | Allowed `status` values |
|------|------------------------|
| `pending` | `processing`, `cancelled` |
| `processing` | `ready`, `cancelled` |
| `ready` | `completed` |
| `completed` | (none — terminal) |
| `cancelled` | (none — terminal) |

Any other combination → 422 with message `"Transisi status dari {current} ke {new} tidak diperbolehkan"`.

Response 200, `data` = updated order (post-update fields). Backend also:
- Inserts a row in `order_status_logs` with `changed_by = auth.id`
- Sends FCM `order_status` to customer (via `OrderObserver`)
- If `status → cancelled`, restores stock + sends FCM cancellation

UI action button matrix:

| Current `status` | Buttons to render |
|------------------|-------------------|
| `pending` | "Mulai Proses" → `processing`, "Batalkan" → `cancelled` |
| `processing` | "Tandai Siap" → `ready`, "Batalkan" → `cancelled` |
| `ready` | "Konfirmasi Diambil" → `completed` |
| `completed` / `cancelled` | none (read-only) |

Always wrap action in a `ConfirmDialog`.

---

## 5. Walk-in Order Creation (kasir / admin)

Reuses `POST /orders`. Differences from customer flow:

- Logged-in user IS the cashier → backend auto-sets `cashier_id = auth.id`
- `user_id` is also set to `auth.id` by the controller (no separate "guest customer" path in current backend). If you want a true walk-in with no customer, that's a backend change — discuss before building UI for it.
- `order_type` MUST be `"walkin"`
- `pickup_time` should be `null` (walk-in = immediate)
- Common `payment_method` for walk-in is `"cash"` → backend sets `payment_status = "paid"` instantly, no QR / VA

### 5.1 Create walk-in — `POST /orders`

```json
{
  "order_type": "walkin",
  "payment_method": "cash",
  "items": [
    { "menu_id": 12, "quantity": 1, "condiment_option_ids": [7] }
  ]
}
```

Same validation rules as customer flow (see Customer API_CONTRACT §4.1).

Same business errors:
- `"Stok {nama bahan} tidak mencukupi untuk membuat {nama menu}"`
- `"Kode promo sudah habis digunakan"` / `"sudah tidak berlaku"`
- `"Minimum order Rp {n}"`
- `"payment_channel wajib diisi untuk virtual_account"`

Response 201 — same shape as customer order creation, with cashier-set fields populated. If `payment_method == "qris"` or `"virtual_account"`, the response still includes `qr_code_url` / `va_number` — useful for showing it to the customer at the counter (display on tablet).

---

## 6. Notifications

### 6.1 List — `GET /notifications`

Up to 100 most recent, for current user (the employee). Same envelope as customer app.

Types relevant to employee:
| `type` | Sent to | Trigger |
|--------|---------|---------|
| `new_order` | kasir + admin | preorder created |
| `stock_critical` | admin only | ingredient dropped below `minimum_stock` |
| `order_status` | the kasir who owns the order (rare — usually just customer) | — |

Example:
```json
{
  "id": 90,
  "title": "Pesanan Baru Masuk",
  "body":  "Order #88 dari Budi",
  "type":  "new_order",
  "data":  { "type": "new_order", "order_id": "88" },
  "is_read": false,
  "created_at": "..."
}
```

### 6.2 Mark one — `PATCH /notifications/{id}/read`
### 6.3 Mark all — `POST /notifications/mark-all-read`
### 6.4 Unread count — `GET /notifications/unread-count` → `{ "unread_count": N }`

Use unread count for app-bar badge. Refresh on every FCM arrival.

---

## 7. FCM Wiring

### Setup
1. Same Firebase project as backend.
2. Drop `google-services.json` into `android/app/`.
3. Request POST_NOTIFICATIONS permission (Android 13+).
4. Send token after login via `PATCH /auth/fcm-token`.
5. Background handler with `@pragma('vm:entry-point')`.
6. Foreground messages → `flutter_local_notifications` to display banner.

### Payloads the employee app receives

```json
// New preorder created (sent to all kasir + admin with fcm_token != null)
{
  "title": "Pesanan Baru Masuk",
  "body":  "Order #88 dari Budi",
  "data":  { "type": "new_order", "order_id": "88" }
}

// Ingredient critical (admin role only)
{
  "title": "Stok Hampir Habis",
  "body":  "Susu UHT tersisa 0.5 liter",
  "data":  { "type": "stock_critical", "ingredient_id": "5" }
}
```

All `data` values are **strings** (FCM constraint) — `int.parse` before use.

Routing:
```dart
switch (message.data['type']) {
  case 'new_order':
    router.push('/orders/${message.data['order_id']}');
    ref.read(activeQueueProvider.notifier).refresh();
  case 'stock_critical':
    if (currentUser.role == 'admin') {
      router.push('/notifications');
    }
}
```

Side effects to fire on every FCM:
- Refetch `/notifications/unread-count` → update badge
- If on Queue screen and `type == "new_order"` → silent re-fetch `/queue/active`

---

## 8. Endpoint Allow-list (Employee App)

```
POST   /auth/login
POST   /auth/logout
GET    /auth/me
PUT    /auth/change-password
PATCH  /auth/fcm-token

GET    /menus              ← for walk-in cart UI (same public endpoint)
GET    /menus/{id}
GET    /categories

POST   /orders             ← walk-in creation
GET    /orders/{id}/payment-status   ← only if walk-in uses QRIS/VA

GET    /staff/orders
GET    /staff/orders/{id}
PATCH  /staff/orders/{id}/status

GET    /queue/active
GET    /queue/estimate

GET    /notifications
PATCH  /notifications/{id}/read
POST   /notifications/mark-all-read
GET    /notifications/unread-count
```

**Forbidden** from employee app: `/admin/*` (will 403 unless logged in as admin, but admin management is a web-only flow — do not build mobile UI for it).

Customer-only endpoints **not** for employee app: `/auth/register`, `GET /orders`, `GET /orders/{id}`, `DELETE /orders/{id}` (these scope to `user_id == auth.id` — employee should use `/staff/orders/*` instead).

---

## 9. Differences vs Customer App (quick diff)

| Concern | Customer | Employee |
|---------|----------|----------|
| Register endpoint | yes | no |
| Allowed login roles | `customer` only | `kasir`, `admin` only |
| Order list endpoint | `GET /orders` (own only) | `GET /staff/orders` (all) |
| Order detail endpoint | `GET /orders/{id}` (own) | `GET /staff/orders/{id}` (any) |
| Status update | `DELETE /orders/{id}` (cancel only, pending only) | `PATCH /staff/orders/{id}/status` (full transitions) |
| Queue endpoints | n/a | `/queue/active`, `/queue/estimate` |
| FCM types received | `order_status`, `payment_confirmed` | `new_order`, `stock_critical` |
| Cart + checkout | yes (preorder) | yes (walk-in flow) |
| Payment screen | needed for QRIS/VA | needed only if walk-in chooses QRIS/VA |
| Polling `/payment-status` | yes, during payment screen | same — only when walk-in is non-cash |

---

## 10. Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Calling `/admin/*` from employee app | 403. Mobile uses `/staff/*` + public `/menus` only |
| Not enforcing client-side role gate on login | Customer can log in → app silently breaks on `/staff/orders` (403) |
| Allowing invalid status transitions in UI | Render only buttons listed in §4.3 matrix |
| Polling `/queue/active` every few seconds | Don't. Use FCM `new_order` + pull-to-refresh |
| Polling `/staff/orders/{id}` for status updates | Don't. Backend pushes `order_status` FCM on every change |
| Forgetting to refresh badge after FCM | Hook `unread-count` refresh into FCM handler |
| Missing `payment_channel` for VA in walk-in | Same rule as customer — required when `payment_method == virtual_account` |
| Stale token after admin demotes you | Treat 401 as auth expiry — redirect to login, surface no scary error |
| Background FCM not invoking handler | Add `@pragma('vm:entry-point')` and register top-level function before `runApp` |
| `data['order_id']` typed as int | FCM `data` is always string. `int.parse(...)` first |

---

## 11. Dio Setup Snippet

```dart
final dio = Dio(BaseOptions(
  baseUrl: dotenv.env['API_BASE_URL']!,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  headers: {'Accept': 'application/json'},
  validateStatus: (s) => s != null && s < 500,
));

dio.interceptors.add(InterceptorsWrapper(
  onRequest: (opts, h) async {
    final token = await storage.read(key: 'token');
    if (token != null) opts.headers['Authorization'] = 'Bearer $token';
    h.next(opts);
  },
  onResponse: (res, h) {
    if (res.statusCode == 401) {
      storage.delete(key: 'token');
      router.go('/login');
    }
    h.next(res);
  },
));
```

---

## 12. Reference Source Files (in backend repo)

When in doubt, the truth lives here:

- `routes/api.php` — full route table
- `app/Http/Controllers/Api/AuthController.php` — login/logout/me/change-password
- `app/Http/Controllers/Api/Staff/StaffOrderController.php` — `/staff/orders/*` shapes + transition rules
- `app/Http/Controllers/Api/Staff/QueueController.php` — `/queue/*` shapes
- `app/Http/Controllers/Api/OrderController.php` — `POST /orders` for walk-in
- `app/Http/Controllers/Api/NotificationController.php`
- `app/Observers/OrderObserver.php` — what FCM events fire and when
- `app/Services/FcmService.php` — exact payload structure
- `database/migrations/2025_01_01_000008_create_orders_table.php` — order columns
- `context/CLAUDE.md` §FCM Notification Payload Structure
