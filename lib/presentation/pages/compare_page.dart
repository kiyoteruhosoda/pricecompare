import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pricecompare/app/bootstrap/app_router.dart';
import 'package:pricecompare/app/di/service_locator.dart';
import 'package:pricecompare/application/dto/product_summary_dto.dart';
import 'package:pricecompare/presentation/viewmodels/compare_viewmodel.dart';
import 'package:pricecompare/shared/l10n/app_localizations.dart';
import 'package:pricecompare/shared/theme/theme.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  late final CompareViewModel _vm;
  final TextEditingController _productNameCtrl = TextEditingController();
  final Map<String, _RowControllers> _rowCtrlMap = {};

  @override
  void initState() {
    super.initState();
    _vm = sl<CompareViewModel>();
    _productNameCtrl.text = _vm.productName;
    for (final row in _vm.rows) {
      _rowCtrlMap[row.id] = _RowControllers.fromRow(row);
    }
  }

  @override
  void dispose() {
    _productNameCtrl.dispose();
    for (final c in _rowCtrlMap.values) {
      c.dispose();
    }
    super.dispose();
  }

  _RowControllers _ctrlFor(String id) =>
      _rowCtrlMap.putIfAbsent(id, () => _RowControllers());

  void _removeCtrl(String id) => _rowCtrlMap.remove(id)?.dispose();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        _handleStateChange(context, l10n);
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageMargin,
                AppSpacing.pageMargin,
                AppSpacing.pageMargin,
                AppSpacing.pageMargin + 88,
              ),
              children: [
                // ── 商品名 ───────────────────────────────────────────
                TextField(
                  controller: _productNameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.compareProductName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.shopping_basket_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: _vm.updateProductName,
                ),

                // ── 履歴サマリ ────────────────────────────────────────
                if (_vm.summary != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _HistorySummaryCard(
                    summary: _vm.summary!,
                    productName: _vm.productName,
                    bestRows: _vm.rows
                        .where((r) => r.isBest && r.unitPrice != null)
                        .toList(),
                    l10n: l10n,
                    onViewHistory: () => Navigator.of(context).pushNamed(
                      AppRouter.productByName,
                      arguments: _vm.productName.trim(),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // ── 各店舗行 ─────────────────────────────────────────
                ..._vm.rows.map((row) {
                  final ctrl = _ctrlFor(row.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _StoreRowCard(
                      row: row,
                      controllers: ctrl,
                      canDelete: _vm.rows.length > 1,
                      onDelete: () {
                        _removeCtrl(row.id);
                        _vm.removeRow(row.id);
                      },
                      onStoreNameChanged: (v) =>
                          _vm.updateStoreName(row.id, v),
                      onBasePriceChanged: (v) =>
                          _vm.updateBasePrice(row.id, v),
                      onDiscountChanged: (v) =>
                          _vm.updateSaleDiscount(row.id, v ?? 0),
                      onPointsChanged: (v) =>
                          _vm.updatePoints(row.id, v ?? 0),
                      onQuantityChanged: (v) =>
                          _vm.updateQuantity(row.id, v),
                      l10n: l10n,
                    ),
                  );
                }),
              ],
            ),

            // ── FAB群 ─────────────────────────────────────────────────
            Positioned(
              right: AppSpacing.pageMargin,
              bottom: AppSpacing.pageMargin,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'save',
                    onPressed: _vm.state == CompareState.saving
                        ? null
                        : _vm.saveAll,
                    icon: _vm.state == CompareState.saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(l10n.compareSave),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FloatingActionButton.extended(
                    heroTag: 'add',
                    onPressed: _vm.addRow,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.compareAddRow),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleStateChange(BuildContext context, AppLocalizations l10n) {
    final state = _vm.state;
    if (state == CompareState.saved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.compareSaveSuccess)),
          );
          _vm.clearState();
        }
      });
    } else if (state == CompareState.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final msg = switch (_vm.errorMessage) {
            'name_required' => l10n.compareSaveErrorNameRequired,
            'base_price_required' => l10n.compareBasePriceRequired,
            'quantity_required' => l10n.compareQuantityRequired,
            _ => l10n.commonError,
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          _vm.clearState();
        }
      });
    }
  }
}

// ─── 履歴サマリカード ──────────────────────────────────────────────────────────

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({
    required this.summary,
    required this.productName,
    required this.bestRows,
    required this.l10n,
    required this.onViewHistory,
  });

  final ProductSummaryDto summary;
  final String productName;
  final List<CompareRow> bestRows;
  final AppLocalizations l10n;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('yyyy/MM/dd');
    final priceFmt = NumberFormat('#,##0.##');

    // Best current row (lowest unit price in current input).
    final currentBestUnitPrice =
        bestRows.isNotEmpty ? bestRows.first.unitPrice : null;

    // Is current best price lower than historical best?
    final isCheaperThanHistory = currentBestUnitPrice != null &&
        currentBestUnitPrice < summary.minUnitPrice;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── サマリ情報 ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 件数 / 最新記録
                Row(
                  children: [
                    Icon(Icons.history,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${l10n.compareHistorySummaryCount} ${summary.historyCount}件  '
                      '${l10n.compareHistorySummaryLatest}: ${dateFmt.format(summary.latestRecordedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // 最安単価
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${l10n.compareHistorySummaryMinUnitPrice}: ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      '¥${priceFmt.format(summary.minUnitPrice)}/個',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),

                // 現在の入力との比較
                if (currentBestUnitPrice != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _PriceComparisonChip(
                    currentPrice: currentBestUnitPrice,
                    historicalBest: summary.minUnitPrice,
                    isCheaper: isCheaperThanHistory,
                    priceFmt: priceFmt,
                    context: context,
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // ── 履歴を見るボタン ───────────────────────────────────────
          TextButton.icon(
            onPressed: onViewHistory,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(l10n.compareViewHistory),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              alignment: Alignment.centerLeft,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 現在価格 vs 過去最安の比較チップ ─────────────────────────────────────────

class _PriceComparisonChip extends StatelessWidget {
  const _PriceComparisonChip({
    required this.currentPrice,
    required this.historicalBest,
    required this.isCheaper,
    required this.priceFmt,
    required this.context,
  });

  final double currentPrice;
  final double historicalBest;
  final bool isCheaper;
  final NumberFormat priceFmt;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final diff = (currentPrice - historicalBest).abs();
    final color =
        isCheaper ? AppColors.statusSuccess : AppColors.statusWarning;
    final bgColor =
        isCheaper ? AppColors.statusSuccessBg : AppColors.statusWarningBg;
    final icon = isCheaper ? Icons.arrow_downward : Icons.arrow_upward;
    final label = isCheaper
        ? '過去最安より ¥${priceFmt.format(diff)}/個 安い'
        : '過去最安より ¥${priceFmt.format(diff)}/個 高い';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.smBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── 店舗行カード ──────────────────────────────────────────────────────────────

class _StoreRowCard extends StatelessWidget {
  const _StoreRowCard({
    required this.row,
    required this.controllers,
    required this.canDelete,
    required this.onDelete,
    required this.onStoreNameChanged,
    required this.onBasePriceChanged,
    required this.onDiscountChanged,
    required this.onPointsChanged,
    required this.onQuantityChanged,
    required this.l10n,
  });

  final CompareRow row;
  final _RowControllers controllers;
  final bool canDelete;
  final VoidCallback onDelete;
  final ValueChanged<String> onStoreNameChanged;
  final ValueChanged<double?> onBasePriceChanged;
  final ValueChanged<double?> onDiscountChanged;
  final ValueChanged<double?> onPointsChanged;
  final ValueChanged<double?> onQuantityChanged;
  final AppLocalizations l10n;

  bool get _hasResult =>
      row.basePrice != null && row.quantity != null && row.quantity! > 0;

  @override
  Widget build(BuildContext context) {
    final isBest = row.isBest && _hasResult;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isBest ? AppColors.statusSuccessBg : null,
      shape: isBest
          ? RoundedRectangleBorder(
              borderRadius: AppRadius.lgBorder,
              side: BorderSide(color: AppColors.statusSuccess, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.componentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── ヘッダー行 ─────────────────────────────────────────
            Row(
              children: [
                if (isBest) ...[
                  Icon(Icons.star, color: AppColors.statusSuccess, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    isBest
                        ? '${_formatUnitPrice(row.unitPrice)}  最安値'
                        : (_hasResult ? _formatUnitPrice(row.unitPrice) : ''),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isBest
                              ? AppColors.statusSuccess
                              : colorScheme.onSurfaceVariant,
                          fontWeight:
                              isBest ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.compareDeleteRow,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTapTarget,
                      minHeight: AppSpacing.minTapTarget,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── 店舗名 ─────────────────────────────────────────────
            TextField(
              controller: controllers.storeName,
              decoration: InputDecoration(
                labelText: l10n.compareStoreName,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
              onChanged: onStoreNameChanged,
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── 販売価格 ───────────────────────────────────────────
            _numField(
              context,
              label: l10n.compareBasePrice,
              controller: controllers.basePrice,
              onChanged: (v) => onBasePriceChanged(_parseDouble(v)),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── セール値引き / ポイント ────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _numField(
                    context,
                    label: l10n.compareSaleDiscount,
                    controller: controllers.saleDiscount,
                    onChanged: (v) => onDiscountChanged(_parseDouble(v)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _numField(
                    context,
                    label: l10n.comparePoints,
                    controller: controllers.points,
                    onChanged: (v) => onPointsChanged(_parseDouble(v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── 数量 ───────────────────────────────────────────────
            _numField(
              context,
              label: l10n.compareQuantity,
              controller: controllers.quantity,
              onChanged: (v) => onQuantityChanged(_parseDouble(v)),
            ),

            // ── 計算結果 ───────────────────────────────────────────
            if (_hasResult) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              _resultRow(
                context,
                label: l10n.compareEffectivePrice,
                value: row.effectivePrice != null
                    ? _formatPrice(row.effectivePrice!)
                    : '—',
              ),
              const SizedBox(height: AppSpacing.xs),
              _resultRow(
                context,
                label: l10n.compareUnitPrice,
                value: _formatUnitPrice(row.unitPrice),
                highlight: isBest,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _numField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
    );
  }

  Widget _resultRow(
    BuildContext context, {
    required String label,
    required String value,
    bool highlight = false,
  }) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final valueStyle = highlight
        ? style?.copyWith(
            color: AppColors.statusSuccess,
            fontWeight: FontWeight.bold,
          )
        : style;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: valueStyle),
      ],
    );
  }

  static double? _parseDouble(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  static String _formatPrice(double price) =>
      '¥${NumberFormat('#,##0').format(price)}';

  static String _formatUnitPrice(double? price) {
    if (price == null) return '—';
    return '¥${NumberFormat('#,##0.##').format(price)}/個';
  }
}

// ─── コントローラーホルダー ────────────────────────────────────────────────────

class _RowControllers {
  _RowControllers()
      : storeName = TextEditingController(),
        basePrice = TextEditingController(),
        saleDiscount = TextEditingController(),
        points = TextEditingController(),
        quantity = TextEditingController();

  factory _RowControllers.fromRow(CompareRow row) {
    return _RowControllers()
      ..storeName.text = row.storeName
      ..basePrice.text = _fmt(row.basePrice)
      ..saleDiscount.text = row.saleDiscount == 0 ? '' : _fmt(row.saleDiscount)
      ..points.text = row.points == 0 ? '' : _fmt(row.points)
      ..quantity.text = _fmt(row.quantity);
  }

  final TextEditingController storeName;
  final TextEditingController basePrice;
  final TextEditingController saleDiscount;
  final TextEditingController points;
  final TextEditingController quantity;

  static String _fmt(double? v) {
    if (v == null) return '';
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
  }

  void dispose() {
    storeName.dispose();
    basePrice.dispose();
    saleDiscount.dispose();
    points.dispose();
    quantity.dispose();
  }
}
