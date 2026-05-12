import 'package:pricecompare/application/dto/save_product_history_input.dart';
import 'package:pricecompare/domain/entities/product.dart';
import 'package:pricecompare/domain/entities/product_history.dart';
import 'package:pricecompare/domain/repositories/product_repository.dart';
import 'package:pricecompare/domain/value_objects/product_history_id.dart';
import 'package:pricecompare/domain/value_objects/product_id.dart';
import 'package:pricecompare/shared/errors/app_error.dart';
import 'package:pricecompare/shared/utils/uuid_generator.dart';

class SaveProductHistoryUseCase {
  const SaveProductHistoryUseCase(this._repository);

  final ProductRepository _repository;

  Future<ProductHistory> execute(SaveProductHistoryInput input) async {
    if (input.productName.trim().isEmpty) {
      throw const DomainError('product_name_required');
    }
    if (input.basePrice < 0) {
      throw const DomainError('base_price_non_negative');
    }
    if (input.saleDiscount < 0) {
      throw const DomainError('sale_discount_non_negative');
    }
    if (input.points < 0) {
      throw const DomainError('points_non_negative');
    }
    if (input.quantity <= 0) {
      throw const DomainError('quantity_positive');
    }

    final now = DateTime.now();
    final effectivePrice =
        input.basePrice - input.saleDiscount - input.points;
    final unitPrice = effectivePrice / input.quantity;

    var product = await _repository.findByName(input.productName.trim());
    if (product == null) {
      product = Product(
        id: ProductId(generateUuid()),
        name: input.productName.trim(),
        createdAt: now,
        updatedAt: now,
      );
    } else {
      product = product.copyWith(updatedAt: now);
    }
    await _repository.save(product);

    final history = ProductHistory(
      id: ProductHistoryId(generateUuid()),
      productId: product.id,
      storeName: input.storeName?.trim().isEmpty == true
          ? null
          : input.storeName?.trim(),
      basePrice: input.basePrice,
      saleDiscount: input.saleDiscount,
      points: input.points,
      quantity: input.quantity,
      effectivePrice: effectivePrice,
      unitPrice: unitPrice,
      memo: input.memo?.trim().isEmpty == true ? null : input.memo?.trim(),
      recordedAt: now,
      createdAt: now,
    );
    await _repository.saveHistory(history);
    return history;
  }
}
