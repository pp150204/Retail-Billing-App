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
}
