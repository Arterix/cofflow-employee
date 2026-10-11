import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
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

class QRISPaymentScreen extends StatefulWidget {
  const QRISPaymentScreen({super.key, required this.order});
  final Order order;

  @override
  State<QRISPaymentScreen> createState() => _QRISPaymentScreenState();
}

class _QRISPaymentScreenState extends State<QRISPaymentScreen> {
  Timer? _timer;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
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
    } catch (_) {
      // swallow; will retry on next tick
    }
  }

  Future<void> _cancel() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Batalkan Pesanan',
      message: 'Pesanan akan dibatalkan dan stok dikembalikan.',
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran QRIS'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 480,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Scan QR Code berikut', style: AppTypography.heading3),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.order.qrCodeUrl != null
                      ? Image.network(
                          widget.order.qrCodeUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.qr_code_2,
                            size: 120,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : const Icon(
                          Icons.qr_code_2,
                          size: 120,
                          color: AppColors.textSecondary,
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  formatRupiah(widget.order.total),
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
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
                      'Menunggu pembayaran...',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
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
