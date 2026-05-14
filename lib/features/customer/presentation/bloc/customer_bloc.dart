import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/customer_usecases.dart';

// Events
abstract class CustomerEvent extends Equatable {
  const CustomerEvent();
  @override
  List<Object?> get props => [];
}

class LoadCustomersEvent extends CustomerEvent {}

class SearchCustomersEvent extends CustomerEvent {
  final String query;
  const SearchCustomersEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class AddCustomerEvent extends CustomerEvent {
  final Customer customer;
  const AddCustomerEvent(this.customer);
  @override
  List<Object?> get props => [customer];
}

class UpdateCustomerEvent extends CustomerEvent {
  final Customer customer;
  const UpdateCustomerEvent(this.customer);
  @override
  List<Object?> get props => [customer];
}

class DeleteCustomerEvent extends CustomerEvent {
  final String id;
  const DeleteCustomerEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// States
enum CustomerStatus { initial, loading, loaded, error }

class CustomerState extends Equatable {
  final CustomerStatus status;
  final List<Customer> customers;
  final List<Customer> filteredCustomers;
  final String? error;

  const CustomerState({
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.filteredCustomers = const [],
    this.error,
  });

  CustomerState copyWith({
    CustomerStatus? status,
    List<Customer>? customers,
    List<Customer>? filteredCustomers,
    String? error,
  }) {
    return CustomerState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, customers, filteredCustomers, error];
}

// Bloc
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final GetCustomersUseCase getCustomersUseCase;
  final AddCustomerUseCase addCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeleteCustomerUseCase deleteCustomerUseCase;

  CustomerBloc({
    required this.getCustomersUseCase,
    required this.addCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deleteCustomerUseCase,
  }) : super(const CustomerState()) {
    on<LoadCustomersEvent>(_onLoadCustomers);
    on<SearchCustomersEvent>(_onSearchCustomers);
    on<AddCustomerEvent>(_onAddCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
  }

  Future<void> _onLoadCustomers(
      LoadCustomersEvent event, Emitter<CustomerState> emit) async {
    emit(state.copyWith(status: CustomerStatus.loading));
    try {
      final customers = await getCustomersUseCase.execute();
      emit(state.copyWith(
        status: CustomerStatus.loaded,
        customers: customers,
        filteredCustomers: customers,
      ));
    } catch (e) {
      emit(state.copyWith(status: CustomerStatus.error, error: e.toString()));
    }
  }

  void _onSearchCustomers(
      SearchCustomersEvent event, Emitter<CustomerState> emit) {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredCustomers: state.customers));
    } else {
      final filtered = state.customers
          .where((c) =>
              c.name.toLowerCase().contains(event.query.toLowerCase()) ||
              c.phone.contains(event.query))
          .toList();
      emit(state.copyWith(filteredCustomers: filtered));
    }
  }

  Future<void> _onAddCustomer(
      AddCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      await addCustomerUseCase.execute(event.customer);
      add(LoadCustomersEvent());
    } catch (e) {
      emit(state.copyWith(status: CustomerStatus.error, error: e.toString()));
    }
  }

  Future<void> _onUpdateCustomer(
      UpdateCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      await updateCustomerUseCase.execute(event.customer);
      add(LoadCustomersEvent());
    } catch (e) {
      emit(state.copyWith(status: CustomerStatus.error, error: e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(
      DeleteCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      await deleteCustomerUseCase.execute(event.id);
      add(LoadCustomersEvent());
    } catch (e) {
      emit(state.copyWith(status: CustomerStatus.error, error: e.toString()));
    }
  }
}
