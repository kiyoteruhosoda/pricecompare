import 'package:flutterbase/infrastructure/db/sqlite/migrations/migration_v1.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'pricecompare.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await migrateV1(db);
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Database get db {
    assert(_db != null, 'AppDatabase.init() must be called before accessing db');
    return _db!;
  }
}
