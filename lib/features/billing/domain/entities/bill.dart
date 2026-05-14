import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class Bill extends Equatable {
  final String id;
  final String billNumber;
  final double totalAmount;
  final DateTime dateTime;
  final List<CartItem> items;
  final bool isPaid;
  final String? customerId;

  const Bill({
    required this.id,
    required this.billNumber,
    required this.totalAmount,
    required this.dateTime,
    required this.items,
    this.isPaid = true,
    this.customerId,
  });

  @override
  List<Object?> get props =>
      [id, billNumber, totalAmount, dateTime, items, isPaid, customerId];

  Bill copyWith({
    String? id,
    String? billNumber,
    double? totalAmount,
    DateTime? dateTime,
    List<CartItem>? items,
    bool? isPaid,
    String? customerId,
  }) {
    return Bill(
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
