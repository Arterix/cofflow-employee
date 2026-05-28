import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../router/app_router.dart';
import 'auth_service.dart';
import 'local_notification_service.dart';
import 'notification_event_bus.dart';

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Sistem akan menampilkan notifikasi dari payload `notification`.
  // Tidak perlu show local notif di background.
}

class FcmService {
  FcmService._();

  static bool _initialized = false;

  /// Initialize Firebase + FCM. Safe to call multiple times.
  /// If `google-services.json` belum dipasang, exception ditangkap dan
  /// dilog — app tetap jalan tanpa push notification.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      await LocalNotificationService.initialize();

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Initial token upload (no-op kalau belum login).
      final token = await messaging.getToken();
      if (token != null) {
        await _uploadTokenIfLoggedIn(token);
      }

      messaging.onTokenRefresh.listen(_uploadTokenIfLoggedIn);

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onTap);
      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

      final initial = await messaging.getInitialMessage();
      if (initial != null) _onTap(initial);

      _initialized = true;
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[FcmService] init skipped: $e\n$st');
      }
    }
  }

  /// Upload current FCM token to server. Called after login.
  static Future<void> uploadCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _uploadTokenIfLoggedIn(token);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[FcmService] uploadCurrentToken failed: $e');
      }
    }
  }

  static Future<void> _uploadTokenIfLoggedIn(String token) async {
    final auth = await AuthService.getToken();
    if (auth == null || auth.isEmpty) return;
    try {
      await ApiClient.instance.patch(
        ApiEndpoints.fcmToken,
        data: {'fcm_token': token},
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[FcmService] token upload failed: $e');
      }
    }
  }

  static void _onForeground(RemoteMessage message) {
    LocalNotificationService.show(message);
    final type = message.data['type'] as String? ?? 'unknown';
    NotificationEventBus.emit(type, _coerceData(message.data));
  }

  static void _onTap(RemoteMessage message) {
    final type = message.data['type'] as String? ?? '';
    if (type == 'new_order' || type == 'order_update') {
      AppRouter.router.go('/incoming-orders');
    }
  }

  static Map<String, dynamic> _coerceData(Map<String, dynamic> raw) =>
      raw.map((k, v) => MapEntry(k, v));
}
