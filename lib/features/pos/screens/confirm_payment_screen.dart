import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/brew_button.dart';
import '../../../shared/widgets/brew_text_field.dart';
import '../../orders/services/order_service.dart';
import '../state/cart_controller.dart';

enum _PaymentMethod { cash, qris, virtualAccount }

extension on _PaymentMethod {
  String get apiValue {
    switch (this) {
      case _PaymentMethod.cash:
        return 'cash';
      case _PaymentMethod.qris:
        return 'qris';
      case _PaymentMethod.virtualAccount:
        return 'virtual_account';
    }
  }

}

const _vaBanks = ['bca', 'bni', 'bri', 'mandiri'];

class ConfirmPaymentScreen extends StatefulWidget {
  const ConfirmPaymentScreen({super.key});

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  final _cart = CartController.instance;
  final _cashController = TextEditingController();

  _PaymentMethod _method = _PaymentMethod.cash;
  String _vaBank = 'bca';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  double get _total => _cart.total;
  double get _cashReceived =>
      double.tryParse(_cashController.text.replaceAll('.', '')) ?? 0;
  double get _change => _cashReceived - _total;

  bool get _canSubmit {
    if (_submitting || _cart.isEmpty) return false;
    if (_method == _PaymentMethod.cash && _change < 0) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final order = await OrderService.createWalkInOrder(
        items: _cart.items,
        paymentMethod: _method.apiValue,
        paymentChannel:
            _method == _PaymentMethod.virtualAccount ? _vaBank : null,
      );
      if (!mounted) return;

      switch (_method) {
        case _PaymentMethod.cash:
          context.go('/receipt', extra: {
            'order': order,
            'cash_received': _cashReceived,
          });
          _cart.clear();
        case _PaymentMethod.qris:
          context.go('/qris-payment', extra: order);
        case _PaymentMethod.virtualAccount:
          context.go('/va-payment', extra: order);
      }
    } on OrderServiceException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      if (e.statusCode == 422) {
        _showStockErrorDialog(e.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memproses pembayaran: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showStockErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Stok Tidak Cukup'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/pos');
            },
            child: const Text('Kembali ke Menu Kasir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pembayaran')),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 720,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _SummaryCard(cart: _cart),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Metode Pembayaran',
                        style: AppTypography.heading4),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<_PaymentMethod>(
                      segments: const [
                        ButtonSegment(
                          value: _PaymentMethod.cash,
                          label: Text('Cash'),
                          icon: Icon(Icons.payments_outlined),
                        ),
                        ButtonSegment(
                          value: _PaymentMethod.qris,
                          label: Text('QRIS'),
                          icon: Icon(Icons.qr_code),
                        ),
                        ButtonSegment(
                          value: _PaymentMethod.virtualAccount,
                          label: Text('VA'),
                          icon: Icon(Icons.account_balance),
                        ),
                      ],
                      selected: {_method},
                      onSelectionChanged: (s) {
                        setState(() => _method = s.first);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_method == _PaymentMethod.cash) _buildCashSection(),
                    if (_method == _PaymentMethod.virtualAccount)
                      _buildVASection(),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.alert.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          _error!,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.alert,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _FooterBar(
                total: _total,
                onConfirm: _canSubmit ? _submit : null,
                isLoading: _submitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrewTextField(
          controller: _cashController,
          label: 'Uang Diterima',
          hint: '50000',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefixIcon: Icons.payments_outlined,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChangeRow(change: _change),
      ],
    );
  }

  Widget _buildVASection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Bank', style: AppTypography.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _vaBank,
          items: [
            for (final b in _vaBanks)
              DropdownMenuItem(value: b, child: Text(b.toUpperCase())),
          ],
          onChanged: (v) => setState(() => _vaBank = v ?? 'bca'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.cart});
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan Pesanan', style: AppTypography.heading4),
            const SizedBox(height: AppSpacing.sm),
            for (final item in cart.items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.quantity}× ', style: AppTypography.body2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.menu.name, style: AppTypography.body2),
                        if (item.selectedCondiments.isNotEmpty)
                          Text(
                            item.condimentSummary,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    formatRupiah(item.subtotal),
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTypography.heading4),
                Text(
                  formatRupiah(cart.total),
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change});
  final double change;

  @override
  Widget build(BuildContext context) {
    final negative = change < 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: (negative ? AppColors.alert : AppColors.accent)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Kembalian', style: AppTypography.body2),
          Text(
            formatRupiah(change),
            style: AppTypography.heading4.copyWith(
              color: negative ? AppColors.alert : AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.total,
    required this.onConfirm,
    required this.isLoading,
  });

  final double total;
  final VoidCallback? onConfirm;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  formatRupiah(total),
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BrewButton(
              label: 'Konfirmasi Bayar',
              onPressed: onConfirm,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
