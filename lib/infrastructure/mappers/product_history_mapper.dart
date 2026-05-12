import 'package:pricecompare/domain/entities/product_history.dart';
import 'package:pricecompare/domain/value_objects/product_history_id.dart';
import 'package:pricecompare/domain/value_objects/product_id.dart';
import 'package:pricecompare/infrastructure/db/sqlite/rows/product_history_row.dart';

class ProductHistoryMapper {
  const ProductHistoryMapper._();

  static ProductHistory fromRow(ProductHistoryRow row) {
    return ProductHistory(
      id: ProductHistoryId(row.id),
      productId: ProductId(row.productId),
      storeName: row.storeName,
      basePrice: row.basePrice,
      saleDiscount: row.saleDiscount,
      points: row.points,
      quantity: row.quantity,
      effectivePrice: row.effectivePrice,
      unitPrice: row.unitPrice,
      memo: row.memo,
      recordedAt: DateTime.parse(row.recordedAt),
      createdAt: DateTime.parse(row.createdAt),
    );
  }

  static ProductHistoryRow toRow(ProductHistory history) {
    return ProductHistoryRow(
      id: history.id.value,
      productId: history.productId.value,
      storeName: history.storeName,
      basePrice: history.basePrice,
      saleDiscount: history.saleDiscount,
      points: history.points,
      quantity: history.quantity,
      effectivePrice: history.effectivePrice,
      unitPrice: history.unitPrice,
      memo: history.memo,
      recordedAt: history.recordedAt.toIso8601String(),
      createdAt: history.createdAt.toIso8601String(),
    );
  }
}
