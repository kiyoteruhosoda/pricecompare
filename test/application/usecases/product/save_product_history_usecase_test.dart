import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/application/dto/save_product_history_input.dart';
import 'package:flutterbase/application/usecases/product/save_product_history_usecase.dart';
import 'package:flutterbase/domain/entities/product.dart';
import 'package:flutterbase/domain/entities/product_history.dart';
import 'package:flutterbase/domain/repositories/product_repository.dart';
import 'package:flutterbase/domain/value_objects/product_history_id.dart';
import 'package:flutterbase/domain/value_objects/product_id.dart';
import 'package:flutterbase/shared/errors/app_error.dart';

class _FakeProductRepository implements ProductRepository {
  Product? storedProduct;
  ProductHistory? storedHistory;
  final Product? findByNameResult;

  _FakeProductRepository({this.findByNameResult});

  @override
  Future<Product?> findByName(String name) async => findByNameResult;

  @override
  Future<void> save(Product product) async {
    storedProduct = product;
  }

  @override
  Future<void> saveHistory(ProductHistory history) async {
    storedHistory = history;
  }

  @override
  Future<List<Product>> getAll() async => [];

  @override
  Future<List<Product>> search(String query) async => [];

  @override
  Future<Product?> findById(ProductId id) async => null;

  @override
  Future<void> deleteById(ProductId id) async {}

  @override
  Future<List<ProductHistory>> getHistoriesForProduct(
      ProductId productId) async => [];

  @override
  Future<ProductHistory?> getHistoryById(ProductHistoryId id) async => null;

  @override
  Future<void> deleteHistoryById(ProductHistoryId id) async {}

  @override
  Future<ProductSummary?> getSummaryByName(String name) async => null;
}

void main() {
  group('SaveProductHistoryUseCase', () {
    test('throws DomainError when productName is empty', () {
      final repo = _FakeProductRepository();
      final useCase = SaveProductHistoryUseCase(repo);
      expect(
        () => useCase.execute(
          const SaveProductHistoryInput(
            productName: '',
            basePrice: 100,
            saleDiscount: 0,
            points: 0,
            quantity: 1,
          ),
        ),
        throwsA(isA<DomainError>()),
      );
    });

    test('throws DomainError when quantity is zero or negative', () {
      final repo = _FakeProductRepository();
      final useCase = SaveProductHistoryUseCase(repo);
      expect(
        () => useCase.execute(
          const SaveProductHistoryInput(
            productName: 'Rice',
            basePrice: 100,
            saleDiscount: 0,
            points: 0,
            quantity: 0,
          ),
        ),
        throwsA(isA<DomainError>()),
      );
    });

    test('throws DomainError when basePrice is negative', () {
      final repo = _FakeProductRepository();
      final useCase = SaveProductHistoryUseCase(repo);
      expect(
        () => useCase.execute(
          const SaveProductHistoryInput(
            productName: 'Rice',
            basePrice: -1,
            saleDiscount: 0,
            points: 0,
            quantity: 1,
          ),
        ),
        throwsA(isA<DomainError>()),
      );
    });

    test('computes effectivePrice and unitPrice correctly', () async {
      final repo = _FakeProductRepository();
      final useCase = SaveProductHistoryUseCase(repo);
      final result = await useCase.execute(
        const SaveProductHistoryInput(
          productName: 'Rice',
          basePrice: 200,
          saleDiscount: 20,
          points: 10,
          quantity: 5,
        ),
      );
      expect(result.effectivePrice, 170.0);
      expect(result.unitPrice, 34.0);
      expect(repo.storedProduct, isNotNull);
      expect(repo.storedHistory, isNotNull);
    });

    test('reuses existing product when name matches', () async {
      final now = DateTime(2026, 5, 12);
      final existing = Product(
        id: ProductId('existing-id'),
        name: 'Rice',
        createdAt: now,
        updatedAt: now,
      );
      final repo = _FakeProductRepository(findByNameResult: existing);
      final useCase = SaveProductHistoryUseCase(repo);
      final result = await useCase.execute(
        const SaveProductHistoryInput(
          productName: 'Rice',
          basePrice: 100,
          saleDiscount: 0,
          points: 0,
          quantity: 1,
        ),
      );
      expect(result.productId, existing.id);
    });
  });
}
