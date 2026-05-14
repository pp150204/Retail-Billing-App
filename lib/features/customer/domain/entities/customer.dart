import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final int points;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.points = 0,
  });

  @override
  List<Object> get props => [id, name, phone, points];

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    int? points,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      points: points ?? this.points,
    );
  }
}
