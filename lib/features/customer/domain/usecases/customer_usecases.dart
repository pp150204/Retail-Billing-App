import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class GetCustomersUseCase {
  final CustomerRepository repository;
  GetCustomersUseCase(this.repository);

  Future<List<Customer>> execute() async {
    return await repository.getCustomers();
  }
}

class AddCustomerUseCase {
  final CustomerRepository repository;
  AddCustomerUseCase(this.repository);

  Future<void> execute(Customer customer) async {
    return await repository.addCustomer(customer);
  }
}

class UpdateCustomerUseCase {
  final CustomerRepository repository;
  UpdateCustomerUseCase(this.repository);

  Future<void> execute(Customer customer) async {
    return await repository.updateCustomer(customer);
  }
}

class DeleteCustomerUseCase {
  final CustomerRepository repository;
  DeleteCustomerUseCase(this.repository);

  Future<void> execute(String id) async {
    return await repository.deleteCustomer(id);
  }
}

class GetCustomerByPhoneUseCase {
  final CustomerRepository repository;
  GetCustomerByPhoneUseCase(this.repository);

  Future<Customer?> execute(String phone) async {
    return await repository.getCustomerByPhone(phone);
  }
}
