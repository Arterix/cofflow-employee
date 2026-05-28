import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/brew_button.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_action_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final order = await OrderService.getOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
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

  Future<void> _act(String newStatus) async {
    final updated = await OrderActionHelper.transition(
      context,
      orderId: widget.orderId,
      newStatus: newStatus,
    );
    if (updated != null && mounted) {
      setState(() => _order = updated);
      showSuccessSnackbar(context, 'Status diperbarui');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _order == null
              ? 'Detail Pesanan'
              : 'Detail Pesanan #${_order!.queueNumberFormatted}',
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerList(itemCount: 4, itemHeight: 120);
    }
    if (_error != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        message: _error!,
        onRetry: _load,
      );
    }
    final o = _order!;
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _CustomerCard(order: o),
                const SizedBox(height: AppSpacing.sm),
                _QueueCard(order: o),
                const SizedBox(height: AppSpacing.sm),
                _ItemsCard(order: o),
                const SizedBox(height: AppSpacing.sm),
                _PaymentCard(order: o),
                const SizedBox(height: AppSpacing.sm),
                _TimelineCard(order: o),
              ],
            ),
          ),
        ),
        if (o.isActive) _ActionFooter(order: o, onAct: _act),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pelanggan', style: AppTypography.heading4),
            const SizedBox(height: AppSpacing.sm),
            _row('Nama', order.customerName ?? '—'),
            if (order.customerPhone != null)
              _row('Telepon', order.customerPhone!),
            _row(
              'Waktu Pesan',
              DateFormat('dd MMM yyyy HH:mm').format(order.createdAt),
            ),
            _row('Tipe', order.orderType),
            if (order.pickupTime != null)
              _row(
                'Pickup',
                DateFormat('dd MMM HH:mm').format(order.pickupTime!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                l,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: Text(v, style: AppTypography.body2)),
          ],
        ),
      );
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nomor Antrian',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  order.queueNumberFormatted,
                  style: AppTypography.heading1.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            StatusBadge(status: order.status),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item', style: AppTypography.heading4),
            const SizedBox(height: AppSpacing.sm),
            for (final item in order.items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.quantity}× ', style: AppTypography.body2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.menuName, style: AppTypography.body2),
                        if (item.condiments.isNotEmpty)
                          Text(
                            item.condimentSummary,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Text(
                            'Catatan: ${item.notes}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    formatRupiah(item.lineTotal),
                    style: AppTypography.body2,
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pembayaran', style: AppTypography.heading4),
            const SizedBox(height: AppSpacing.sm),
            _row('Metode', order.paymentMethodLabel),
            _row(
              'Status',
              order.isPaid ? 'Sudah Dibayar' : 'Belum Dibayar',
              color: order.isPaid ? AppColors.accent : AppColors.alert,
            ),
            _row('Subtotal', formatRupiah(order.subtotal)),
            if (order.discountAmount > 0)
              _row('Diskon', '- ${formatRupiah(order.discountAmount)}'),
            const Divider(),
            _row(
              'Total',
              formatRupiah(order.total),
              bold: true,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v, {Color? color, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(l,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  )),
            ),
            Expanded(
              child: Text(
                v,
                style: AppTypography.body2.copyWith(
                  color: color,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    if (order.statusLogs.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riwayat Status', style: AppTypography.heading4),
            const SizedBox(height: AppSpacing.sm),
            for (final log in order.statusLogs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        log.status,
                        style: AppTypography.body2,
                      ),
                    ),
                    if (log.createdAt != null)
                      Text(
                        DateFormat('HH:mm').format(log.createdAt!),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionFooter extends StatelessWidget {
  const _ActionFooter({required this.order, required this.onAct});
  final Order order;
  final ValueChanged<String> onAct;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];
    if (order.status == 'pending') {
      buttons.add(BrewButton(
        label: 'Mulai Proses',
        onPressed: () => onAct('processing'),
        isFullWidth: false,
      ));
    } else if (order.status == 'processing') {
      buttons.add(BrewButton(
        label: 'Siap Diambil',
        onPressed: () => onAct('ready'),
        color: AppColors.accent,
        isFullWidth: false,
      ));
    } else if (order.status == 'ready') {
      buttons.add(BrewButton(
        label: 'Selesai',
        onPressed: () => onAct('completed'),
        isFullWidth: false,
      ));
    }
    if (order.status != 'completed' && order.status != 'cancelled') {
      buttons.add(BrewButton(
        label: 'Batalkan',
        onPressed: () => onAct('cancelled'),
        outlined: true,
        color: AppColors.alert,
        isFullWidth: false,
      ));
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: buttons[i]),
          ],
        ],
      ),
    );
  }
}
