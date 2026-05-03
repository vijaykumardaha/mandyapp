import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class OrderDAO {
  final dbHelper = DBHelper.instance;

  // Insert a new order
  Future<int> insertOrder(Order order) async {
    final db = await dbHelper.database;
    order.updatedAt = DateTime.now().millisecondsSinceEpoch;
    order.isDeleted = 0;
    order.syncStatus = 0;
    return await db.insert('orders', order.toJson());
  }

  // Update an existing order
  Future<int> updateOrder(Order order) async {
    order.updatedAt = DateTime.now().millisecondsSinceEpoch;
    order.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.update(
      'orders',
      order.toJson(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> restoreOrder(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'orders',
      {
        'is_deleted': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete an order
  Future<int> deleteOrder(int id) async {
    // Soft delete order and its items
    final db = await dbHelper.database;
    final order = await getOrderById(id);
    if (order != null) {
      // Soft delete all order-linked order items first
      await db.update(
        'order_items',
        {
          'is_deleted': 1,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: '${order.orderFor == 'seller' ? 'seller_order_id' : 'buyer_order_id'} = ?',
        whereArgs: [id],
      );
      // Then soft delete the order
      return await db.update(
        'orders',
        {
          'is_deleted': 1,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  // Get order by ID
  Future<Order?> getOrderById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'id = ? AND is_deleted = ?',
      whereArgs: [id, 0],
    );

    if (maps.isNotEmpty) {
      return Order.fromJson(maps.first);
    }
    return null;
  }

  // Get all orders
  Future<List<Order>> getAllOrders() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Order.fromJson(maps[i]);
    });
  }

  // Get orders by user ID
  Future<List<Order>> getOrdersByCustomer(int customerId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at ASC',
    );

    // Load items for each order
    List<Order> orders = [];
    for (var map in maps) {
      final order = Order.fromJson(map);
      final items = await getOrderItems(order.id!, orderFor: order.orderFor);
      orders.add(order.copyWith(id: order.id!, items: items, orderFor: order.orderFor));
    }
    return orders;
  }

  // Get open order for user
  Future<Order?> getOpenOrderForCustomer(int customerId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'customer_id = ? AND status = ?',
      whereArgs: [customerId, 'open'],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final order = Order.fromJson(maps.first);
      // Load items for this order
      final items = await getOrderItems(order.id!, orderFor: order.orderFor);
      return order.copyWith(items: items, id: DBHelper.generateUuidInt(), orderFor: order.orderFor);
    }
    return null;
  }

  // Get order with items
  Future<Order?> getOrderWithItems(int orderId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );

    if (orderMaps.isNotEmpty) {
      final order = Order.fromJson(orderMaps.first);
      final items = await getOrderItems(orderId, orderFor: order.orderFor);
      return Order.fromJson(orderMaps.first, items: items);
    }
    return null;
  }

  // Update order status
  Future<int> updateOrderStatus(int orderId, String status) async {
    final db = await dbHelper.database;
    return await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // === Order OrderItem Methods ===

  // Insert an order item sale
  Future<int> insertOrderItem(OrderItem item) async {
    final db = await dbHelper.database;
    final prepared = item.copyWith(
      id: item.id ?? DBHelper.generateUuidInt(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isDeleted: 0,
      syncStatus: 0,
    );
    return await db.insert('order_items', prepared.toJson());
  }

  // Update an order item sale
  Future<int> updateOrderItem(OrderItem item) async {
    final db = await dbHelper.database;
    final updated = item.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      syncStatus: 0,
    );
    return await db.update(
      'order_items',
      updated.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
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

  // Delete an order item sale
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

  // Get order item sale by ID
  Future<OrderItem?> getOrderItem(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_items',
      where: 'id = ? AND is_deleted = ?',
      whereArgs: [id, 0],
    );

    if (maps.isNotEmpty) {
      return OrderItem.fromJson(maps.first);
    }
    return null;
  }

  // Get all item sales for an order
  Future<List<OrderItem>> getOrderItems(
    int orderId, {
    String? orderFor,
  }) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        oi.id,
        oi.mandy_id,
        oi.seller_id,
        oi.buyer_order_id,
        oi.seller_order_id,
        oi.buyer_id,
        oi.product_id,
        oi.variant_id,
        oi.buying_price,
        oi.selling_price,
        oi.quantity,
        oi.unit,
        oi.updated_at,
        oi.is_deleted,
        oi.sync_status,
        pv.variant_name,
        pv.image_path
      FROM order_items oi
      LEFT JOIN product_variants pv ON oi.variant_id = pv.id
      WHERE (${orderFor == 'seller' ? 'oi.seller_order_id' : 'oi.buyer_order_id'} = ? AND oi.is_deleted = ?)
      ORDER BY oi.updated_at ASC
    ''', [orderId, 0]);

    return maps.map(OrderItem.fromJson).toList();
  }

  // Clear all item sales from an order
  Future<int> clearOrder(int orderId) async {
    final db = await dbHelper.database;
    final order = await getOrderById(orderId);
    return await db.update(
      'order_items',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: '${order?.orderFor == 'seller' ? 'seller_order_id' : 'buyer_order_id'} = ?',
      whereArgs: [orderId],
    );
  }

  // Get order item sale by product ID (when variant not specified)
  Future<OrderItem?> getOrderItemByProduct(int orderId, int productId) async {
    final db = await dbHelper.database;
    final order = await getOrderById(orderId);
    final List<Map<String, dynamic>> maps = await db.query(
      'order_items',
      where: '${order?.orderFor == 'seller' ? 'seller_order_id' : 'buyer_order_id'} = ? AND product_id = ? AND variant_id IS NULL AND is_deleted = ?',
      whereArgs: [orderId, productId, 0],
    );

    if (maps.isNotEmpty) {
      return OrderItem.fromJson(maps.first);
    }
    return null;
  }

  // Get order item sale by variant ID
  Future<OrderItem?> getOrderItemByVariant(int orderId, int variantId) async {
    final db = await dbHelper.database;
    final order = await getOrderById(orderId);
    final List<Map<String, dynamic>> maps = await db.query(
      'order_items',
      where: '${order?.orderFor == 'seller' ? 'seller_order_id' : 'buyer_order_id'} = ? AND variant_id = ? AND is_deleted = ?',
      whereArgs: [orderId, variantId, 0],
    );

    if (maps.isNotEmpty) {
      return OrderItem.fromJson(maps.first);
    }
    return null;
  }

  // Get total items count in order
  Future<int> getOrderItemCount(int orderId) async {
    final db = await dbHelper.database;
    final order = await getOrderById(orderId);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM order_items WHERE ${order?.orderFor == 'seller' ? 'seller_order_id' : 'buyer_order_id'} = ? AND is_deleted = ?',
      [orderId, 0],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

}
