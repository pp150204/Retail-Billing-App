import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/product.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel extends Product {
  @override
  final String id;
  @override
  final String name;
  @override
  final String barcode;
  @override
  final double price;
  @override
  final int stock;
  @override
  final String category;
  @override
  final DateTime? expiryDate;

  const ProductModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.stock,
    this.category = 'Uncategorized',
    this.expiryDate,
  }) : super(
          id: id,
          name: name,
          barcode: barcode,
          price: price,
          stock: stock,
          category: category,
          expiryDate: expiryDate,
        );

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      barcode: product.barcode,
      price: product.price,
      stock: product.stock,
      category: product.category,
      expiryDate: product.expiryDate,
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      barcode: barcode,
      price: price,
      stock: stock,
      category: category,
      expiryDate: expiryDate,
    );
  }

  // SQLite serialization
  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  // SQLite database methods
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      barcode: map['barcode'] as String,
      price: map['price'] as double,
      stock: map['stock'] as int,
      category: map['category'] as String? ?? 'Uncategorized',
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'price': price,
      'stock': stock,
      'category': category,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }
}
