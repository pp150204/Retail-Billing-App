import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SqliteDatabase {
  static Database? _database;
  static const String _databaseName = 'billing_app.db';
  static const int _databaseVersion = 5;

  // Table names
  static const String productTable = 'products';
  static const String shopTable = 'shop';
  static const String settingsTable = 'settings';
  static const String billTable = 'bills';
  static const String orderItemsTable = 'order_items';

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
      onUpgrade: _onUpgrade,
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
        stock INTEGER NOT NULL,
        expiryDate TEXT
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
        footerText TEXT NOT NULL,
        logoPath TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Create settings table (key-value store)
    await db.execute('''
      CREATE TABLE $settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create bills table
    await db.execute('''
      CREATE TABLE $billTable (
        id TEXT PRIMARY KEY,
        billNumber TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        dateTime TEXT NOT NULL,
        isPaid INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create order_items table
    await db.execute('''
      CREATE TABLE $orderItemsTable (
        id TEXT PRIMARY KEY,
        billId TEXT NOT NULL,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (billId) REFERENCES $billTable (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add expiryDate column to products table
      await db.execute('''
        ALTER TABLE $productTable ADD COLUMN expiryDate TEXT
      ''');
    }
    if (oldVersion < 3) {
      // Create bills table
      await db.execute('''
        CREATE TABLE $billTable (
          id TEXT PRIMARY KEY,
          billNumber TEXT NOT NULL,
          totalAmount REAL NOT NULL,
          dateTime TEXT NOT NULL,
          isPaid INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // Create order_items table
      await db.execute('''
        CREATE TABLE $orderItemsTable (
          id TEXT PRIMARY KEY,
          billId TEXT NOT NULL,
          productId TEXT NOT NULL,
          productName TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          price REAL NOT NULL,
          total REAL NOT NULL,
          FOREIGN KEY (billId) REFERENCES $billTable (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add logoPath column to shop table
      await db.execute('''
        ALTER TABLE $shopTable ADD COLUMN logoPath TEXT NOT NULL DEFAULT ''
      ''');
    }
    if (oldVersion < 5) {
      // Add isPaid column to bills table
      await db.execute('''
        ALTER TABLE $billTable ADD COLUMN isPaid INTEGER NOT NULL DEFAULT 1
      ''');
    }
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
