import 'package:pricecompare/domain/entities/product.dart';
import 'package:pricecompare/domain/repositories/product_repository.dart';

class SearchProductsUseCase {
  const SearchProductsUseCase(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> execute(String query) {
    if (query.trim().isEmpty) return _repository.getAll();
    return _repository.search(query.trim());
  }
}
