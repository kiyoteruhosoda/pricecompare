import 'package:equatable/equatable.dart';
import 'package:flutterbase/domain/value_objects/product_id.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final ProductId id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product copyWith({
    ProductId? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [id, name, createdAt, updatedAt];
}
