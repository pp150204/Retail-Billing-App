import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SqliteDatabase {
  static Database? _database;
  static const String _databaseName = 'billing_app.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String productTable = 'products';
  static const String shopTable = 'shop';
  static const String settingsTable = 'settings';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _databaseName);
    print("Database path: $path");

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Create products table
    await db.execute('''
      CREATE TABLE $productTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        barcode TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL
      )
    ''');

    // Create shop table
    await db.execute('''
      CREATE TABLE $shopTable (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        addressLine1 TEXT NOT NULL,
        addressLine2 TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        upiId TEXT NOT NULL,
        footerText TEXT NOT NULL
      )
    ''');

    // Create settings table (key-value store)
    await db.execute('''
      CREATE TABLE $settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> init() async {
    await database;
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
