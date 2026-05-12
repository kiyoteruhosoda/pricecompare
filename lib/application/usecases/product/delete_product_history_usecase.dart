import 'package:flutterbase/domain/repositories/product_repository.dart';
import 'package:flutterbase/domain/value_objects/product_history_id.dart';

class DeleteProductHistoryUseCase {
  const DeleteProductHistoryUseCase(this._repository);

  final ProductRepository _repository;

  Future<void> execute(ProductHistoryId id) => _repository.deleteHistoryById(id);
}
