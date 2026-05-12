import 'package:pricecompare/domain/entities/product.dart';
import 'package:pricecompare/domain/entities/product_history.dart';
import 'package:pricecompare/domain/repositories/product_repository.dart';
import 'package:pricecompare/domain/value_objects/product_history_id.dart';
import 'package:pricecompare/domain/value_objects/product_id.dart';
import 'package:pricecompare/infrastructure/db/sqlite/dao/product_dao.dart';
import 'package:pricecompare/infrastructure/db/sqlite/dao/product_history_dao.dart';
import 'package:pricecompare/infrastructure/mappers/product_history_mapper.dart';
import 'package:pricecompare/infrastructure/mappers/product_mapper.dart';

class SqliteProductRepository implements ProductRepository {
  const SqliteProductRepository({
    required ProductDao productDao,
    required ProductHistoryDao historyDao,
  })  : _productDao = productDao,
        _historyDao = historyDao;

  final ProductDao _productDao;
  final ProductHistoryDao _historyDao;

  @override
  Future<List<Product>> getAll() async {
    final rows = await _productDao.findAll();
    return rows.map(ProductMapper.fromRow).toList();
  }

  @override
  Future<List<Product>> search(String query) async {
    final rows = await _productDao.search(query);
    return rows.map(ProductMapper.fromRow).toList();
  }

  @override
  Future<Product?> findByName(String name) async {
    final row = await _productDao.findByName(name);
    return row == null ? null : ProductMapper.fromRow(row);
  }

  @override
  Future<Product?> findById(ProductId id) async {
    final row = await _productDao.findById(id.value);
    return row == null ? null : ProductMapper.fromRow(row);
  }

  @override
  Future<void> save(Product product) async {
    await _productDao.upsert(ProductMapper.toRow(product));
  }

  @override
  Future<void> deleteById(ProductId id) async {
    await _productDao.deleteById(id.value);
  }

  @override
  Future<List<ProductHistory>> getHistoriesForProduct(
      ProductId productId) async {
    final rows = await _historyDao.findByProductId(productId.value);
    return rows.map(ProductHistoryMapper.fromRow).toList();
  }

  @override
  Future<ProductHistory?> getHistoryById(ProductHistoryId id) async {
    final row = await _historyDao.findById(id.value);
    return row == null ? null : ProductHistoryMapper.fromRow(row);
  }

  @override
  Future<void> saveHistory(ProductHistory history) async {
    await _historyDao.insert(ProductHistoryMapper.toRow(history));
  }

  @override
  Future<void> deleteHistoryById(ProductHistoryId id) async {
    await _historyDao.deleteById(id.value);
  }

  @override
  Future<ProductSummary?> getSummaryByName(String name) async {
    final product = await _productDao.findByName(name);
    if (product == null) return null;
    final raw = await _historyDao.getSummaryByProductId(product.id);
    if (raw == null) return null;
    return ProductSummary(
      historyCount: raw['history_count'] as int,
      minUnitPrice: (raw['min_unit_price'] as num).toDouble(),
      latestRecordedAt: DateTime.parse(raw['latest_recorded_at'] as String),
    );
  }
}
