import 'dart:async';

class NotificationEvent {
  const NotificationEvent({required this.type, required this.data});
  final String type;
  final Map<String, dynamic> data;
}

class NotificationEventBus {
  NotificationEventBus._();

  static final StreamController<NotificationEvent> _controller =
      StreamController<NotificationEvent>.broadcast();

  static Stream<NotificationEvent> get stream => _controller.stream;

  static void emit(String type, Map<String, dynamic> data) {
    _controller.add(NotificationEvent(type: type, data: data));
  }

  static Future<void> dispose() => _controller.close();
}
