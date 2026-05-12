import 'package:flutter/material.dart';
import 'package:pricecompare/app/di/service_locator.dart';
import 'package:pricecompare/domain/entities/product_history.dart';
import 'package:pricecompare/presentation/viewmodels/history_detail_viewmodel.dart';
import 'package:pricecompare/shared/l10n/app_localizations.dart';
import 'package:pricecompare/shared/theme/theme.dart';
import 'package:intl/intl.dart';

class HistoryDetailPage extends StatefulWidget {
  const HistoryDetailPage({super.key, required this.history});

  final ProductHistory history;

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  late final HistoryDetailViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = sl<HistoryDetailViewModel>();
    _vm.load(widget.history.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyDetailTitle),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: l10n.commonDelete,
            onPressed: () => _confirmDelete(context, l10n),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.state == HistoryDetailState.deleted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.historyDetailDeleteSuccess)),
                );
                Navigator.of(context).pop();
              }
            });
          }
          return _buildBody(context, l10n);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    return switch (_vm.state) {
      HistoryDetailState.loading => const Center(
          child: CircularProgressIndicator(),
        ),
      HistoryDetailState.error => Center(
          child: Text(l10n.commonError),
        ),
      HistoryDetailState.deleted => const SizedBox.shrink(),
      HistoryDetailState.loaded => _buildDetail(
          context, l10n, _vm.history!),
    };
  }

  Widget _buildDetail(
    BuildContext context,
    AppLocalizations l10n,
    ProductHistory h,
  ) {
    final dateFmt = DateFormat('yyyy/MM/dd HH:mm');
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.componentPadding),
            child: Column(
              children: [
                if (h.storeName != null) ...[
                  _DetailRow(
                    label: l10n.historyDetailStoreName,
                    value: h.storeName!,
                  ),
                  const Divider(height: 1),
                ],
                _DetailRow(
                  label: l10n.historyDetailBasePrice,
                  value: '¥${NumberFormat('#,##0').format(h.basePrice)}',
                ),
                const Divider(height: 1),
                _DetailRow(
                  label: l10n.historyDetailSaleDiscount,
                  value: '¥${NumberFormat('#,##0').format(h.saleDiscount)}',
                ),
                const Divider(height: 1),
                _DetailRow(
                  label: l10n.historyDetailPoints,
                  value: '¥${NumberFormat('#,##0').format(h.points)}',
                ),
                const Divider(height: 1),
                _DetailRow(
                  label: l10n.historyDetailQuantity,
                  value: NumberFormat('#,##0.##').format(h.quantity),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.componentPadding),
            child: Column(
              children: [
                _DetailRow(
                  label: l10n.historyDetailEffectivePrice,
                  value:
                      '¥${NumberFormat('#,##0').format(h.effectivePrice)}',
                ),
                const Divider(height: 1),
                _DetailRow(
                  label: l10n.historyDetailUnitPrice,
                  value:
                      '¥${NumberFormat('#,##0.##').format(h.unitPrice)}',
                  valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.statusSuccess,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.componentPadding),
            child: Column(
              children: [
                _DetailRow(
                  label: l10n.historyDetailRecordedAt,
                  value: dateFmt.format(h.recordedAt),
                ),
                if (h.memo != null) ...[
                  const Divider(height: 1),
                  _DetailRow(
                    label: l10n.historyDetailMemo,
                    value: h.memo!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.historyDetailDeleteConfirmTitle),
        content: Text(l10n.historyDetailDeleteConfirmBody),
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
      await _vm.delete();
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: valueStyle ?? Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
