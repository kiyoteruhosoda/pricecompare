import 'package:equatable/equatable.dart';
import 'package:flutterbase/domain/value_objects/product_history_id.dart';
import 'package:flutterbase/domain/value_objects/product_id.dart';

class ProductHistory extends Equatable {
  const ProductHistory({
    required this.id,
    required this.productId,
    this.storeName,
    required this.basePrice,
    required this.saleDiscount,
    required this.points,
    required this.quantity,
    required this.effectivePrice,
    required this.unitPrice,
    this.memo,
    required this.recordedAt,
    required this.createdAt,
  });

  final ProductHistoryId id;
  final ProductId productId;
  final String? storeName;
  final double basePrice;
  final double saleDiscount;
  final double points;
  final double quantity;
  final double effectivePrice;
  final double unitPrice;
  final String? memo;
  final DateTime recordedAt;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        productId,
        storeName,
        basePrice,
        saleDiscount,
        points,
        quantity,
        effectivePrice,
        unitPrice,
        memo,
        recordedAt,
        createdAt,
      ];
}
