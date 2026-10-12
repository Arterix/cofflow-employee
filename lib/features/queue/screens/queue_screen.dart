import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../orders/models/order.dart';
import '../services/queue_service.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  List<Order> _queue = [];
  QueueEstimate? _estimate;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
      final results = await Future.wait([
        QueueService.getActiveQueue(),
        QueueService.getEstimate(),
      ]);
      if (!mounted) return;
      setState(() {
        _queue = results[0] as List<Order>;
        _estimate = results[1] as QueueEstimate;
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveContentContainer(
      maxWidth: 800,
      child: Column(
        children: [
          if (_estimate != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: AppColors.surface,
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Estimasi tunggu: ~${_estimate!.minutes} menit',
                    style: AppTypography.body2,
                  ),
                  const Spacer(),
                  Text(
                    '${_estimate!.activeCount} aktif',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerList(itemCount: 5, itemHeight: 88);
    }
    if (_error != null) {
      return EmptyStateWidget(
        icon: Icons.wifi_off,
        message: _error!,
        onRetry: _load,
      );
    }
    if (_queue.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.format_list_numbered,
        message: 'Belum ada antrian aktif hari ini',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _queue.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) => _QueueCard(order: _queue[i]),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final isReady = order.status == 'ready';
    final double numberSize = context.isMobile
        ? 28
        : context.isTablet
            ? 34
            : 40;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isReady
            ? Border.all(color: AppColors.accent, width: 2)
            : Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Width follows the number; FittedBox shrinks long numbers
          // instead of letting them overflow onto the customer name.
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: numberSize * 2,
              maxWidth: numberSize * 3.2,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                order.queueNumberFormatted,
                maxLines: 1,
                softWrap: false,
                style: AppTypography.heading1.copyWith(
                  fontSize: numberSize,
                  height: 1.1,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName ?? '—',
                  style: AppTypography.body2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${order.items.length} item',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(status: order.status),
        ],
      ),
    );
  }
}
