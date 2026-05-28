import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/notification_event_bus.dart';
import '../services/order_service.dart';

class IncomingBadgeController extends ChangeNotifier {
  IncomingBadgeController._() {
    _sub = NotificationEventBus.stream.listen((e) {
      if (e.type == 'new_order' || e.type == 'order_status') refresh();
    });
  }
  static final IncomingBadgeController instance = IncomingBadgeController._();

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  StreamSubscription? _sub;
  bool _refreshing = false;

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final list = await OrderService.getStaffOrders(
        type: 'preorder',
        status: 'pending',
      );
      _pendingCount = list.length;
      notifyListeners();
    } catch (_) {
      // ignore — badge stays stale, not critical
    } finally {
      _refreshing = false;
    }
  }

  void reset() {
    _pendingCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
