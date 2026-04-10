import '../entities/bill.dart';

abstract class BillRepository {
  Future<void> saveBill(Bill bill);
  Future<List<Bill>> getAllBills();
  Future<Map<String, dynamic>> getTodaySalesSummary();
}
