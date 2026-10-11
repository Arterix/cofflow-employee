import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../features/auth/services/auth_api_service.dart';
import '../../features/orders/state/incoming_badge_controller.dart';
import '../../features/pos/state/cart_controller.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final _badge = IncomingBadgeController.instance;
  final _cart = CartController.instance;

  static const List<_TabSpec> _tabs = [
    _TabSpec('/pos', 'POS', Icons.point_of_sale),
    _TabSpec('/cart', 'Keranjang', Icons.shopping_cart_outlined),
    _TabSpec('/incoming-orders', 'Order', Icons.inbox),
    _TabSpec('/queue', 'Antrian', Icons.format_list_numbered),
  ];

  @override
  void initState() {
    super.initState();
    _badge.addListener(_onBadgeChanged);
    _cart.addListener(_onBadgeChanged);
    _badge.refresh();
  }

  @override
  void dispose() {
    _badge.removeListener(_onBadgeChanged);
    _cart.removeListener(_onBadgeChanged);
    super.dispose();
  }

  void _onBadgeChanged() {
    if (mounted) setState(() {});
  }

  int _currentIndex() {
    for (int i = 0; i < _tabs.length; i++) {
      if (widget.location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthApiService.logout();
    CartController.instance.clear();
    IncomingBadgeController.instance.reset();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex();
    final tab = _tabs[index];
    final incomingCount = _badge.pendingCount;
    final cartCount = _cart.itemCount;
    final isWide = context.isWide;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              backgroundColor: AppColors.surface,
              extended: context.screenWidth >= 1200,
              minExtendedWidth: 180,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.coffee, color: AppColors.primary, size: 28),
                    if (context.screenWidth >= 1200) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Konco POS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: AppColors.alert),
                      tooltip: 'Logout',
                      onPressed: () => _confirmLogout(context),
                    ),
                  ),
                ),
              ),
              onDestinationSelected: (i) {
                if (i == index) return;
                context.go(_tabs[i].path);
              },
              destinations: [
                for (int i = 0; i < _tabs.length; i++)
                  NavigationRailDestination(
                    icon: _iconFor(i, incomingCount, cartCount),
                    label: Text(_tabs[i].label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(tab.label),
                  automaticallyImplyLeading: false,
                ),
                body: widget.child,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tab.label),
        actions: [
          IconButton(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        backgroundColor: AppColors.surface,
        onDestinationSelected: (i) {
          if (i == index) return;
          context.go(_tabs[i].path);
        },
        destinations: [
          for (int i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: _iconFor(i, incomingCount, cartCount),
              label: _tabs[i].label,
            ),
        ],
      ),
    );
  }

  Widget _iconFor(int i, int incomingCount, int cartCount) {
    final icon = Icon(_tabs[i].icon);
    // Cart tab (index 1) → badge cart item count
    if (i == 1 && cartCount > 0) {
      return Badge.count(count: cartCount, child: icon);
    }
    // Incoming orders tab (index 2) → badge pending count
    if (i == 2 && incomingCount > 0) {
      return Badge.count(count: incomingCount, child: icon);
    }
    return icon;
  }
}

class _TabSpec {
  const _TabSpec(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}
