import 'package:equatable/equatable.dart';

class ProductHistoryId extends Equatable {
  const ProductHistoryId(this.value)
      : assert(value != '', 'ProductHistoryId cannot be empty');

  final String value;

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}
