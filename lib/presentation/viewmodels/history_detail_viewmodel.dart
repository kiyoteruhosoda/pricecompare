import 'package:flutter/material.dart';
import 'package:pricecompare/application/usecases/product/delete_product_history_usecase.dart';
import 'package:pricecompare/application/usecases/product/get_product_history_usecase.dart';
import 'package:pricecompare/domain/entities/product_history.dart';
import 'package:pricecompare/domain/value_objects/product_history_id.dart';

enum HistoryDetailState { loading, loaded, deleted, error }

class HistoryDetailViewModel extends ChangeNotifier {
  HistoryDetailViewModel(
    this._getHistory,
    this._deleteHistory,
  );

  final GetProductHistoryUseCase _getHistory;
  final DeleteProductHistoryUseCase _deleteHistory;

  HistoryDetailState _state = HistoryDetailState.loading;
  ProductHistory? _history;
  String? _errorMessage;

  HistoryDetailState get state => _state;
  ProductHistory? get history => _history;
  String? get errorMessage => _errorMessage;

  Future<void> load(ProductHistoryId id) async {
    _state = HistoryDetailState.loading;
    notifyListeners();
    try {
      _history = await _getHistory.execute(id);
      _state = _history != null
          ? HistoryDetailState.loaded
          : HistoryDetailState.error;
      _errorMessage = _history == null ? 'not_found' : null;
    } catch (e) {
      _state = HistoryDetailState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> delete() async {
    if (_history == null) return;
    await _deleteHistory.execute(_history!.id);
    _state = HistoryDetailState.deleted;
    notifyListeners();
  }
}
