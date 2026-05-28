import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_typography.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  static const Map<String, String> _labels = {
    'pending': 'Menunggu',
    'processing': 'Diproses',
    'ready': 'Siap',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
  };

  Color _color() {
    switch (status) {
      case 'pending':
        return AppColors.alert;
      case 'processing':
        return AppColors.primary;
      case 'ready':
        return AppColors.accent;
      case 'completed':
        return AppColors.grey;
      case 'cancelled':
        return AppColors.alert;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    final label = _labels[status] ?? status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: c,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
