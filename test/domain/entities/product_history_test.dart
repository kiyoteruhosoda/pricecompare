import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/domain/entities/product_history.dart';
import 'package:flutterbase/domain/value_objects/product_history_id.dart';
import 'package:flutterbase/domain/value_objects/product_id.dart';

void main() {
  final now = DateTime(2026, 5, 12);

  ProductHistory makeHistory({
    double basePrice = 100,
    double saleDiscount = 10,
    double points = 5,
    double quantity = 2,
  }) {
    final effective = basePrice - saleDiscount - points;
    return ProductHistory(
      id: ProductHistoryId('hid'),
      productId: ProductId('pid'),
      basePrice: basePrice,
      saleDiscount: saleDiscount,
      points: points,
      quantity: quantity,
      effectivePrice: effective,
      unitPrice: effective / quantity,
      recordedAt: now,
      createdAt: now,
    );
  }

  group('ProductHistory', () {
    test('effectivePrice = basePrice - saleDiscount - points', () {
      final h = makeHistory(basePrice: 200, saleDiscount: 20, points: 10);
      expect(h.effectivePrice, 170.0);
    });

    test('unitPrice = effectivePrice / quantity', () {
      final h =
          makeHistory(basePrice: 200, saleDiscount: 20, points: 10, quantity: 5);
      expect(h.unitPrice, 34.0);
    });

    test('equality by value', () {
      final a = makeHistory();
      final b = makeHistory();
      expect(a, equals(b));
    });
  });
}
