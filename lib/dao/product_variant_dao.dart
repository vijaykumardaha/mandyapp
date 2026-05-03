import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class ProductVariantDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertVariant(ProductVariant variant) async {
    variant.id = DBHelper.generateUuidInt();
    variant.updatedAt = DateTime.now().millisecondsSinceEpoch;
    variant.isDeleted = 0;
    variant.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.insert('product_variants', variant.toJson());
  }

  Future<List<ProductVariant>> getVariantsByProductId(int productId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'product_variants',
      where: 'product_id = ? AND is_deleted = ?',
      whereArgs: [productId, 0],
    );
    return List.generate(maps.length, (i) => ProductVariant.fromJson(maps[i]));
  }

  Future<int> updateVariant(ProductVariant variant) async {
    variant.updatedAt = DateTime.now().millisecondsSinceEpoch;
    variant.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.update(
      'product_variants',
      variant.toJson(),
      where: 'id = ?',
      whereArgs: [variant.id],
    );
  }

  Future<int> restoreVariant(int variantId) async {
    final db = await dbHelper.database;
    return await db.update(
      'product_variants',
      {
        'is_deleted': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [variantId],
    );
  }

  Future<ProductVariant?> getVariantById(int variantId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'product_variants',
      where: 'id = ? AND is_deleted = ?',
      whereArgs: [variantId, 0],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ProductVariant.fromJson(maps.first);
    }
    return null;
  }

  Future<List<ProductVariant>> getAllVariants() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'product_variants',
      where: 'is_deleted = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => ProductVariant.fromJson(maps[i]));
  }

  Future<int> deleteVariant(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'product_variants',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteVariantsByProductId(int productId) async {
    final db = await dbHelper.database;
    return await db.update(
      'product_variants',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }
}
