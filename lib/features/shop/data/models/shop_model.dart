import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/shop.dart';

part 'shop_model.g.dart';

@JsonSerializable()
class ShopModel extends Shop {
  @override
  final String name;
  @override
  final String addressLine1;
  @override
  final String addressLine2;
  @override
  final String phoneNumber;
  @override
  final String upiId;
  @override
  final String footerText;

  const ShopModel({
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.phoneNumber,
    required this.upiId,
    required this.footerText,
  }) : super(
          name: name,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          phoneNumber: phoneNumber,
          upiId: upiId,
          footerText: footerText,
        );

  factory ShopModel.fromEntity(Shop shop) {
    return ShopModel(
      name: shop.name,
      addressLine1: shop.addressLine1,
      addressLine2: shop.addressLine2,
      phoneNumber: shop.phoneNumber,
      upiId: shop.upiId,
      footerText: shop.footerText,
    );
  }

  Shop toEntity() => this;

  // SQLite serialization
  factory ShopModel.fromJson(Map<String, dynamic> json) =>
      _$ShopModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShopModelToJson(this);

  // SQLite database methods
  factory ShopModel.fromMap(Map<String, dynamic> map) {
    return ShopModel(
      name: map['name'] as String,
      addressLine1: map['addressLine1'] as String,
      addressLine2: map['addressLine2'] as String,
      phoneNumber: map['phoneNumber'] as String,
      upiId: map['upiId'] as String,
      footerText: map['footerText'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1, // Always use ID 1 for single shop record
      'name': name,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'phoneNumber': phoneNumber,
      'upiId': upiId,
      'footerText': footerText,
    };
  }
}
