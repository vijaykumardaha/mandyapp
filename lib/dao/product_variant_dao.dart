import 'package:krishimandi/models/product_variant_model.dart';
import 'package:krishimandi/utils/app_helper.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/utils/db_helper.dart';

class ProductVariantDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertVariant(ProductVariant variant) async {
    variant.id = DBHelper.generateUuidInt();
    variant.mandiId = await AppHelper.getCurrentMandiId();
    variant.updatedAt = DateTime.now().millisecondsSinceEpoch;
    variant.isDeleted = 0;
    variant.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.insert(DbTables.productVariants, variant.toJson());
  }

  Future<List<ProductVariant>> getVariantsByProductId(int productId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.productVariants,
      where: 'product_id = ? AND is_deleted = ?',
      whereArgs: [productId, 0],
    );
    return List.generate(maps.length, (i) => ProductVariant.fromJson(maps[i]));
  }

  Future<int> updateVariant(ProductVariant variant) async {
    variant.updatedAt = DateTime.now().millisecondsSinceEpoch;
    variant.isDeleted = 0;
    variant.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.update(
      DbTables.productVariants,
      variant.toJson(),
      where: 'id = ?',
      whereArgs: [variant.id],
    );
  }

  Future<int> restoreVariant(int variantId) async {
    final db = await dbHelper.database;
    return await db.update(
      DbTables.productVariants,
      {
        'is_deleted': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [variantId],
    );
  }

  Future<ProductVariant?> getVariantById(int variantId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.productVariants,
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
      DbTables.productVariants,
      where: 'is_deleted = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => ProductVariant.fromJson(maps[i]));
  }

  Future<int> deleteVariant(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      DbTables.productVariants,
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteVariantsByProductId(int productId) async {
    final db = await dbHelper.database;
    return await db.update(
      DbTables.productVariants,
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  // Bulk upsert product variants
  Future<void> bulkUpsertVariants(List<ProductVariant> variants) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final variant in variants) {
        batch.rawInsert('''
          INSERT INTO ${DbTables.productVariants} (
            id, mandi_id, product_id, variant_name, selling_price,
            quantity, unit, image_path, updated_at, is_deleted, sync_status
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

          ON CONFLICT(id) DO UPDATE SET
            mandi_id = excluded.mandi_id,
            product_id = excluded.product_id,
            variant_name = excluded.variant_name,
            selling_price = excluded.selling_price,
            quantity = excluded.quantity,
            unit = excluded.unit,
            image_path = excluded.image_path,
            updated_at = excluded.updated_at,
            is_deleted = excluded.is_deleted,
            sync_status = excluded.sync_status

          WHERE excluded.updated_at > ${DbTables.productVariants}.updated_at;
        ''', [
          variant.id,
          variant.mandiId,
          variant.productId,
          variant.variantName,
          variant.sellingPrice,
          variant.quantity,
          variant.unit,
          variant.imagePath,
          variant.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
          variant.isDeleted ?? 0,
          1,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }
}
