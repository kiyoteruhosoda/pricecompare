import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pricecompare/app/di/service_locator.dart';
import 'package:pricecompare/presentation/viewmodels/compare_viewmodel.dart';
import 'package:pricecompare/shared/l10n/app_localizations.dart';
import 'package:pricecompare/shared/theme/theme.dart';
import 'package:intl/intl.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  late final CompareViewModel _vm;
  final List<_SlotControllers> _slotControllers = [];

  @override
  void initState() {
    super.initState();
    _vm = sl<CompareViewModel>();
    // Ensure exactly 2 rows exist.
    while (_vm.rows.length < 2) {
      _vm.addRow();
    }
    for (final row in _vm.rows.take(2)) {
      _slotControllers.add(_SlotControllers.fromRow(row));
    }
  }

  @override
  void dispose() {
    for (final c in _slotControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        _handleStateChange(context, l10n);
        final rows = _vm.rows.take(2).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Slot A ──────────────────────────────────────────────
              if (rows.isNotEmpty)
                _SlotCard(
                  label: 'A',
                  row: rows[0],
                  controllers: _slotControllers[0],
                  onBasePriceChanged: (v) =>
                      _vm.updateBasePrice(rows[0].id, v),
                  onDiscountChanged: (v) =>
                      _vm.updateSaleDiscount(rows[0].id, v ?? 0),
                  onPointsChanged: (v) =>
                      _vm.updatePoints(rows[0].id, v ?? 0),
                  onQuantityChanged: (v) =>
                      _vm.updateQuantity(rows[0].id, v),
                  onNameChanged: (v) =>
                      _vm.updateProductName(rows[0].id, v),
                  onSave: () => _vm.saveRow(rows[0].id),
                ),

              const SizedBox(height: AppSpacing.md),

              // ── vs divider ──────────────────────────────────────────
              if (rows.length >= 2)
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm),
                      child: Text(
                        'vs',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

              const SizedBox(height: AppSpacing.md),

              // ── Slot B ──────────────────────────────────────────────
              if (rows.length >= 2)
                _SlotCard(
                  label: 'B',
                  row: rows[1],
                  controllers: _slotControllers[1],
                  onBasePriceChanged: (v) =>
                      _vm.updateBasePrice(rows[1].id, v),
                  onDiscountChanged: (v) =>
                      _vm.updateSaleDiscount(rows[1].id, v ?? 0),
                  onPointsChanged: (v) =>
                      _vm.updatePoints(rows[1].id, v ?? 0),
                  onQuantityChanged: (v) =>
                      _vm.updateQuantity(rows[1].id, v),
                  onNameChanged: (v) =>
                      _vm.updateProductName(rows[1].id, v),
                  onSave: () => _vm.saveRow(rows[1].id),
                ),

              const SizedBox(height: AppSpacing.lg),

              // ── Result banner ────────────────────────────────────────
              if (rows.length >= 2)
                _ResultBanner(rowA: rows[0], rowB: rows[1], l10n: l10n),
            ],
          ),
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

// ─── Slot card ────────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.label,
    required this.row,
    required this.controllers,
    required this.onBasePriceChanged,
    required this.onDiscountChanged,
    required this.onPointsChanged,
    required this.onQuantityChanged,
    required this.onNameChanged,
    required this.onSave,
  });

  final String label;
  final CompareRow row;
  final _SlotControllers controllers;
  final ValueChanged<double?> onBasePriceChanged;
  final ValueChanged<double?> onDiscountChanged;
  final ValueChanged<double?> onPointsChanged;
  final ValueChanged<double?> onQuantityChanged;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onSave;

  bool get _hasResult =>
      row.basePrice != null && row.quantity != null && row.quantity! > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isBest = row.isBest && _hasResult;

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
            // ── Card header ──────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      isBest ? AppColors.statusSuccess : colorScheme.primary,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (isBest) ...[
                  Icon(Icons.star, color: AppColors.statusSuccess, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatUnitPrice(row.unitPrice),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.statusSuccess,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ] else if (_hasResult) ...[
                  Text(
                    _formatUnitPrice(row.unitPrice),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Inputs ───────────────────────────────────────────────
            _numField(
              context,
              label: l10n.compareBasePrice,
              controller: controllers.basePrice,
              onChanged: (v) => onBasePriceChanged(_parseDouble(v)),
            ),
            const SizedBox(height: AppSpacing.sm),
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
            _numField(
              context,
              label: l10n.compareQuantity,
              controller: controllers.quantity,
              onChanged: (v) => onQuantityChanged(_parseDouble(v)),
            ),

            // ── Computed result ──────────────────────────────────────
            if (_hasResult) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.compareEffectivePrice,
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    row.effectivePrice != null
                        ? _formatPrice(row.effectivePrice!)
                        : '—',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.compareUnitPrice,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    _formatUnitPrice(row.unitPrice),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isBest ? AppColors.statusSuccess : null,
                        ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // ── Name + save ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers.name,
                    decoration: InputDecoration(
                      labelText: l10n.compareProductName,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: onNameChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(l10n.compareAddToHistory),
                  onPressed: _hasResult ? onSave : null,
                ),
              ],
            ),
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

// ─── Result banner ─────────────────────────────────────────────────────────────

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.rowA,
    required this.rowB,
    required this.l10n,
  });

  final CompareRow rowA;
  final CompareRow rowB;
  final AppLocalizations l10n;

  bool get _bothReady =>
      rowA.unitPrice != null && rowB.unitPrice != null;

  @override
  Widget build(BuildContext context) {
    if (!_bothReady) return const SizedBox.shrink();

    final winner = rowA.isBest ? 'A' : 'B';
    final diff = (rowA.unitPrice! - rowB.unitPrice!).abs();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusSuccessBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.statusSuccess),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: AppColors.statusSuccess, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$winner が安い',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.statusSuccess,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '差額 ¥${NumberFormat('#,##0.##').format(diff)}/個',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.statusSuccess,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Controllers holder ────────────────────────────────────────────────────────

class _SlotControllers {
  _SlotControllers()
      : name = TextEditingController(),
        basePrice = TextEditingController(),
        saleDiscount = TextEditingController(),
        points = TextEditingController(),
        quantity = TextEditingController();

  factory _SlotControllers.fromRow(CompareRow row) {
    return _SlotControllers()
      ..name.text = row.productName
      ..basePrice.text = _fmt(row.basePrice)
      ..saleDiscount.text = row.saleDiscount == 0 ? '' : _fmt(row.saleDiscount)
      ..points.text = row.points == 0 ? '' : _fmt(row.points)
      ..quantity.text = _fmt(row.quantity);
  }

  final TextEditingController name;
  final TextEditingController basePrice;
  final TextEditingController saleDiscount;
  final TextEditingController points;
  final TextEditingController quantity;

  static String _fmt(double? v) {
    if (v == null) return '';
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
  }

  void dispose() {
    name.dispose();
    basePrice.dispose();
    saleDiscount.dispose();
    points.dispose();
    quantity.dispose();
  }
}
