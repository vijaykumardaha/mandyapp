import 'package:mandyapp/models/order_payment_model.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class OrderPaymentDAO {
  final dbHelper = DBHelper.instance;

  // Insert a new order payment
  Future<int> insertOrderPayment(OrderPayment payment) async {
    final db = await dbHelper.database;
    return await db.insert('order_payments', payment.toJson());
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

  // Get order payment by order ID (summary)
  Future<OrderPayment?> getOrderPaymentByOrderId(int orderId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    if (maps.isNotEmpty) {
      return OrderPayment.fromJson(maps.first);
    }
    return null;
  }

  // Get total payment amount for an order
  Future<double> getTotalPaymentAmount(int orderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(cash_amount + upi_amount + card_amount) as total FROM order_payments WHERE order_id = ?',
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

  // Get payments with pending amounts
  Future<List<OrderPayment>> getPaymentsWithPending() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      where: 'pending_amount > 0 OR pending_payment > 0',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OrderPayment.fromJson(maps[i]);
    });
  }
}
