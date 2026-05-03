import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class OrderItemDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertOrderItem(OrderItem orderItem) async {
    final db = await dbHelper.database;
    orderItem.id = DBHelper.generateUuidInt();
    orderItem.updatedAt = DateTime.now().millisecondsSinceEpoch;
    orderItem.isDeleted = 0;
    orderItem.syncStatus = 0;
    return db.insert('order_items', orderItem.toJson());
  }

  Future<int> updateOrderItem(OrderItem orderItem) async {
    final db = await dbHelper.database;
    final updatedOrderItem = orderItem.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      syncStatus: 0,
    );
    return db.update(
      'order_items',
      updatedOrderItem.toJson(),
      where: 'id = ?',
      whereArgs: [orderItem.id],
    );
  }

  Future<int> restoreOrderItem(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'order_items',
      {
        'is_deleted': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteOrderItem(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'order_items',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<OrderItem?> getOrderItemById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'order_items',
      where: 'id = ? AND is_deleted = ?',
      whereArgs: [id, 0],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return OrderItem.fromJson(maps.first);
  }

  Future<List<OrderItem>> getOrderItems({int? sellerId, int? productId, int? variantId, bool excludeOrderLinked = false}) async {
    final db = await dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    // Always exclude deleted items
    whereClauses.add('is_deleted = ?');
    whereArgs.add(0);

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
    if (excludeOrderLinked) {
      whereClauses.add('buyer_order_id IS NULL AND seller_order_id IS NULL');
    }

    final maps = await db.query(
      'order_items',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'updated_at DESC',
    );

    return maps.map(OrderItem.fromJson).toList();
  }

  Future<List<OrderItem>> getSellerOrderItems({required int sellerId }) async {
    final db = await dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    whereClauses.add('seller_id = ?');
    whereArgs.add(sellerId);

    whereClauses.add('seller_order_id IS NULL');
    whereClauses.add('is_deleted = ?');
    whereArgs.add(0);

    final maps = await db.query(
      'order_items',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'updated_at DESC',
    );

    return maps.map(OrderItem.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> getDailyOrderItemsReport({
    required DateTime startDate,
    required DateTime endDate,
    int? productId,
    int? categoryId,
  }) async {
    final db = await dbHelper.database;

    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    // Always exclude deleted items
    whereClauses.add('oi.is_deleted = ?');
    whereArgs.add(0);

    // Date range filter
    whereClauses.add('date(oi.updated_at) >= date(?)');
    whereArgs.add(startDate.toIso8601String().split('T')[0]);
    whereClauses.add('date(oi.updated_at) <= date(?)');
    whereArgs.add(endDate.toIso8601String().split('T')[0]);

    if (productId != null) {
      whereClauses.add('oi.product_id = ?');
      whereArgs.add(productId);
    }

    final query = '''
      SELECT
        date(oi.updated_at) as date,
        oi.product_id,
        oi.variant_id,
        pv.variant_name,
        pv.unit,
        SUM(oi.quantity) as total_quantity,
        COUNT(*) as transaction_count,
        SUM(oi.quantity * oi.selling_price) as total_revenue
      FROM order_items oi
      LEFT JOIN product_variants pv ON oi.variant_id = pv.id
      ${whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : ''}
      GROUP BY date(oi.updated_at), oi.product_id, oi.variant_id, pv.variant_name, pv.unit
      ORDER BY date DESC, total_revenue DESC
    ''';

    return db.rawQuery(query, whereArgs);
  }
}
