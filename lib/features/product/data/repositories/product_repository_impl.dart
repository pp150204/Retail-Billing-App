import 'package:fpdart/fpdart.dart';
import '../../../../core/data/sqlite_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final db = await SqliteDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        SqliteDatabase.productTable,
      );
      final products =
          maps.map((map) => ProductModel.fromMap(map)).toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final db = await SqliteDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        SqliteDatabase.productTable,
        where: 'barcode = ?',
        whereArgs: [barcode],
      );

      if (maps.isEmpty) {
        return Left(CacheFailure('Product not found'));
      }

      final product = ProductModel.fromMap(maps.first);
      return Right(product);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      final db = await SqliteDatabase.database;
      final model = ProductModel.fromEntity(product);
      await db.insert(
        SqliteDatabase.productTable,
        model.toMap(),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      final db = await SqliteDatabase.database;
      final model = ProductModel.fromEntity(product);
      await db.update(
        SqliteDatabase.productTable,
        model.toMap(),
        where: 'id = ?',
        whereArgs: [model.id],
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      final db = await SqliteDatabase.database;
      await db.delete(
        SqliteDatabase.productTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
