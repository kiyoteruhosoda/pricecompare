import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterbase/app/di/service_locator.dart';
import 'package:flutterbase/presentation/viewmodels/compare_viewmodel.dart';
import 'package:flutterbase/shared/l10n/app_localizations.dart';
import 'package:flutterbase/shared/theme/theme.dart';
import 'package:intl/intl.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  late final CompareViewModel _vm;
  final Map<String, _RowControllers> _controllers = {};

  @override
  void initState() {
    super.initState();
    _vm = sl<CompareViewModel>();
    for (final row in _vm.rows) {
      _controllers[row.id] = _RowControllers();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  _RowControllers _controllersFor(String id) {
    return _controllers.putIfAbsent(id, () => _RowControllers());
  }

  void _removeControllers(String id) {
    _controllers.remove(id)?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        _syncControllers();
        _handleStateChange(context, l10n);
        return Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageMargin,
                AppSpacing.pageMargin,
                AppSpacing.pageMargin,
                AppSpacing.pageMargin + 64,
              ),
              itemCount: _vm.rows.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                final row = _vm.rows[index];
                final ctrl = _controllersFor(row.id);
                return _CompareRowCard(
                  row: row,
                  controllers: ctrl,
                  canDelete: _vm.rows.length > 1,
                  onDelete: () {
                    _removeControllers(row.id);
                    _vm.removeRow(row.id);
                  },
                  onNameChanged: (v) => _vm.updateProductName(row.id, v),
                  onBasePriceChanged: (v) => _vm.updateBasePrice(row.id, v),
                  onDiscountChanged: (v) =>
                      _vm.updateSaleDiscount(row.id, v ?? 0),
                  onPointsChanged: (v) => _vm.updatePoints(row.id, v ?? 0),
                  onQuantityChanged: (v) => _vm.updateQuantity(row.id, v),
                  onSave: () => _vm.saveRow(row.id),
                  onViewHistory: () => _navigateToProduct(context, row),
                );
              },
            ),
            Positioned(
              right: AppSpacing.pageMargin,
              bottom: AppSpacing.pageMargin,
              child: FloatingActionButton.extended(
                onPressed: _vm.addRow,
                icon: const Icon(Icons.add),
                label: Text(l10n.compareAddRow),
              ),
            ),
          ],
        );
      },
    );
  }

  void _syncControllers() {
    for (final row in _vm.rows) {
      _controllersFor(row.id);
    }
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

  void _navigateToProduct(BuildContext context, CompareRow row) {
    if (row.productName.trim().isEmpty) return;
    Navigator.of(context)
        .pushNamed('/product-by-name', arguments: row.productName.trim());
  }
}

// ─── Row card ────────────────────────────────────────────────────────────────

class _CompareRowCard extends StatelessWidget {
  const _CompareRowCard({
    required this.row,
    required this.controllers,
    required this.canDelete,
    required this.onDelete,
    required this.onNameChanged,
    required this.onBasePriceChanged,
    required this.onDiscountChanged,
    required this.onPointsChanged,
    required this.onQuantityChanged,
    required this.onSave,
    required this.onViewHistory,
  });

  final CompareRow row;
  final _RowControllers controllers;
  final bool canDelete;
  final VoidCallback onDelete;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<double?> onBasePriceChanged;
  final ValueChanged<double?> onDiscountChanged;
  final ValueChanged<double?> onPointsChanged;
  final ValueChanged<double?> onQuantityChanged;
  final VoidCallback onSave;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isBest = row.isBest &&
        row.unitPrice != null &&
        _hasValidInputs();

    return Card(
      color: isBest ? AppColors.statusSuccessBg : null,
      shape: isBest
          ? RoundedRectangleBorder(
              borderRadius: AppRadius.lgBorder,
              side: BorderSide(
                color: AppColors.statusSuccess,
                width: 2,
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.componentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header row ───────────────────────────────────────────
            Row(
              children: [
                if (isBest) ...[
                  Icon(
                    Icons.star,
                    color: AppColors.statusSuccess,
                    size: AppSpacing.iconLg,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    isBest ? _formatUnitPrice(row.unitPrice) : '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.statusSuccess,
                          fontWeight: FontWeight.bold,
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

            // ─── Product name ─────────────────────────────────────────
            _buildNameField(context, l10n),

            // ─── Summary hint ─────────────────────────────────────────
            if (row.summary != null) _buildSummaryHint(context, l10n),

            const SizedBox(height: AppSpacing.sm),

            // ─── Price inputs ─────────────────────────────────────────
            _buildPriceInput(
              context,
              label: l10n.compareBasePrice,
              controller: controllers.basePrice,
              onChanged: (v) => onBasePriceChanged(_parseDouble(v)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildPriceInput(
                    context,
                    label: l10n.compareSaleDiscount,
                    controller: controllers.saleDiscount,
                    onChanged: (v) => onDiscountChanged(_parseDouble(v)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildPriceInput(
                    context,
                    label: l10n.comparePoints,
                    controller: controllers.points,
                    onChanged: (v) => onPointsChanged(_parseDouble(v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildPriceInput(
              context,
              label: l10n.compareQuantity,
              controller: controllers.quantity,
              onChanged: (v) => onQuantityChanged(_parseDouble(v)),
            ),

            // ─── Computed results ─────────────────────────────────────
            if (row.effectivePrice != null || row.unitPrice != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              _buildResultRow(
                context,
                label: l10n.compareEffectivePrice,
                value: row.effectivePrice != null
                    ? _formatPrice(row.effectivePrice!)
                    : '—',
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildResultRow(
                context,
                label: l10n.compareUnitPrice,
                value: row.unitPrice != null
                    ? _formatUnitPrice(row.unitPrice)
                    : '—',
                highlight: isBest,
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // ─── Action buttons ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.history, size: AppSpacing.iconMd),
                    label: Text(l10n.compareViewHistory),
                    onPressed: row.productName.trim().isNotEmpty
                        ? onViewHistory
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save_outlined,
                        size: AppSpacing.iconMd),
                    label: Text(l10n.compareAddToHistory),
                    onPressed: onSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _hasValidInputs() =>
      row.basePrice != null && row.quantity != null && row.quantity! > 0;

  Widget _buildNameField(BuildContext context, AppLocalizations l10n) {
    return TextField(
      controller: controllers.name,
      decoration: InputDecoration(
        labelText: l10n.compareProductName,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      textInputAction: TextInputAction.next,
      onChanged: onNameChanged,
    );
  }

  Widget _buildSummaryHint(BuildContext context, AppLocalizations l10n) {
    final summary = row.summary!;
    final dateFmt = DateFormat('yyyy/MM/dd');
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.smBorder,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: AppSpacing.iconSm,
              color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '${l10n.compareHistorySummaryCount}: ${summary.historyCount}  '
              '${l10n.compareHistorySummaryMinUnitPrice}: ${_formatUnitPrice(summary.minUnitPrice)}  '
              '${l10n.compareHistorySummaryLatest}: ${dateFmt.format(summary.latestRecordedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInput(
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

  Widget _buildResultRow(
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
    final trimmed = v.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  static String _formatPrice(double price) {
    return '¥${NumberFormat('#,##0').format(price)}';
  }

  static String _formatUnitPrice(double? price) {
    if (price == null) return '—';
    return '¥${NumberFormat('#,##0.##').format(price)}';
  }
}

// ─── Controllers holder ───────────────────────────────────────────────────────

class _RowControllers {
  final name = TextEditingController();
  final basePrice = TextEditingController();
  final saleDiscount = TextEditingController();
  final points = TextEditingController();
  final quantity = TextEditingController();

  void dispose() {
    name.dispose();
    basePrice.dispose();
    saleDiscount.dispose();
    points.dispose();
    quantity.dispose();
  }
}
