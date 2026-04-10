part of 'billing_bloc.dart';

class BillingState extends Equatable {
  final List<CartItem> cartItems;
  final String? error;
  final bool isPrinting;
  final bool printSuccess;
  final double todayRevenue;
  final int todayOrdersCount;
  final int todayItemsSold;

  const BillingState({
    this.cartItems = const [],
    this.error,
    this.isPrinting = false,
    this.printSuccess = false,
    this.todayRevenue = 0.0,
    this.todayOrdersCount = 0,
    this.todayItemsSold = 0,
  });

  double get totalAmount => cartItems.fold(0, (sum, item) => sum + item.total);

  BillingState copyWith({
    List<CartItem>? cartItems,
    String? error,
    bool clearError = false,
    bool? isPrinting,
    bool? printSuccess,
    double? todayRevenue,
    int? todayOrdersCount,
    int? todayItemsSold,
  }) {
    return BillingState(
      cartItems: cartItems ?? this.cartItems,
      error: clearError ? null : (error ?? this.error),
      isPrinting: isPrinting ?? this.isPrinting,
      printSuccess: printSuccess ?? this.printSuccess,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      todayOrdersCount: todayOrdersCount ?? this.todayOrdersCount,
      todayItemsSold: todayItemsSold ?? this.todayItemsSold,
    );
  }

  @override
  List<Object?> get props => [
        cartItems,
        error,
        isPrinting,
        printSuccess,
        todayRevenue,
        todayOrdersCount,
        todayItemsSold
      ];
}
