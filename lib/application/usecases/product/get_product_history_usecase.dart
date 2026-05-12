import 'package:pricecompare/domain/entities/product_history.dart';
import 'package:pricecompare/domain/repositories/product_repository.dart';
import 'package:pricecompare/domain/value_objects/product_history_id.dart';

class GetProductHistoryUseCase {
  const GetProductHistoryUseCase(this._repository);

  final ProductRepository _repository;

  Future<ProductHistory?> execute(ProductHistoryId id) =>
      _repository.getHistoryById(id);
}
