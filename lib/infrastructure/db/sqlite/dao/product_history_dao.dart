import 'package:flutterbase/infrastructure/db/sqlite/rows/product_history_row.dart';
import 'package:sqflite/sqflite.dart';

class ProductHistoryDao {
  const ProductHistoryDao(this._db);

  final Database _db;

  static const _table = 'product_histories';

  Future<List<ProductHistoryRow>> findByProductId(String productId) async {
    final maps = await _db.query(
      _table,
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'recorded_at DESC',
    );
    return maps.map(ProductHistoryRow.fromMap).toList();
  }

  Future<ProductHistoryRow?> findById(String id) async {
    final maps = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ProductHistoryRow.fromMap(maps.first);
  }

  Future<void> insert(ProductHistoryRow row) async {
    await _db.insert(
      _table,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteById(String id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getSummaryByProductId(
      String productId) async {
    final result = await _db.rawQuery(
      '''
      SELECT
        COUNT(*) AS history_count,
        MIN(unit_price) AS min_unit_price,
        MAX(recorded_at) AS latest_recorded_at
      FROM $_table
      WHERE product_id = ?
      ''',
      [productId],
    );
    if (result.isEmpty) return null;
    final row = result.first;
    if (row['history_count'] == 0) return null;
    return row;
  }
}
