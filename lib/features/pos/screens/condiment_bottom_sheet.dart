import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/brew_button.dart';
import '../models/condiment_group.dart';
import '../models/condiment_option.dart';
import '../models/menu.dart';

typedef CondimentConfirmCallback = void Function(
  List<CondimentOption> selected,
  int quantity,
  String? notes,
);

class CondimentBottomSheet extends StatefulWidget {
  const CondimentBottomSheet({
    super.key,
    required this.menu,
    required this.onConfirm,
  });

  final Menu menu;
  final CondimentConfirmCallback onConfirm;

  static Future<void> show(
    BuildContext context, {
    required Menu menu,
    required CondimentConfirmCallback onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CondimentBottomSheet(menu: menu, onConfirm: onConfirm),
    );
  }

  @override
  State<CondimentBottomSheet> createState() => _CondimentBottomSheetState();
}

class _CondimentBottomSheetState extends State<CondimentBottomSheet> {
  // groupId → list of selected option ids
  final Map<int, List<int>> _selected = {};
  final Set<int> _errorGroups = {};
  int _quantity = 1;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggle(CondimentGroup group, CondimentOption option) {
    setState(() {
      _errorGroups.remove(group.id);
      final list = _selected.putIfAbsent(group.id, () => []);
      if (group.isMulti) {
        if (list.contains(option.id)) {
          list.remove(option.id);
        } else {
          list.add(option.id);
        }
      } else {
        _selected[group.id] = [option.id];
      }
    });
  }

  double get _condimentTotal {
    double sum = 0;
    for (final g in widget.menu.condimentGroups) {
      final selectedIds = _selected[g.id] ?? const <int>[];
      for (final opt in g.options) {
        if (selectedIds.contains(opt.id)) sum += opt.additionalPrice;
      }
    }
    return sum;
  }

  double get _unitTotal => widget.menu.price + _condimentTotal;
  double get _lineTotal => _unitTotal * _quantity;

  void _confirm() {
    final missing = <int>{};
    for (final g in widget.menu.condimentGroups) {
      if (g.isRequired && (_selected[g.id] ?? const <int>[]).isEmpty) {
        missing.add(g.id);
      }
    }
    if (missing.isNotEmpty) {
      setState(() => _errorGroups
        ..clear()
        ..addAll(missing));
      return;
    }

    final flat = <CondimentOption>[];
    for (final g in widget.menu.condimentGroups) {
      final ids = _selected[g.id] ?? const <int>[];
      for (final opt in g.options) {
        if (ids.contains(opt.id)) flat.add(opt);
      }
    }

    widget.onConfirm(
      flat,
      _quantity,
      _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.menu.name, style: AppTypography.heading3),
                  const SizedBox(height: 2),
                  Text(
                    'Pilih pilihan untuk pesanan ini',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                children: [
                  for (final group in widget.menu.condimentGroups)
                    _GroupSection(
                      group: group,
                      selectedIds: _selected[group.id] ?? const [],
                      hasError: _errorGroups.contains(group.id),
                      onToggle: (opt) => _toggle(group, opt),
                    ),
                  if (widget.menu.condimentGroups.isEmpty)
                    Text(
                      'Menu ini tidak memiliki pilihan tambahan.',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Catatan (opsional)', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Less ice, no sugar, dll',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            _Footer(
              quantity: _quantity,
              total: _lineTotal,
              onDec: () =>
                  setState(() => _quantity = (_quantity - 1).clamp(1, 99)),
              onInc: () =>
                  setState(() => _quantity = (_quantity + 1).clamp(1, 99)),
              onConfirm: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.selectedIds,
    required this.hasError,
    required this.onToggle,
  });

  final CondimentGroup group;
  final List<int> selectedIds;
  final bool hasError;
  final ValueChanged<CondimentOption> onToggle;

  @override
  Widget build(BuildContext context) {
    final labelColor = hasError ? AppColors.alert : AppColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 6),
          child: Row(
            children: [
              Text(
                group.name,
                style: AppTypography.heading4.copyWith(color: labelColor),
              ),
              const SizedBox(width: 8),
              if (group.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.alert.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Wajib',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.alert,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (final opt in group.options)
          _OptionRow(
            option: opt,
            isSelected: selectedIds.contains(opt.id),
            isMulti: group.isMulti,
            onTap: () => onToggle(opt),
          ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Pilihan wajib diisi',
              style: AppTypography.caption.copyWith(color: AppColors.alert),
            ),
          ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.isSelected,
    required this.isMulti,
    required this.onTap,
  });

  final CondimentOption option;
  final bool isSelected;
  final bool isMulti;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 6,
        ),
        child: Row(
          children: [
            isMulti
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    activeColor: AppColors.primary,
                  )
                : _RadioCircle(selected: isSelected),
            Expanded(
              child: Text(option.name, style: AppTypography.body2),
            ),
            if (option.additionalPrice > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '+ ${formatRupiah(option.additionalPrice)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RadioCircle extends StatelessWidget {
  const _RadioCircle({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: selected
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.quantity,
    required this.total,
    required this.onDec,
    required this.onInc,
    required this.onConfirm,
  });

  final int quantity;
  final double total;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jumlah', style: AppTypography.body2),
              Row(
                children: [
                  IconButton(
                    onPressed: quantity > 1 ? onDec : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primary,
                  ),
                  Text('$quantity', style: AppTypography.heading3),
                  IconButton(
                    onPressed: onInc,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          BrewButton(
            label: 'Tambah — ${formatRupiah(total)}',
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}
