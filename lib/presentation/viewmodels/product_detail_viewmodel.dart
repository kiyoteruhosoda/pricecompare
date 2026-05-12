import 'package:flutter/material.dart';
import 'package:flutterbase/application/usecases/product/delete_product_history_usecase.dart';
import 'package:flutterbase/application/usecases/product/get_product_histories_usecase.dart';
import 'package:flutterbase/domain/entities/product.dart';
import 'package:flutterbase/domain/entities/product_history.dart';
import 'package:flutterbase/domain/value_objects/product_history_id.dart';
import 'package:flutterbase/domain/value_objects/product_id.dart';

enum ProductDetailState { loading, loaded, empty, error }

class ProductDetailViewModel extends ChangeNotifier {
  ProductDetailViewModel(
    this._getHistories,
    this._deleteHistory,
  );

  final GetProductHistoriesUseCase _getHistories;
  final DeleteProductHistoryUseCase _deleteHistory;

  ProductDetailState _state = ProductDetailState.loading;
  Product? _product;
  List<ProductHistory> _histories = [];
  String? _errorMessage;

  ProductDetailState get state => _state;
  Product? get product => _product;
  List<ProductHistory> get histories => List.unmodifiable(_histories);
  String? get errorMessage => _errorMessage;

  double? get minUnitPrice {
    if (_histories.isEmpty) return null;
    return _histories.map((h) => h.unitPrice).reduce((a, b) => a < b ? a : b);
  }

  double? get latestUnitPrice =>
      _histories.isNotEmpty ? _histories.first.unitPrice : null;

  Future<void> load(Product product) async {
    _product = product;
    _state = ProductDetailState.loading;
    notifyListeners();
    await _fetchHistories(product.id);
  }

  Future<void> deleteHistory(ProductHistoryId id) async {
    await _deleteHistory.execute(id);
    if (_product != null) {
      await _fetchHistories(_product!.id);
    }
  }

  Future<void> _fetchHistories(ProductId productId) async {
    try {
      _histories = await _getHistories.execute(productId);
      _state = _histories.isEmpty
          ? ProductDetailState.empty
          : ProductDetailState.loaded;
      _errorMessage = null;
    } catch (e) {
      _state = ProductDetailState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
