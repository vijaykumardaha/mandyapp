import 'package:mandyapp/models/order_payment_model.dart';
import 'package:mandyapp/utils/app_helper.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class OrderPaymentDAO {
  final dbHelper = DBHelper.instance;

  // Insert a new order payment
  Future<int> insertOrderPayment(OrderPayment payment) async {
    final db = await dbHelper.database;
    final mandyId = await AppHelper.getCurrentMandyId();
    final json = payment.toJson();
    json.remove('id');
    json['mandy_id'] = mandyId;
    return await db.insert('order_payments', json);
  }

  // Update an existing order payment
  Future<int> updateOrderPayment(OrderPayment payment) async {
    final db = await dbHelper.database;
    return await db.update(
      'order_payments',
      payment.toJson(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  // Delete an order payment
  Future<int> deleteOrderPayment(int id) async {
    final db = await dbHelper.database;
    return await db.delete('order_payments', where: 'id = ?', whereArgs: [id]);
  }

  // Get order payment by ID
  Future<OrderPayment?> getOrderPaymentById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return OrderPayment.fromJson(maps.first);
    }
    return null;
  }

  // Delete all payments for an order
  Future<int> deleteOrderPayments(int orderId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'order_payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  // Get all order payments
  Future<List<OrderPayment>> getAllOrderPayments() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OrderPayment.fromJson(maps[i]);
    });
  }

  // Get all payments for an order
  Future<List<OrderPayment>> getOrderPaymentsByOrderId(int orderId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OrderPayment.fromJson(maps[i]);
    });
  }

  // Get total payment amount for an order (sum of all payment amounts)
  Future<double> getTotalPaymentAmount(int orderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM order_payments WHERE order_id = ?',
      [orderId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get payment count for an order
  Future<int> getPaymentCount(int orderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM order_payments WHERE order_id = ?',
      [orderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get payments within date range
  Future<List<OrderPayment>> getPaymentsByDateRange(String startDate, String endDate) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OrderPayment.fromJson(maps[i]);
    });
  }

  // Get recent payments (last N payments)
  Future<List<OrderPayment>> getRecentPayments({int limit = 10}) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return OrderPayment.fromJson(maps[i]);
    });
  }

  // Get payments by source type
  Future<List<OrderPayment>> getPaymentsBySource(String source) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      where: 'source = ?',
      whereArgs: [source],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OrderPayment.fromJson(maps[i]);
    });
  }

  // Get total amount by source type for an order
  Future<double> getTotalAmountBySource(int orderId, String source) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM order_payments WHERE order_id = ? AND source = ?',
      [orderId, source],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get payment summary by source for an order
  Future<Map<String, double>> getPaymentSummaryBySource(int orderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT source, SUM(amount) as total FROM order_payments WHERE order_id = ? GROUP BY source',
      [orderId],
    );

    Map<String, double> summary = {};
    for (var row in result) {
      summary[row['source'] as String] = (row['total'] as num?)?.toDouble() ?? 0.0;
    }
    return summary;
  }

  // Bulk upsert order payments
  Future<void> bulkUpsertOrderPayments(List<OrderPayment> orderPayments) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final orderPayment in orderPayments) {
        batch.rawInsert('''
          INSERT INTO order_payments (
            order_id, source, amount, created_at
          )
          VALUES (?, ?, ?, ?)

          ON CONFLICT(id) DO UPDATE SET
            order_id = excluded.order_id,
            source = excluded.source,
            amount = excluded.amount,
            created_at = excluded.created_at

          WHERE excluded.created_at > order_payments.created_at;
        ''', [
          orderPayment.orderId,
          orderPayment.source,
          orderPayment.amount,
          orderPayment.createdAt,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }
}
