import 'package:mandyapp/models/product_stock_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class ProductStockDAO {
  final dbHelper = DBHelper.instance;

  Future<int> upsertStock(ProductStock stock) async {
    final db = await dbHelper.database;
    if (stock.id != null) {
      final data = stock.toJson();
      return db.update(
        'product_stocks',
        data,
        where: 'id = ?',
        whereArgs: [stock.id],
      );
    }
    stock.id = DBHelper.generateUuidInt();
    return db.insert('product_stocks', stock.toJson());
  }

  Future<List<ProductStock>> getStocks({int? customerId}) async {
    final db = await dbHelper.database;
    final whereClauses = <String>[];
    final args = <Object?>[];

    if (customerId != null) {
      whereClauses.add('customer_id = ?');
      args.add(customerId);
    }

    final maps = await db.query(
      'product_stocks',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'last_updated DESC',
    );
    return maps.map((m) => ProductStock.fromJson(m)).toList();
  }

  Future<ProductStock?> getStockForVariant({
    required int productId,
    required int variantId,
  }) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'product_stocks',
      where: 'product_id = ? AND variant_id = ? COLLATE NOCASE',
      whereArgs: [
        productId.toString(),
        variantId.toString(),
      ],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ProductStock.fromJson(maps.first);
  }

  Future<ProductStock?> getStockById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'product_stocks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ProductStock.fromJson(maps.first);
  }

  Future<int> deleteStock(int id) async {
    final db = await dbHelper.database;
    return db.delete(
      'product_stocks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearStocks() async {
    final db = await dbHelper.database;
    await db.delete('product_stocks');
  }
}
