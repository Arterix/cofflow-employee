import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/notification_event_bus.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/brew_button.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_action_helper.dart';

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all'; // all | pending | processing | ready
  StreamSubscription<NotificationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _load();
    _subscription = NotificationEventBus.stream.listen((event) {
      if (event.type == 'new_order' || event.type == 'order_status') {
        _load(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final list = await OrderService.getStaffOrders(type: 'preorder');
      if (!mounted) return;
      setState(() {
        _orders = list.where((o) => o.isActive).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  List<Order> get _filtered {
    if (_filter == 'all') return _orders;
    return _orders.where((o) => o.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterTabBar(active: _filter, onChanged: (f) => setState(() => _filter = f)),
        const Divider(height: 1),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerList(itemCount: 4, itemHeight: 140);
    }
    if (_error != null) {
      return EmptyStateWidget(
        icon: Icons.wifi_off,
        message: _error!,
        onRetry: _load,
      );
    }
    final list = _filtered;
    if (list.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        message: 'Belum ada pesanan masuk',
      );
    }
    final isWide = context.isWide;
    return RefreshIndicator(
      onRefresh: _load,
      child: isWide
          ? GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 480,
                mainAxisExtent: 185,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) => _OrderCard(
                order: list[i],
                onUpdate: () => _load(silent: true),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _OrderCard(
                order: list[i],
                onUpdate: () => _load(silent: true),
              ),
            ),
    );
  }
}

class _FilterTabBar extends StatelessWidget {
  const _FilterTabBar({required this.active, required this.onChanged});
  final String active;
  final ValueChanged<String> onChanged;

  static const _filters = [
    ('all', 'Semua'),
    ('pending', 'Pending'),
    ('processing', 'Diproses'),
    ('ready', 'Siap'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (final (val, label) in _filters)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.xs,
              ),
              child: ChoiceChip(
                label: Text(label),
                selected: active == val,
                onSelected: (_) => onChanged(val),
                selectedColor: AppColors.primary,
                labelStyle: AppTypography.label.copyWith(
                  color: active == val
                      ? AppColors.onPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onUpdate});

  final Order order;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/order-detail/${order.id}'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: order.statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${order.queueNumberFormatted}',
                            style: AppTypography.heading3,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              order.customerName ?? '—',
                              style: AppTypography.body2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.items.length} item · ${formatRupiah(order.total)}',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${DateFormat('HH:mm').format(order.createdAt)} · ${order.orderType}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ActionRow(order: order, onUpdate: onUpdate),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.order, required this.onUpdate});
  final Order order;
  final VoidCallback onUpdate;

  Future<void> _act(BuildContext context, String newStatus) async {
    final result = await OrderActionHelper.transition(
      context,
      orderId: order.id,
      newStatus: newStatus,
    );
    if (result != null && context.mounted) {
      showSuccessSnackbar(context, 'Status diperbarui');
      onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];
    if (order.status == 'pending') {
      buttons.add(_btn('Mulai Proses', () => _act(context, 'processing')));
    } else if (order.status == 'processing') {
      buttons.add(_btn('Siap Diambil', () => _act(context, 'ready'),
          color: AppColors.accent));
    } else if (order.status == 'ready') {
      buttons.add(_btn('Selesai', () => _act(context, 'completed')));
    }
    if (order.status != 'completed' && order.status != 'cancelled') {
      buttons.add(_btn(
        'Batalkan',
        () => _act(context, 'cancelled'),
        outlined: true,
        color: AppColors.alert,
      ));
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }

  Widget _btn(
    String label,
    VoidCallback onPressed, {
    Color? color,
    bool outlined = false,
  }) {
    return BrewButton(
      label: label,
      onPressed: onPressed,
      color: color,
      outlined: outlined,
      isFullWidth: false,
    );
  }
}
