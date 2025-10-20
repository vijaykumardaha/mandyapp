import 'package:mandyapp/models/item_sale_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class ItemSaleDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertItemSale(ItemSale sale) async {
    final db = await dbHelper.database;
    sale.id = DBHelper.generateUuidInt();
    final now = DateTime.now().toIso8601String();
    sale.createdAt = now;
    sale.updatedAt = now;
    return db.insert('item_sales', sale.toJson());
  }

  Future<int> updateItemSale(ItemSale sale) async {
    final db = await dbHelper.database;
    final updatedSale = sale.copyWith(updatedAt: DateTime.now().toIso8601String());
    return db.update(
      'item_sales',
      updatedSale.toJson(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<int> deleteItemSale(int id) async {
    final db = await dbHelper.database;
    return db.delete(
      'item_sales',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ItemSale?> getItemSaleById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'item_sales',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return ItemSale.fromJson(maps.first);
  }

  Future<List<ItemSale>> getItemSales({int? sellerId, int? productId, int? variantId, bool excludeCartLinked = false}) async {
    final db = await dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (sellerId != null) {
      whereClauses.add('seller_id = ?');
      whereArgs.add(sellerId);
    }
    if (productId != null) {
      whereClauses.add('product_id = ?');
      whereArgs.add(productId);
    }
    if (variantId != null) {
      whereClauses.add('variant_id = ?');
      whereArgs.add(variantId);
    }
    if (excludeCartLinked) {
      whereClauses.add('buyer_cart_id IS NULL AND seller_cart_id IS NULL');
    }

    final maps = await db.query(
      'item_sales',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps.map(ItemSale.fromJson).toList();
  }
}
