import '../../domain/entities/bill.dart';
import '../../domain/entities/cart_item.dart';
import 'package:billing_app/features/product/data/models/product_model.dart';
import 'package:uuid/uuid.dart';

class BillModel extends Bill {
  const BillModel({
    required super.id,
    required super.billNumber,
    required super.totalAmount,
    required super.dateTime,
    required super.items,
    required super.isPaid,
    super.customerId,
  });

  factory BillModel.fromCartItems(List<CartItem> items, double totalAmount, {String? customerId}) {
    final now = DateTime.now();
    final billNumber = 'BILL-${now.millisecondsSinceEpoch}';
    return BillModel(
      id: const Uuid().v4(),
      billNumber: billNumber,
      totalAmount: totalAmount,
      dateTime: now,
      items: items,
      isPaid: true,
      customerId: customerId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billNumber': billNumber,
      'totalAmount': totalAmount,
      'dateTime': dateTime.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
      'customerId': customerId,
    };
  }

  factory BillModel.fromMap(Map<String, dynamic> map, List<CartItem> items) {
    return BillModel(
      id: map['id'],
      billNumber: map['billNumber'],
      totalAmount: map['totalAmount'],
      dateTime: DateTime.parse(map['dateTime']),
      items: items,
      isPaid: map['isPaid'] == 1,
      customerId: map['customerId'],
    );
  }

  @override
  BillModel copyWith({
    String? id,
    String? billNumber,
    double? totalAmount,
    DateTime? dateTime,
    List<CartItem>? items,
    bool? isPaid,
    String? customerId,
  }) {
    return BillModel(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      dateTime: dateTime ?? this.dateTime,
      items: items ?? this.items,
      isPaid: isPaid ?? this.isPaid,
      customerId: customerId ?? this.customerId,
    );
  }
}
