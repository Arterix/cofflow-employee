import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/brew_button.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../orders/models/order.dart';
import '../../orders/services/order_service.dart';
import '../state/cart_controller.dart';

class VAPaymentScreen extends StatefulWidget {
  const VAPaymentScreen({super.key, required this.order});
  final Order order;

  @override
  State<VAPaymentScreen> createState() => _VAPaymentScreenState();
}

class _VAPaymentScreenState extends State<VAPaymentScreen> {
  Timer? _timer;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final status = await OrderService.getPaymentStatus(widget.order.id);
      if (status == 'paid' && mounted) {
        _timer?.cancel();
        CartController.instance.clear();
        context.go('/receipt', extra: {'order': widget.order});
      }
    } catch (_) {}
  }

  Future<void> _cancel() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Batalkan Pesanan',
      message: 'Pesanan akan dibatalkan.',
      confirmLabel: 'Batalkan',
      isDangerous: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await OrderService.cancelOrder(widget.order.id);
      _timer?.cancel();
      if (!mounted) return;
      context.go('/pos');
    } on OrderServiceException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, e.message);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _copyVa() async {
    final va = widget.order.vaNumber;
    if (va == null) return;
    await Clipboard.setData(ClipboardData(text: va));
    if (!mounted) return;
    showSuccessSnackbar(context, 'Nomor VA disalin');
  }

  @override
  Widget build(BuildContext context) {
    final bank = widget.order.paymentChannel?.toUpperCase() ?? 'BANK';
    final va = widget.order.vaNumber ?? '-';
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran Virtual Account'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 480,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    bank,
                    style: AppTypography.heading4.copyWith(
                      color: AppColors.onPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Nomor Virtual Account',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: _copyVa,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SelectableText(
                          va,
                          style: AppTypography.heading1.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.copy,
                            size: 20, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  formatRupiah(widget.order.total),
                  style: AppTypography.heading2,
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cara Bayar',
                          style: AppTypography.heading4,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '1. Buka m-Banking $bank\n'
                          '2. Pilih Transfer > Virtual Account\n'
                          '3. Masukkan nomor di atas\n'
                          '4. Konfirmasi total tagihan',
                          style: AppTypography.body2,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Menunggu konfirmasi pembayaran...',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                BrewButton(
                  label: 'Batalkan Pesanan',
                  onPressed: _cancelling ? null : _cancel,
                  isLoading: _cancelling,
                  outlined: true,
                  color: AppColors.alert,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
