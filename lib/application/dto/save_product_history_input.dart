class SaveProductHistoryInput {
  const SaveProductHistoryInput({
    required this.productName,
    this.storeName,
    required this.basePrice,
    required this.saleDiscount,
    required this.points,
    required this.quantity,
    this.memo,
  });

  final String productName;
  final String? storeName;
  final double basePrice;
  final double saleDiscount;
  final double points;
  final double quantity;
  final String? memo;
}
