import 'package:flutter/material.dart';
import 'package:flutterbase/app/di/service_locator.dart';
import 'package:flutterbase/domain/entities/product.dart';
import 'package:flutterbase/domain/entities/product_history.dart';
import 'package:flutterbase/presentation/viewmodels/product_detail_viewmodel.dart';
import 'package:flutterbase/shared/l10n/app_localizations.dart';
import 'package:flutterbase/shared/theme/theme.dart';
import 'package:intl/intl.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductDetailViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = sl<ProductDetailViewModel>();
    _vm.load(widget.product);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => _buildBody(context, l10n),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    return switch (_vm.state) {
      ProductDetailState.loading => const Center(
          child: CircularProgressIndicator(),
        ),
      ProductDetailState.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.commonError),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => _vm.load(widget.product),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      ProductDetailState.empty => Column(
          children: [
            _buildSummaryHeader(context, l10n),
            Expanded(
              child: Center(
                child: Text(
                  l10n.productDetailHistoryEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ],
        ),
      ProductDetailState.loaded => Column(
          children: [
            _buildSummaryHeader(context, l10n),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _vm.load(widget.product),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageMargin,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: _vm.histories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final h = _vm.histories[index];
                    return _HistoryTile(
                      history: h,
                      onTap: () => Navigator.of(context)
                          .pushNamed('/history-detail', arguments: h)
                          .then((_) => _vm.load(widget.product)),
                      onDelete: () =>
                          _confirmDeleteHistory(context, l10n, h),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
    };
  }

  Widget _buildSummaryHeader(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageMargin,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: l10n.productDetailHistoryCountLabel,
            value: '${_vm.histories.length}${l10n.productDetailHistoryCount}',
          ),
          const SizedBox(width: AppSpacing.xl),
          if (_vm.minUnitPrice != null)
            _SummaryItem(
              label: l10n.productDetailMinUnitPrice,
              value:
                  '¥${NumberFormat('#,##0.##').format(_vm.minUnitPrice)}',
              highlight: true,
            ),
          const SizedBox(width: AppSpacing.xl),
          if (_vm.latestUnitPrice != null)
            _SummaryItem(
              label: l10n.productDetailLatestUnitPrice,
              value:
                  '¥${NumberFormat('#,##0.##').format(_vm.latestUnitPrice)}',
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteHistory(
    BuildContext context,
    AppLocalizations l10n,
    ProductHistory h,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.productDetailDeleteHistoryConfirmTitle),
        content: Text(l10n.productDetailDeleteHistoryConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.commonDelete,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _vm.deleteHistory(h.id);
    }
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: highlight ? AppColors.statusSuccess : null,
                fontWeight:
                    highlight ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.history,
    required this.onTap,
    required this.onDelete,
  });

  final ProductHistory history;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('yyyy/MM/dd HH:mm');

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
                      dateFmt.format(history.recordedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '¥${NumberFormat('#,##0.##').format(history.unitPrice)}',
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${l10n.historyDetailBasePrice}: ¥${NumberFormat('#,##0').format(history.basePrice)}'
                      '  ×${NumberFormat('#,##0.##').format(history.quantity)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
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
