import 'package:fpdart/fpdart.dart';
import '../../../../core/data/sqlite_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shop_repository.dart';
import '../models/shop_model.dart';

class ShopRepositoryImpl implements ShopRepository {
  static const int shopId = 1; // Single shop record

  @override
  Future<Either<Failure, Shop>> getShop() async {
    try {
      final db = await SqliteDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        SqliteDatabase.shopTable,
        where: 'id = ?',
        whereArgs: [shopId],
      );

      if (maps.isNotEmpty) {
        final shop = ShopModel.fromMap(maps.first);
        return Right(shop);
      } else {
        // Return default shop if not found
        return const Right(Shop(
            name: 'Mega Mart',
            addressLine1: 'Kolhapur, Maharashtra',
            addressLine2: '-636453',
            phoneNumber: '+919579690200',
            upiId: 'prathmesh@oksbi',
            footerText: 'Thank you, Visit again!!!'));
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateShop(Shop shop) async {
    try {
      final db = await SqliteDatabase.database;
      final model = ShopModel.fromEntity(shop);

      // Check if shop exists
      final List<Map<String, dynamic>> existing = await db.query(
        SqliteDatabase.shopTable,
        where: 'id = ?',
        whereArgs: [shopId],
      );

      if (existing.isEmpty) {
        // Insert if doesn't exist
        await db.insert(
          SqliteDatabase.shopTable,
          model.toMap(),
        );
      } else {
        // Update if exists
        await db.update(
          SqliteDatabase.shopTable,
          model.toMap(),
          where: 'id = ?',
          whereArgs: [shopId],
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
