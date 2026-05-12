import 'package:flutter/material.dart';
import 'package:pricecompare/app/di/service_locator.dart';
import 'package:pricecompare/presentation/viewmodels/product_list_viewmodel.dart';
import 'package:pricecompare/shared/l10n/app_localizations.dart';
import 'package:pricecompare/shared/theme/theme.dart';
import 'package:intl/intl.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late final ProductListViewModel _vm;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = sl<ProductListViewModel>();
    _vm.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageMargin,
            AppSpacing.sm,
            AppSpacing.pageMargin,
            AppSpacing.xs,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.productsSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _vm.search('');
                      },
                    )
                  : null,
            ),
            onChanged: _vm.search,
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _vm,
            builder: (context, _) => _buildBody(context, l10n),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    return switch (_vm.state) {
      ProductListState.loading => const Center(
          child: CircularProgressIndicator(),
        ),
      ProductListState.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.commonError),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: _vm.load, child: Text(l10n.commonRetry)),
            ],
          ),
        ),
      ProductListState.empty => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Text(
              l10n.productsEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      ProductListState.loaded => RefreshIndicator(
          onRefresh: _vm.load,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageMargin,
              vertical: AppSpacing.sm,
            ),
            itemCount: _vm.items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = _vm.items[index];
              return _ProductListTile(
                item: item,
                onTap: () => Navigator.of(context).pushNamed(
                  '/product-detail',
                  arguments: item.product,
                ).then((_) => _vm.load()),
                onDelete: () => _confirmDelete(context, l10n, item),
              );
            },
          ),
        ),
    };
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
    ProductListItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.productsDeleteConfirmTitle),
        content: Text(l10n.productsDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.commonDelete,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _vm.deleteProduct(item.product.id);
    }
  }
}

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final ProductListItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('yyyy/MM/dd');
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.componentPadding,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.lg,
                      children: [
                        _InfoChip(
                          label:
                              '${item.historyCount}${l10n.productsHistoryCount}',
                          icon: Icons.history,
                        ),
                        if (item.minUnitPrice != null)
                          _InfoChip(
                            label:
                                '${l10n.productsMinUnitPrice}: ¥${NumberFormat('#,##0.##').format(item.minUnitPrice)}',
                            icon: Icons.sell_outlined,
                          ),
                        if (item.latestRecordedAt != null)
                          _InfoChip(
                            label:
                                '${l10n.productsLatestDate}: ${dateFmt.format(item.latestRecordedAt!)}',
                            icon: Icons.calendar_today_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                ),
                onPressed: onDelete,
                tooltip: l10n.commonDelete,
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSpacing.iconSm, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
