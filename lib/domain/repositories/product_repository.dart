import 'package:pricecompare/domain/entities/product.dart';
import 'package:pricecompare/domain/entities/product_history.dart';
import 'package:pricecompare/domain/value_objects/product_history_id.dart';
import 'package:pricecompare/domain/value_objects/product_id.dart';

abstract interface class ProductRepository {
  Future<List<Product>> getAll();
  Future<List<Product>> search(String query);
  Future<Product?> findByName(String name);
  Future<Product?> findById(ProductId id);
  Future<void> save(Product product);
  Future<void> deleteById(ProductId id);

  Future<List<ProductHistory>> getHistoriesForProduct(ProductId productId);
  Future<ProductHistory?> getHistoryById(ProductHistoryId id);
  Future<void> saveHistory(ProductHistory history);
  Future<void> deleteHistoryById(ProductHistoryId id);

  Future<ProductSummary?> getSummaryByName(String name);
}

class ProductSummary {
  const ProductSummary({
    required this.historyCount,
    required this.minUnitPrice,
    required this.latestRecordedAt,
  });

  final int historyCount;
  final double minUnitPrice;
  final DateTime latestRecordedAt;
}
