import 'package:flutterbase/application/dto/product_summary_dto.dart';
import 'package:flutterbase/domain/repositories/product_repository.dart';

class GetProductSummaryUseCase {
  const GetProductSummaryUseCase(this._repository);

  final ProductRepository _repository;

  Future<ProductSummaryDto?> execute(String productName) async {
    if (productName.trim().isEmpty) return null;
    final summary = await _repository.getSummaryByName(productName.trim());
    if (summary == null) return null;
    return ProductSummaryDto(
      historyCount: summary.historyCount,
      minUnitPrice: summary.minUnitPrice,
      latestRecordedAt: summary.latestRecordedAt,
    );
  }
}
