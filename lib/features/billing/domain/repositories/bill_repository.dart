import '../entities/bill.dart';

abstract class BillRepository {
  Future<void> saveBill(Bill bill);
  Future<List<Bill>> getAllBills();
  Future<Map<String, dynamic>> getTodaySalesSummary();
  Future<void> updateBillStatus(String billId, bool isPaid);
  Future<Map<String, dynamic>> getSalesAnalytics();
  Future<List<Bill>> getBillsByCustomerId(String customerId);
  
  // Advanced Analytics
  Future<Map<String, dynamic>> getDetailedAnalytics();
  Future<List<Map<String, dynamic>>> getRevenueStats(DateTime start, DateTime end);
  Future<List<Map<String, dynamic>>> getProductPerformance();
  Future<Map<String, dynamic>> getCustomerDetailedAnalytics(String customerId);
  Future<Map<String, dynamic>> getProductDetailedAnalytics(String productName);
  Future<List<Map<String, dynamic>>> getCustomerSpendingTrend(String customerId);
  
  // New Analytics for BI Upgrade
  Future<List<Map<String, dynamic>>> getCategoryPerformance();
  Future<List<Map<String, dynamic>>> getPaymentMethodDistribution();
  Future<List<Map<String, dynamic>>> getAverageOrderValueTrend();
  Future<Map<String, dynamic>> getCustomerRetentionStats();
  Future<Map<String, dynamic>> getInventoryHealth();
}
