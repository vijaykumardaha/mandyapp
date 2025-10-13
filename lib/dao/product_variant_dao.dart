import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class ProductVariantDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertVariant(ProductVariant variant) async {
    variant.id = DBHelper.generateUuidInt();
    final db = await dbHelper.database;
    return await db.insert('product_variants', variant.toJson());
  }

  Future<List<ProductVariant>> getVariantsByProductId(int productId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'product_variants',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return List.generate(maps.length, (i) => ProductVariant.fromJson(maps[i]));
  }

  Future<int> updateVariant(ProductVariant variant) async {
    final db = await dbHelper.database;
    return await db.update(
      'product_variants',
      variant.toJson(),
      where: 'id = ?',
      whereArgs: [variant.id],
    );
  }

  Future<int> deleteVariant(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'product_variants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteVariantsByProductId(int productId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'product_variants',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  Future<ProductVariant?> getVariantById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'product_variants',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ProductVariant.fromJson(maps.first);
  }
}
