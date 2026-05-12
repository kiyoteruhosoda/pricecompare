import 'package:pricecompare/domain/entities/product_history.dart';
import 'package:pricecompare/domain/repositories/product_repository.dart';
import 'package:pricecompare/domain/value_objects/product_id.dart';

class GetProductHistoriesUseCase {
  const GetProductHistoriesUseCase(this._repository);

  final ProductRepository _repository;

  Future<List<ProductHistory>> execute(ProductId productId) =>
      _repository.getHistoriesForProduct(productId);
}
