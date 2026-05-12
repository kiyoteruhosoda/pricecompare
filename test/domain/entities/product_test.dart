import 'package:flutter_test/flutter_test.dart';
import 'package:pricecompare/domain/entities/product.dart';
import 'package:pricecompare/domain/value_objects/product_id.dart';

void main() {
  final id = ProductId('test-id');
  final now = DateTime(2026, 5, 12);

  group('Product', () {
    test('equality is by value', () {
      final a = Product(id: id, name: 'Rice', createdAt: now, updatedAt: now);
      final b = Product(id: id, name: 'Rice', createdAt: now, updatedAt: now);
      expect(a, equals(b));
    });

    test('copyWith updates only supplied fields', () {
      final product =
          Product(id: id, name: 'Rice', createdAt: now, updatedAt: now);
      final updated = product.copyWith(name: 'Bread');
      expect(updated.name, 'Bread');
      expect(updated.id, product.id);
      expect(updated.createdAt, product.createdAt);
    });
  });

  group('ProductId', () {
    test('equality by value', () {
      expect(ProductId('abc'), equals(ProductId('abc')));
      expect(ProductId('abc'), isNot(equals(ProductId('xyz'))));
    });
  });
}
