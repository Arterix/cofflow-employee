import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/brew_button.dart';
import '../../orders/models/order.dart';
import '../state/cart_controller.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({
    super.key,
    required this.order,
    this.cashReceived,
  });

  final Order order;
  final double? cashReceived;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _newOrder() {
    CartController.instance.clear();
    context.go('/pos');
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final change = widget.cashReceived != null
        ? (widget.cashReceived! - o.total)
        : null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pesanan Diterima'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        const Center(
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.accent,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: Text(
                            'Pembayaran Berhasil',
                            style: AppTypography.heading2.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: Text(
                            'Nomor Antrian',
                            style: AppTypography.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Center(
                          child: ScaleTransition(
                            scale: CurvedAnimation(
                              parent: _controller,
                              curve: Curves.elasticOut,
                            ),
                            child: Text(
                              o.queueNumberFormatted,
                              style: AppTypography.heading1.copyWith(
                                fontSize: 72,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rincian',
                                    style: AppTypography.heading4),
                                const SizedBox(height: AppSpacing.sm),
                                for (final item in o.items)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Text('${item.quantity}× ',
                                            style: AppTypography.body2),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(item.menuName,
                                                  style:
                                                      AppTypography.body2),
                                              if (item.condiments.isNotEmpty)
                                                Text(
                                                  item.condimentSummary,
                                                  style: AppTypography
                                                      .caption
                                                      .copyWith(
                                                    color: AppColors
                                                        .textSecondary,
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
                                  ),
                                const Divider(),
                                _Row(
                                  label: 'Total',
                                  value: formatRupiah(o.total),
                                  bold: true,
                                ),
                                _Row(
                                  label: 'Metode',
                                  value: o.paymentMethodLabel,
                                ),
                                if (change != null) ...[
                                  _Row(
                                    label: 'Uang Diterima',
                                    value:
                                        formatRupiah(widget.cashReceived!),
                                  ),
                                  _Row(
                                    label: 'Kembalian',
                                    value: formatRupiah(change),
                                    valueColor: AppColors.accent,
                                    bold: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                BrewButton(label: 'Pesanan Baru', onPressed: _newOrder),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.body2.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: valueColor,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body2),
          Text(value, style: style),
        ],
      ),
    );
  }
}

