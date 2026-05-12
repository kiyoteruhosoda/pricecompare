import 'package:pricecompare/domain/repositories/product_repository.dart';
import 'package:pricecompare/domain/value_objects/product_id.dart';

class DeleteProductUseCase {
  const DeleteProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<void> execute(ProductId id) => _repository.deleteById(id);
}
