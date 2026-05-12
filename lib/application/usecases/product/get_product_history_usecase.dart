import 'package:flutterbase/domain/entities/product_history.dart';
import 'package:flutterbase/domain/repositories/product_repository.dart';
import 'package:flutterbase/domain/value_objects/product_history_id.dart';

class GetProductHistoryUseCase {
  const GetProductHistoryUseCase(this._repository);

  final ProductRepository _repository;

  Future<ProductHistory?> execute(ProductHistoryId id) =>
      _repository.getHistoryById(id);
}
