import 'package:equatable/equatable.dart';

class ProductId extends Equatable {
  const ProductId(this.value) : assert(value != '', 'ProductId cannot be empty');

  final String value;

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}
