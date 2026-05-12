import 'package:flutter/material.dart';
import 'package:pricecompare/application/dto/save_product_history_input.dart';
import 'package:pricecompare/application/usecases/product/save_product_history_usecase.dart';

class CompareRow {
  CompareRow({
    required this.id,
    this.storeName = '',
    this.basePrice,
    this.saleDiscount = 0,
    this.points = 0,
    this.quantity,
    this.effectivePrice,
    this.unitPrice,
    this.isBest = false,
  });

  final String id;
  String storeName;
  double? basePrice;
  double saleDiscount;
  double points;
  double? quantity;
  double? effectivePrice;
  double? unitPrice;
  bool isBest;

  CompareRow copyWith({
    String? storeName,
    double? basePrice,
    bool clearBasePrice = false,
    double? saleDiscount,
    double? points,
    double? quantity,
    bool clearQuantity = false,
    double? effectivePrice,
    bool clearEffectivePrice = false,
    double? unitPrice,
    bool clearUnitPrice = false,
    bool? isBest,
  }) {
    return CompareRow(
      id: id,
      storeName: storeName ?? this.storeName,
      basePrice: clearBasePrice ? null : (basePrice ?? this.basePrice),
      saleDiscount: saleDiscount ?? this.saleDiscount,
      points: points ?? this.points,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      effectivePrice:
          clearEffectivePrice ? null : (effectivePrice ?? this.effectivePrice),
      unitPrice: clearUnitPrice ? null : (unitPrice ?? this.unitPrice),
      isBest: isBest ?? this.isBest,
    );
  }
}

enum CompareState { idle, saving, saved, error }

class CompareViewModel extends ChangeNotifier {
  CompareViewModel(this._saveHistory) {
    _rows = [_newRow(), _newRow()];
  }

  final SaveProductHistoryUseCase _saveHistory;

  String _productName = '';
  late List<CompareRow> _rows;
  CompareState _state = CompareState.idle;
  String? _errorMessage;

  String get productName => _productName;
  List<CompareRow> get rows => List.unmodifiable(_rows);
  CompareState get state => _state;
  String? get errorMessage => _errorMessage;

  int _rowCounter = 0;

  CompareRow _newRow() {
    _rowCounter++;
    return CompareRow(id: 'row_$_rowCounter');
  }

  void updateProductName(String name) {
    _productName = name;
    notifyListeners();
  }

  void addRow() {
    _rows = [..._rows, _newRow()];
    notifyListeners();
  }

  void removeRow(String id) {
    if (_rows.length <= 1) return;
    _rows = _rows.where((r) => r.id != id).toList();
    _recalculate();
    notifyListeners();
  }

  void updateStoreName(String id, String name) {
    _updateRow(id, (r) => r.copyWith(storeName: name));
    notifyListeners();
  }

  void updateBasePrice(String id, double? value) {
    _updateRow(
      id,
      (r) => value == null
          ? r.copyWith(clearBasePrice: true)
          : r.copyWith(basePrice: value),
    );
    _recalculate();
  }

  void updateSaleDiscount(String id, double value) {
    _updateRow(id, (r) => r.copyWith(saleDiscount: value));
    _recalculate();
  }

  void updatePoints(String id, double value) {
    _updateRow(id, (r) => r.copyWith(points: value));
    _recalculate();
  }

  void updateQuantity(String id, double? value) {
    _updateRow(
      id,
      (r) => value == null
          ? r.copyWith(clearQuantity: true)
          : r.copyWith(quantity: value),
    );
    _recalculate();
  }

  Future<void> saveAll() async {
    final saveable = _rows
        .where((r) => r.basePrice != null && r.quantity != null && r.quantity! > 0)
        .toList();
    if (saveable.isEmpty) return;

    if (_productName.trim().isEmpty) {
      _errorMessage = 'name_required';
      _state = CompareState.error;
      notifyListeners();
      return;
    }

    _state = CompareState.saving;
    notifyListeners();

    try {
      for (final row in saveable) {
        await _saveHistory.execute(
          SaveProductHistoryInput(
            productName: _productName.trim(),
            storeName:
                row.storeName.trim().isEmpty ? null : row.storeName.trim(),
            basePrice: row.basePrice!,
            saleDiscount: row.saleDiscount,
            points: row.points,
            quantity: row.quantity!,
          ),
        );
      }
      _state = CompareState.saved;
      _errorMessage = null;
    } catch (_) {
      _state = CompareState.error;
      _errorMessage = 'save_failed';
    }
    notifyListeners();
  }

  void clearState() {
    _state = CompareState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  void _updateRow(String id, CompareRow Function(CompareRow) transform) {
    _rows = _rows.map((r) => r.id == id ? transform(r) : r).toList();
  }

  void _recalculate() {
    double? minUnitPrice;
    final updated = _rows.map((r) {
      if (r.basePrice == null || r.quantity == null || r.quantity! <= 0) {
        return r.copyWith(
          clearEffectivePrice: true,
          clearUnitPrice: true,
          isBest: false,
        );
      }
      final eff = r.basePrice! - r.saleDiscount - r.points;
      final unit = eff / r.quantity!;
      if (minUnitPrice == null || unit < minUnitPrice!) {
        minUnitPrice = unit;
      }
      return r.copyWith(effectivePrice: eff, unitPrice: unit, isBest: false);
    }).toList();

    _rows = updated.map((r) {
      if (r.unitPrice != null &&
          minUnitPrice != null &&
          r.unitPrice == minUnitPrice) {
        return r.copyWith(isBest: true);
      }
      return r;
    }).toList();

    notifyListeners();
  }
}
