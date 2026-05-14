import '../../../../core/data/sqlite_database.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  @override
  Future<List<Customer>> getCustomers() async {
    final db = await SqliteDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      SqliteDatabase.customerTable,
      orderBy: 'name ASC',
    );
    return maps.map((map) => CustomerModel.fromMap(map)).toList();
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    final db = await SqliteDatabase.database;
    final model = CustomerModel.fromEntity(customer);
    await db.insert(
      SqliteDatabase.customerTable,
      model.toMap(),
    );
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    final db = await SqliteDatabase.database;
    final model = CustomerModel.fromEntity(customer);
    await db.update(
      SqliteDatabase.customerTable,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final db = await SqliteDatabase.database;
    await db.delete(
      SqliteDatabase.customerTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    final db = await SqliteDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      SqliteDatabase.customerTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CustomerModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<Customer?> getCustomerByPhone(String phone) async {
    final db = await SqliteDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      SqliteDatabase.customerTable,
      where: 'phone = ?',
      whereArgs: [phone],
    );
    if (maps.isNotEmpty) {
      return CustomerModel.fromMap(maps.first);
    }
    return null;
  }
}
