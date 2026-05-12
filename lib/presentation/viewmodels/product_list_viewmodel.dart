import 'package:flutter/material.dart';
import 'package:flutterbase/application/usecases/product/delete_product_usecase.dart';
import 'package:flutterbase/application/usecases/product/search_products_usecase.dart';
import 'package:flutterbase/domain/entities/product.dart';
import 'package:flutterbase/domain/repositories/product_repository.dart';
import 'package:flutterbase/domain/value_objects/product_id.dart';

class ProductListItem {
  const ProductListItem({
    required this.product,
    this.historyCount = 0,
    this.minUnitPrice,
    this.latestRecordedAt,
  });

  final Product product;
  final int historyCount;
  final double? minUnitPrice;
  final DateTime? latestRecordedAt;
}

enum ProductListState { loading, loaded, empty, error }

class ProductListViewModel extends ChangeNotifier {
  ProductListViewModel(
    this._searchProducts,
    this._deleteProduct,
    this._repository,
  );

  final SearchProductsUseCase _searchProducts;
  final DeleteProductUseCase _deleteProduct;
  final ProductRepository _repository;

  ProductListState _state = ProductListState.loading;
  List<ProductListItem> _items = [];
  String _searchQuery = '';
  String? _errorMessage;

  ProductListState get state => _state;
  List<ProductListItem> get items => List.unmodifiable(_items);
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _state = ProductListState.loading;
    notifyListeners();
    await _fetchItems(_searchQuery);
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    await _fetchItems(query);
  }

  Future<void> deleteProduct(ProductId id) async {
    await _deleteProduct.execute(id);
    await _fetchItems(_searchQuery);
  }

  Future<void> _fetchItems(String query) async {
    try {
      final products = await _searchProducts.execute(query);
      final items = <ProductListItem>[];
      for (final product in products) {
        final summary = await _repository.getSummaryByName(product.name);
        items.add(
          ProductListItem(
            product: product,
            historyCount: summary?.historyCount ?? 0,
            minUnitPrice: summary?.minUnitPrice,
            latestRecordedAt: summary?.latestRecordedAt,
          ),
        );
      }
      _items = items;
      _state = _items.isEmpty
          ? ProductListState.empty
          : ProductListState.loaded;
      _errorMessage = null;
    } catch (e) {
      _state = ProductListState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
