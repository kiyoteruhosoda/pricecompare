import 'package:flutterbase/infrastructure/db/sqlite/rows/product_row.dart';
import 'package:sqflite/sqflite.dart';

class ProductDao {
  const ProductDao(this._db);

  final Database _db;

  static const _table = 'products';

  Future<List<ProductRow>> findAll() async {
    final maps = await _db.query(_table, orderBy: 'updated_at DESC');
    return maps.map(ProductRow.fromMap).toList();
  }

  Future<List<ProductRow>> search(String query) async {
    final maps = await _db.query(
      _table,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'updated_at DESC',
    );
    return maps.map(ProductRow.fromMap).toList();
  }

  Future<ProductRow?> findByName(String name) async {
    final maps = await _db.query(
      _table,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ProductRow.fromMap(maps.first);
  }

  Future<ProductRow?> findById(String id) async {
    final maps = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ProductRow.fromMap(maps.first);
  }

  Future<void> upsert(ProductRow row) async {
    await _db.insert(
      _table,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteById(String id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
