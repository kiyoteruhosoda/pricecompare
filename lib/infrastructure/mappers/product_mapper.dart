import 'package:flutterbase/domain/entities/product.dart';
import 'package:flutterbase/domain/value_objects/product_id.dart';
import 'package:flutterbase/infrastructure/db/sqlite/rows/product_row.dart';

class ProductMapper {
  const ProductMapper._();

  static Product fromRow(ProductRow row) {
    return Product(
      id: ProductId(row.id),
      name: row.name,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );
  }

  static ProductRow toRow(Product product) {
    return ProductRow(
      id: product.id.value,
      name: product.name,
      createdAt: product.createdAt.toIso8601String(),
      updatedAt: product.updatedAt.toIso8601String(),
    );
  }
}
