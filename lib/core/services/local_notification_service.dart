import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'konco_space_orders',
    'Pesanan Konco Space',
    description: 'Notifikasi pesanan masuk dan update status',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel);
    await androidImpl?.requestNotificationsPermission();
  }

  static Future<void> show(RemoteMessage message) async {
    final notif = message.notification;
    final title = notif?.title ?? message.data['title'] as String? ?? 'Konco Space';
    final body = notif?.body ?? message.data['body'] as String? ?? '';
    await _plugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['type'] as String?,
    );
  }
}
