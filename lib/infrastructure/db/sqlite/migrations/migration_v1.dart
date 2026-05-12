import 'package:sqflite/sqflite.dart';

Future<void> migrateV1(Database db) async {
  await db.execute('''
    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE product_histories (
      id TEXT PRIMARY KEY,
      product_id TEXT NOT NULL,
      store_name TEXT,
      base_price REAL NOT NULL,
      sale_discount REAL NOT NULL,
      points REAL NOT NULL,
      quantity REAL NOT NULL,
      effective_price REAL NOT NULL,
      unit_price REAL NOT NULL,
      memo TEXT,
      recorded_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
    )
  ''');

  await db.execute(
    'CREATE INDEX idx_product_histories_product_id ON product_histories (product_id)',
  );

  await db.execute(
    'CREATE INDEX idx_products_name ON products (name)',
  );
}
