import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../../core/data/sqlite_database.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../domain/repositories/printer_repository.dart';
import 'package:sqflite/sqflite.dart';

class PrinterRepositoryImpl implements PrinterRepository {
  final PrinterHelper _printerHelper = PrinterHelper();

  @override
  Future<List<BluetoothInfo>> scanDevices() async {
    if (await _printerHelper.checkPermission()) {
      return await _printerHelper.getBondedDevices();
    }
    throw Exception('Bluetooth permission denied');
  }

  @override
  Future<bool> connect(String macAddress) async {
    return await _printerHelper.connect(macAddress);
  }

  @override
  Future<bool> disconnect() async {
    return await _printerHelper.disconnect();
  }

  @override
  Future<String?> getSavedPrinterMac() async {
    return await _getSetting('printer_mac');
  }

  @override
  Future<String?> getSavedPrinterName() async {
    return await _getSetting('printer_name');
  }

  @override
  Future<void> savePrinterData(String mac, String name) async {
    await _saveSetting('printer_mac', mac);
    await _saveSetting('printer_name', name);
  }

  @override
  Future<void> clearPrinterData() async {
    await _deleteSetting('printer_mac');
    await _deleteSetting('printer_name');
  }

  @override
  Future<void> testPrint(String shopName) async {
    await _printerHelper
        .printText("Test Print\n\n$shopName\n\n----------------\n\n");
  }

  // Helper methods for settings table
  Future<void> _saveSetting(String key, String value) async {
    final db = await SqliteDatabase.database;
    await db.insert(
      SqliteDatabase.settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> _getSetting(String key) async {
    final db = await SqliteDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      SqliteDatabase.settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<void> _deleteSetting(String key) async {
    final db = await SqliteDatabase.database;
    await db.delete(
      SqliteDatabase.settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
  }
}
