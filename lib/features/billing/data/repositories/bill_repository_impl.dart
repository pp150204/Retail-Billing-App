import 'package:sqflite/sqflite.dart';
import '../../../../core/data/sqlite_database.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/bill_repository.dart';
import '../models/bill_model.dart';
import '../../../product/domain/entities/product.dart';
import 'package:uuid/uuid.dart';

class BillRepositoryImpl implements BillRepository {
  @override
  Future<void> saveBill(Bill bill) async {
    final db = await SqliteDatabase.database;
    final billModel = BillModel(
      id: bill.id,
      billNumber: bill.billNumber,
      totalAmount: bill.totalAmount,
      dateTime: bill.dateTime,
      items: bill.items,
      isPaid: bill.isPaid,
      customerId: bill.customerId,
      paymentMethod: bill.paymentMethod,
    );

    await db.transaction((txn) async {
      // Save bill
      await txn.insert(SqliteDatabase.billTable, billModel.toMap());

      // Save order items
      for (var item in bill.items) {
        await txn.insert(SqliteDatabase.orderItemsTable, {
          'id': const Uuid().v4(),
          'billId': bill.id,
          'productId': item.product.id,
          'productName': item.product.name,
          'quantity': item.quantity,
          'price': item.product.price,
          'total': item.total,
        });

        // Update product stock
        await txn.rawUpdate(
          'UPDATE ${SqliteDatabase.productTable} SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.product.id],
        );
      }
    });
  }

  @override
  Future<List<Bill>> getAllBills() async {
    final db = await SqliteDatabase.database;
    final List<Map<String, dynamic>> billMaps = await db.query(
      SqliteDatabase.billTable,
      orderBy: 'dateTime DESC',
    );

    List<Bill> bills = [];
    for (var billMap in billMaps) {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        SqliteDatabase.orderItemsTable,
        where: 'billId = ?',
        whereArgs: [billMap['id']],
      );

      List<CartItem> items = itemMaps.map((itemMap) {
        return CartItem(
          product: Product(
            id: itemMap['productId'],
            name: itemMap['productName'],
            price: itemMap['price'],
            barcode: '', // Not needed for reporting
            stock: 0, // Not needed for reporting
            category: 'Uncategorized',
          ),
          quantity: itemMap['quantity'],
        );
      }).toList();

      bills.add(BillModel.fromMap(billMap, items));
    }
    return bills;
  }

  @override
  Future<Map<String, dynamic>> getTodaySalesSummary() async {
    final db = await SqliteDatabase.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    final tomorrow = DateTime(now.year, now.month, now.day + 1).toIso8601String();

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalOrders,
        SUM(totalAmount) as totalRevenue
      FROM ${SqliteDatabase.billTable}
      WHERE dateTime >= ? AND dateTime < ?
    ''', [today, tomorrow]);

    final List<Map<String, dynamic>> itemsResult = await db.rawQuery('''
      SELECT SUM(quantity) as itemsSold
      FROM ${SqliteDatabase.orderItemsTable}
      WHERE billId IN (
        SELECT id FROM ${SqliteDatabase.billTable}
        WHERE dateTime >= ? AND dateTime < ?
      )
    ''', [today, tomorrow]);

    return {
      'totalOrders': result[0]['totalOrders'] ?? 0,
      'totalRevenue': result[0]['totalRevenue'] ?? 0.0,
      'itemsSold': itemsResult[0]['itemsSold'] ?? 0,
    };
  }

  @override
  Future<void> updateBillStatus(String billId, bool isPaid) async {
    final db = await SqliteDatabase.database;
    await db.update(
      SqliteDatabase.billTable,
      {'isPaid': isPaid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [billId],
    );
  }

  @override
  Future<Map<String, dynamic>> getSalesAnalytics() async {
    final db = await SqliteDatabase.database;

    // Total stats
    final List<Map<String, dynamic>> totals = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalOrders,
        SUM(totalAmount) as totalRevenue,
        SUM(CASE WHEN isPaid = 0 THEN totalAmount ELSE 0 END) as unpaidAmount
      FROM ${SqliteDatabase.billTable}
    ''');

    // Top selling products
    final List<Map<String, dynamic>> topProducts = await db.rawQuery('''
      SELECT productName, SUM(quantity) as totalQty, SUM(total) as totalRevenue
      FROM ${SqliteDatabase.orderItemsTable}
      GROUP BY productName
      ORDER BY totalQty DESC
      LIMIT 5
    ''');

    return {
      'totalOrders': totals[0]['totalOrders'] ?? 0,
      'totalRevenue': totals[0]['totalRevenue'] ?? 0.0,
      'unpaidAmount': totals[0]['unpaidAmount'] ?? 0.0,
      'topProducts': topProducts,
    };
  }

  @override
  Future<List<Bill>> getBillsByCustomerId(String customerId) async {
    final db = await SqliteDatabase.database;
    final List<Map<String, dynamic>> billMaps = await db.query(
      SqliteDatabase.billTable,
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'dateTime DESC',
    );

    List<Bill> bills = [];
    for (var billMap in billMaps) {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        SqliteDatabase.orderItemsTable,
        where: 'billId = ?',
        whereArgs: [billMap['id']],
      );

      List<CartItem> items = itemMaps.map((itemMap) {
        return CartItem(
          product: Product(
            id: itemMap['productId'],
            name: itemMap['productName'],
            price: itemMap['price'],
            barcode: '',
            stock: 0,
            category: 'Uncategorized',
          ),
          quantity: itemMap['quantity'],
        );
      }).toList();

      bills.add(BillModel.fromMap(billMap, items));
    }
    return bills;
  }

  @override
  Future<Map<String, dynamic>> getDetailedAnalytics() async {
    final db = await SqliteDatabase.database;

    // 1. Core KPIs
    final List<Map<String, dynamic>> kpis = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalOrders,
        SUM(totalAmount) as totalRevenue,
        AVG(totalAmount) as avgOrderValue,
        SUM(CASE WHEN isPaid = 0 THEN totalAmount ELSE 0 END) as unpaidAmount
      FROM ${SqliteDatabase.billTable}
    ''');

    // 2. Top Products by Revenue
    final List<Map<String, dynamic>> topProducts = await db.rawQuery('''
      SELECT productName, SUM(quantity) as totalQty, SUM(total) as totalRevenue
      FROM ${SqliteDatabase.orderItemsTable}
      GROUP BY productName
      ORDER BY totalRevenue DESC
      LIMIT 10
    ''');

    // 3. Peak Sales Hours
    final List<Map<String, dynamic>> hourlyStats = await db.rawQuery('''
      SELECT STRFTIME('%H', dateTime) as hour, COUNT(*) as orderCount
      FROM ${SqliteDatabase.billTable}
      GROUP BY hour
      ORDER BY hour ASC
    ''');

    // 4. Additional Metrics
    final List<Map<String, dynamic>> additional = await db.rawQuery('''
      SELECT 
        SUM(quantity) as totalItemsSold,
        (SELECT COUNT(*) FROM ${SqliteDatabase.customerTable}) as totalCustomers
      FROM ${SqliteDatabase.orderItemsTable}
    ''');

    final double totalRevenue = kpis[0]['totalRevenue'] ?? 0.0;
    // Assume a 25% margin for estimate
    final double profitEstimate = totalRevenue * 0.25;

    return {
      'totalOrders': kpis[0]['totalOrders'] ?? 0,
      'totalRevenue': totalRevenue,
      'avgOrderValue': kpis[0]['avgOrderValue'] ?? 0.0,
      'unpaidAmount': kpis[0]['unpaidAmount'] ?? 0.0,
      'profitEstimate': profitEstimate,
      'totalItemsSold': additional[0]['totalItemsSold'] ?? 0,
      'totalCustomers': additional[0]['totalCustomers'] ?? 0,
      'topProducts': topProducts,
      'hourlyStats': hourlyStats,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getRevenueStats(DateTime start, DateTime end) async {
    final db = await SqliteDatabase.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        DATE(dateTime) as date, 
        SUM(totalAmount) as dailyRevenue
      FROM ${SqliteDatabase.billTable}
      WHERE dateTime >= ? AND dateTime <= ?
      GROUP BY date
      ORDER BY date ASC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getProductPerformance() async {
    final db = await SqliteDatabase.database;
    return await db.rawQuery('''
      SELECT 
        productName, 
        SUM(quantity) as unitsSold, 
        SUM(total) as revenue,
        (SELECT stock FROM ${SqliteDatabase.productTable} WHERE name = productName) as currentStock
      FROM ${SqliteDatabase.orderItemsTable}
      GROUP BY productName
      ORDER BY unitsSold DESC
    ''');
  }

  @override
  Future<Map<String, dynamic>> getCustomerDetailedAnalytics(String customerId) async {
    final db = await SqliteDatabase.database;
    
    // 1. Core stats
    final List<Map<String, dynamic>> stats = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalVisits,
        SUM(totalAmount) as totalSpend,
        AVG(totalAmount) as avgSpend,
        MAX(dateTime) as lastVisit
      FROM ${SqliteDatabase.billTable}
      WHERE customerId = ?
    ''', [customerId]);

    // 2. Favorite items
    final List<Map<String, dynamic>> favorites = await db.rawQuery('''
      SELECT productName, SUM(quantity) as totalQty
      FROM ${SqliteDatabase.orderItemsTable}
      WHERE billId IN (SELECT id FROM ${SqliteDatabase.billTable} WHERE customerId = ?)
      GROUP BY productName
      ORDER BY totalQty DESC
      LIMIT 3
    ''', [customerId]);

    return {
      'totalVisits': stats[0]['totalVisits'] ?? 0,
      'totalSpend': stats[0]['totalSpend'] ?? 0.0,
      'avgSpend': stats[0]['avgSpend'] ?? 0.0,
      'lastVisit': stats[0]['lastVisit'],
      'favorites': favorites,
    };
  }

  @override
  Future<Map<String, dynamic>> getProductDetailedAnalytics(String productName) async {
    final db = await SqliteDatabase.database;

    // 1. Sales trend (last 30 days)
    final List<Map<String, dynamic>> trend = await db.rawQuery('''
      SELECT 
        DATE(b.dateTime) as date, 
        SUM(oi.quantity) as qty
      FROM ${SqliteDatabase.orderItemsTable} oi
      JOIN ${SqliteDatabase.billTable} b ON oi.billId = b.id
      WHERE oi.productName = ?
      GROUP BY date
      ORDER BY date ASC
      LIMIT 30
    ''', [productName]);

    // 2. Peak selling hours
    final List<Map<String, dynamic>> hours = await db.rawQuery('''
      SELECT STRFTIME('%H', b.dateTime) as hour, SUM(oi.quantity) as qty
      FROM ${SqliteDatabase.orderItemsTable} oi
      JOIN ${SqliteDatabase.billTable} b ON oi.billId = b.id
      WHERE oi.productName = ?
      GROUP BY hour
      ORDER BY qty DESC
      LIMIT 1
    ''', [productName]);

    return {
      'trend': trend,
      'peakHour': hours.isNotEmpty ? hours[0]['hour'] : null,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerSpendingTrend(String customerId) async {
    final db = await SqliteDatabase.database;
    return await db.rawQuery('''
      SELECT 
        DATE(dateTime) as date, 
        SUM(totalAmount) as spend
      FROM ${SqliteDatabase.billTable}
      WHERE customerId = ?
      GROUP BY date
      ORDER BY date ASC
      LIMIT 10
    ''', [customerId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getCategoryPerformance() async {
    final db = await SqliteDatabase.database;
    return await db.rawQuery('''
      SELECT p.category, SUM(oi.quantity) as totalQty, SUM(oi.total) as totalRevenue
      FROM ${SqliteDatabase.orderItemsTable} oi
      JOIN ${SqliteDatabase.productTable} p ON oi.productId = p.id
      GROUP BY p.category
      ORDER BY totalRevenue DESC
    ''');
  }

  @override
  Future<List<Map<String, dynamic>>> getPaymentMethodDistribution() async {
    final db = await SqliteDatabase.database;
    return await db.rawQuery('''
      SELECT paymentMethod, COUNT(*) as count, SUM(totalAmount) as totalRevenue
      FROM ${SqliteDatabase.billTable}
      GROUP BY paymentMethod
    ''');
  }

  @override
  Future<List<Map<String, dynamic>>> getAverageOrderValueTrend() async {
    final db = await SqliteDatabase.database;
    return await db.rawQuery('''
      SELECT DATE(dateTime) as date, AVG(totalAmount) as avgAOV
      FROM ${SqliteDatabase.billTable}
      GROUP BY date
      ORDER BY date ASC
      LIMIT 30
    ''');
  }

  @override
  Future<Map<String, dynamic>> getCustomerRetentionStats() async {
    final db = await SqliteDatabase.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM (SELECT customerId FROM ${SqliteDatabase.billTable} WHERE customerId IS NOT NULL GROUP BY customerId HAVING COUNT(*) = 1)) as newCustomers,
        (SELECT COUNT(*) FROM (SELECT customerId FROM ${SqliteDatabase.billTable} WHERE customerId IS NOT NULL GROUP BY customerId HAVING COUNT(*) > 1)) as repeatCustomers
    ''');
    return {
      'newCustomers': result[0]['newCustomers'] ?? 0,
      'repeatCustomers': result[0]['repeatCustomers'] ?? 0,
    };
  }

  @override
  Future<Map<String, dynamic>> getInventoryHealth() async {
    final db = await SqliteDatabase.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        SUM(stock * price) as totalStockValue,
        COUNT(CASE WHEN stock <= 5 THEN 1 END) as lowStockCount,
        COUNT(*) as totalProducts
      FROM ${SqliteDatabase.productTable}
    ''');
    return {
      'totalStockValue': result[0]['totalStockValue'] ?? 0.0,
      'lowStockCount': result[0]['lowStockCount'] ?? 0,
      'totalProducts': result[0]['totalProducts'] ?? 0,
    };
  }
}
