class ProductSummaryDto {
  const ProductSummaryDto({
    required this.historyCount,
    required this.minUnitPrice,
    required this.latestRecordedAt,
  });

  final int historyCount;
  final double minUnitPrice;
  final DateTime latestRecordedAt;
}
