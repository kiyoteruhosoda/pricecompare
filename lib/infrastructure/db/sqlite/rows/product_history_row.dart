class ProductHistoryRow {
  const ProductHistoryRow({
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

  final String id;
  final String productId;
  final String? storeName;
  final double basePrice;
  final double saleDiscount;
  final double points;
  final double quantity;
  final double effectivePrice;
  final double unitPrice;
  final String? memo;
  final String recordedAt;
  final String createdAt;

  factory ProductHistoryRow.fromMap(Map<String, dynamic> map) {
    return ProductHistoryRow(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      storeName: map['store_name'] as String?,
      basePrice: (map['base_price'] as num).toDouble(),
      saleDiscount: (map['sale_discount'] as num).toDouble(),
      points: (map['points'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      effectivePrice: (map['effective_price'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      memo: map['memo'] as String?,
      recordedAt: map['recorded_at'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'store_name': storeName,
      'base_price': basePrice,
      'sale_discount': saleDiscount,
      'points': points,
      'quantity': quantity,
      'effective_price': effectivePrice,
      'unit_price': unitPrice,
      'memo': memo,
      'recorded_at': recordedAt,
      'created_at': createdAt,
    };
  }
}
