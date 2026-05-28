import 'package:flutter/material.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderActionHelper {
  OrderActionHelper._();

  /// Returns updated [Order] on success, null on cancel/error.
  static Future<Order?> transition(
    BuildContext context, {
    required int orderId,
    required String newStatus,
  }) async {
    final isCancel = newStatus == 'cancelled';
    final title = _titleFor(newStatus);
    final msg = isCancel
        ? 'Beri alasan pembatalan (opsional).'
        : 'Lanjutkan perubahan status ke "${_labelFor(newStatus)}"?';

    String? notes;
    bool confirmed;

    if (isCancel) {
      final result = await _showCancelDialog(context, title);
      confirmed = result != null;
      notes = result;
    } else {
      confirmed = await ConfirmDialog.show(
        context,
        title: title,
        message: msg,
        confirmLabel: 'Ya',
      );
    }

    if (!confirmed || !context.mounted) return null;

    try {
      final updated = await OrderService.updateOrderStatus(
        orderId,
        newStatus,
        notes: notes,
      );
      return updated;
    } on OrderServiceException catch (e) {
      if (!context.mounted) return null;
      showErrorSnackbar(context, e.message);
      return null;
    }
  }

  static Future<String?> _showCancelDialog(
    BuildContext context,
    String title,
  ) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Alasan pembatalan',
            hintText: 'Misal: pelanggan membatalkan',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan Pesanan'),
          ),
        ],
      ),
    );
    if (ok != true) return null;
    return controller.text.trim();
  }

  static String _titleFor(String status) {
    switch (status) {
      case 'processing':
        return 'Mulai Proses';
      case 'ready':
        return 'Tandai Siap';
      case 'completed':
        return 'Konfirmasi Diambil';
      case 'cancelled':
        return 'Batalkan Pesanan';
      default:
        return 'Ubah Status';
    }
  }

  static String _labelFor(String status) {
    switch (status) {
      case 'processing':
        return 'Diproses';
      case 'ready':
        return 'Siap Diambil';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}
