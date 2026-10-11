import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../models/category.dart';
import '../models/menu.dart';
import '../services/menu_service.dart';
import '../state/cart_controller.dart';
import 'condiment_bottom_sheet.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final _searchController = TextEditingController();
  final _cart = CartController.instance;

  List<Menu> _allMenus = [];
  List<MenuCategory> _categories = [];
  bool _isLoading = true;
  String? _error;
  int? _activeCategoryId; // null = "Semua"
  String _query = '';

  @override
  void initState() {
    super.initState();
    _cart.addListener(_onCartChanged);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        MenuService.getMenus(),
        MenuService.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _allMenus = results[0] as List<Menu>;
        _categories = results[1] as List<MenuCategory>;
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

  List<Menu> get _filtered {
    Iterable<Menu> list = _allMenus;
    if (_activeCategoryId != null) {
      list = list.where((m) => m.category?.id == _activeCategoryId);
    }
    if (_query.isNotEmpty) {
      list = list.where((m) => m.name.toLowerCase().contains(_query));
    }
    return list.toList();
  }

  void _onMenuTap(Menu menu) {
    if (!menu.hasCondiments) {
      _cart.addItem(menu);
      showSuccessSnackbar(context, '${menu.name} ditambahkan');
      return;
    }
    CondimentBottomSheet.show(
      context,
      menu: menu,
      onConfirm: (selected, qty, notes) {
        _cart.addItem(
          menu,
          quantity: qty,
          selectedCondiments: selected,
          notes: notes,
        );
        showSuccessSnackbar(context, '${menu.name} ditambahkan');
      },
    );
  }

  int _calculateCols(double availableWidth) {
    if (availableWidth < 340) return 2;
    if (availableWidth < 520) return 3;
    if (availableWidth < 780) return 4;
    if (availableWidth < 1100) return 5;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    final isSplit = context.screenWidth >= 900;
    final catalogWidth = isSplit ? (context.screenWidth - 460) : context.screenWidth;
    final cols = _calculateCols(catalogWidth);

    final catalogContent = Column(
      children: [
        _SearchAndFilters(
          searchController: _searchController,
          categories: _categories,
          activeCategoryId: _activeCategoryId,
          onCategoryTap: (id) => setState(() => _activeCategoryId = id),
        ),
        const Divider(height: 1),
        Expanded(child: _buildGrid(cols)),
        if (!isSplit && _cart.isNotEmpty) _CartBar(cart: _cart),
      ],
    );

    if (isSplit) {
      return Row(
        children: [
          Expanded(child: catalogContent),
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
          SizedBox(
            width: 380,
            child: _InlineCartSidePanel(cart: _cart),
          ),
        ],
      );
    }

    return catalogContent;
  }

  Widget _buildGrid(int cols) {
    if (_isLoading) {
      return ShimmerGrid(crossAxisCount: cols, itemCount: cols * 3);
    }
    if (_error != null) {
      return EmptyStateWidget(
        icon: Icons.wifi_off,
        message: _error!,
        onRetry: _load,
      );
    }
    final list = _filtered;
    if (list.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off,
        message: 'Tidak ada menu yang ditemukan',
      );
    }
    final ratio = cols <= 3 ? 0.64 : 0.72;
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: ratio,
        ),
        itemCount: list.length,
        itemBuilder: (_, i) =>
            _MenuCard(menu: list[i], onTap: () => _onMenuTap(list[i])),
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.searchController,
    required this.categories,
    required this.activeCategoryId,
    required this.onCategoryTap,
  });

  final TextEditingController searchController;
  final List<MenuCategory> categories;
  final int? activeCategoryId;
  final ValueChanged<int?> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari menu...',
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Chip(
                  label: 'Semua',
                  selected: activeCategoryId == null,
                  onTap: () => onCategoryTap(null),
                ),
                for (final c in categories)
                  _Chip(
                    label: c.name,
                    selected: activeCategoryId == c.id,
                    onTap: () => onCategoryTap(c.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.label.copyWith(
          color: selected ? AppColors.onPrimary : AppColors.textPrimary,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.divider,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.menu, required this.onTap});

  final Menu menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image: flex 5. Text block: flex 4. Total share = whole cell,
            // so nothing can overflow regardless of cell aspect ratio.
            Expanded(
              flex: 5,
              child: menu.imageUrl != null && menu.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: menu.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: AppColors.divider,
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.divider,
                        child: const Icon(Icons.local_cafe,
                            color: AppColors.textSecondary),
                      ),
                    )
                  : Container(
                      color: AppColors.divider,
                      child: const Icon(Icons.local_cafe,
                          color: AppColors.textSecondary, size: 36),
                    ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        menu.name,
                        style: AppTypography.heading4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatRupiah(menu.price),
                          style: AppTypography.body2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.cart});
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () => context.push('/cart'),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.onPrimary,
                  child: Text(
                    '${cart.itemCount}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lihat keranjang',
                        style: AppTypography.label.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        formatRupiah(cart.total),
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                BrewButton(
                  label: 'Bayar',
                  onPressed: () => context.push('/cart'),
                  color: AppColors.accent,
                  foregroundColor: AppColors.primary,
                  isFullWidth: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineCartSidePanel extends StatelessWidget {
  const _InlineCartSidePanel({required this.cart});
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    final items = cart.items;
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text('Pesanan Saat Ini', style: AppTypography.heading4),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (items.isNotEmpty)
                  TextButton(
                    onPressed: () => cart.clear(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.alert,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 48,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Belum ada item dipilih',
                            style: AppTypography.body2
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sentuh menu untuk menambahkan ke pesanan',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.menu.name,
                                    style: AppTypography.body1.copyWith(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if (it.selectedCondiments.isNotEmpty)
                                    Text(
                                      it.condimentSummary,
                                      style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary),
                                    ),
                                  if (it.notes != null && it.notes!.isNotEmpty)
                                    Text(
                                      'Catatan: ${it.notes}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatRupiah(it.subtotal),
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 20),
                                  color: AppColors.textSecondary,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => cart.decrementAt(i),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text('${it.quantity}',
                                      style: AppTypography.heading4),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 20),
                                  color: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => cart.incrementAt(i),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                      Text('Total Pembayaran', style: AppTypography.body2),
                      Text(
                        formatRupiah(cart.total),
                        style: AppTypography.heading3
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BrewButton(
                    label: 'Proses Pembayaran',
                    onPressed: () => context.push('/cart'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
