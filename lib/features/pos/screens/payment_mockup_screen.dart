import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/brew_button.dart';
import '../state/cart_controller.dart';

/// Visual mockup of the payment flow. Does NOT call the backend.
/// Use for design review / demo. Real flow lives in ConfirmPaymentScreen.
class PaymentMockupScreen extends StatefulWidget {
  const PaymentMockupScreen({super.key});

  @override
  State<PaymentMockupScreen> createState() => _PaymentMockupScreenState();
}

enum _MockMethod { cash, qris, virtualAccount }

class _PaymentMockupScreenState extends State<PaymentMockupScreen> {
  final _cart = CartController.instance;
  _MockMethod _method = _MockMethod.cash;
  bool _processing = false;

  Future<void> _pay() async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final methodLabel = switch (_method) {
      _MockMethod.cash => 'Cash',
      _MockMethod.qris => 'QRIS',
      _MockMethod.virtualAccount => 'Virtual Account',
    };

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle,
            color: AppColors.accent, size: 56),
        title: const Text('Pembayaran Berhasil'),
        content: Text(
          'Mockup transaksi $methodLabel sebesar '
          '${formatRupiah(_cart.total)} telah dicatat.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    _cart.clear();
    showSuccessSnackbar(context, 'Cart dibersihkan');
    context.go('/pos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran (Mockup)')),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 720,
          child: Column(
            children: [
              const _MockupBanner(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _TotalCard(total: _cart.total, itemCount: _cart.itemCount),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Metode Pembayaran', style: AppTypography.heading4),
                    const SizedBox(height: AppSpacing.sm),
                    _MethodTile(
                      method: _MockMethod.cash,
                      icon: Icons.payments_outlined,
                      label: 'Cash',
                      subtitle: 'Bayar di kasir, hitung kembalian manual',
                      selected: _method == _MockMethod.cash,
                      onTap: () => setState(() => _method = _MockMethod.cash),
                    ),
                    _MethodTile(
                      method: _MockMethod.qris,
                      icon: Icons.qr_code_2,
                      label: 'QRIS',
                      subtitle: 'Scan QR via mobile banking / e-wallet',
                      selected: _method == _MockMethod.qris,
                      onTap: () => setState(() => _method = _MockMethod.qris),
                    ),
                    _MethodTile(
                      method: _MockMethod.virtualAccount,
                      icon: Icons.account_balance,
                      label: 'Virtual Account',
                      subtitle: 'Transfer ke nomor VA per bank',
                      selected: _method == _MockMethod.virtualAccount,
                      onTap: () =>
                          setState(() => _method = _MockMethod.virtualAccount),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: BrewButton(
                  label: 'Bayar Sekarang',
                  isLoading: _processing,
                  onPressed: _cart.isEmpty ? null : _pay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockupBanner extends StatelessWidget {
  const _MockupBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.accent.withValues(alpha: 0.18),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Halaman mockup — tidak memanggil backend.',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.itemCount});
  final double total;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Tagihan',
            style: AppTypography.label.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(total),
            style: AppTypography.heading1.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$itemCount item dalam keranjang',
            style: AppTypography.caption.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final _MockMethod method;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTypography.heading4),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
