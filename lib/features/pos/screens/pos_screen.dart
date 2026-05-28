import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchAndFilters(
          searchController: _searchController,
          categories: _categories,
          activeCategoryId: _activeCategoryId,
          onCategoryTap: (id) => setState(() => _activeCategoryId = id),
        ),
        const Divider(height: 1),
        Expanded(child: _buildGrid()),
        if (_cart.isNotEmpty) _CartBar(cart: _cart),
      ],
    );
  }

  Widget _buildGrid() {
    if (_isLoading) {
      return const ShimmerGrid(crossAxisCount: 3, itemCount: 9);
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
    // Fixed aspect ratio = no LayoutBuilder → no relayout-boundary assert.
    // 0.62 fits image(flex 5) + text(flex 4) safely on phones 320-430dp.
    // Expanded flex split inside _MenuCard absorbs any leftover space, so
    // overflow is impossible regardless of grid cell height.
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.62,
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
