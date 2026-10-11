import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire 401 handler: clear token & bounce to login.
  ApiClient.onUnauthorized = () async {
    await AuthService.clearToken();
    AppRouter.router.go('/login');
  };

  // FCM init. Silently skips if google-services.json belum dipasang.
  await FcmService.initialize();

  runApp(const KoncoSpaceEmployeeApp());
}

class KoncoSpaceEmployeeApp extends StatelessWidget {
  const KoncoSpaceEmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Konco Space - Aplikasi Kasir',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}
