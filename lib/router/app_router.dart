import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/services/auth_service.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/orders/models/order.dart';
import '../features/orders/screens/incoming_orders_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/pos/screens/cart_screen.dart';
import '../features/pos/screens/confirm_payment_screen.dart';
import '../features/pos/screens/payment_mockup_screen.dart';
import '../features/pos/screens/pos_screen.dart';
import '../features/pos/screens/qris_payment_screen.dart';
import '../features/pos/screens/receipt_screen.dart';
import '../features/pos/screens/va_payment_screen.dart';
import '../features/queue/screens/queue_screen.dart';
import '../shared/widgets/main_scaffold.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;

      final token = await AuthService.getToken();
      final loggedIn = token != null && token.isNotEmpty;
      final atLogin = loc == '/login';

      if (!loggedIn && !atLogin) return '/login';
      if (loggedIn && atLogin) return '/pos';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainScaffold(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/pos',
            builder: (_, _) => const POSScreen(),
          ),
          GoRoute(
            path: '/incoming-orders',
            builder: (_, _) => const IncomingOrdersScreen(),
          ),
          GoRoute(
            path: '/queue',
            builder: (_, _) => const QueueScreen(),
          ),
          GoRoute(
            path: '/cart',
            builder: (_, _) => const CartScreen(),
          ),
        ],
      ),

      // Payment mockup (outside shell, full screen)
      GoRoute(
        path: '/payment-mockup',
        builder: (_, _) => const PaymentMockupScreen(),
      ),

      // Real payment flow (outside shell)
      GoRoute(
        path: '/confirm-payment',
        builder: (_, _) => const ConfirmPaymentScreen(),
      ),
      GoRoute(
        path: '/qris-payment',
        builder: (_, state) {
          final order = state.extra as Order;
          return QRISPaymentScreen(order: order);
        },
      ),
      GoRoute(
        path: '/va-payment',
        builder: (_, state) {
          final order = state.extra as Order;
          return VAPaymentScreen(order: order);
        },
      ),
      GoRoute(
        path: '/receipt',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ReceiptScreen(
            order: extra['order'] as Order,
            cashReceived: extra['cash_received'] as double?,
          );
        },
      ),
      GoRoute(
        path: '/order-detail/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return OrderDetailScreen(orderId: id);
        },
      ),
    ],
  );
}
