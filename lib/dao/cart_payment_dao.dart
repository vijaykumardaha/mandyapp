import 'package:mandyapp/models/cart_payment_model.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class CartPaymentDAO {
  final dbHelper = DBHelper.instance;

  // Insert a new cart payment
  Future<int> insertCartPayment(CartPayment payment) async {
    final db = await dbHelper.database;
    return await db.insert('cart_payments', payment.toJson());
  }

  // Update an existing cart payment
  Future<int> updateCartPayment(CartPayment payment) async {
    final db = await dbHelper.database;
    return await db.update(
      'cart_payments',
      payment.toJson(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  // Delete a cart payment
  Future<int> deleteCartPayment(int id) async {
    final db = await dbHelper.database;
    return await db.delete('cart_payments', where: 'id = ?', whereArgs: [id]);
  }

  // Get cart payment by ID
  Future<CartPayment?> getCartPaymentById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_payments',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return CartPayment.fromJson(maps.first);
    }
    return null;
  }

  // Get all cart payments
  Future<List<CartPayment>> getAllCartPayments() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_payments',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return CartPayment.fromJson(maps[i]);
    });
  }

  // Get cart payment by cart ID (summary)
  Future<CartPayment?> getCartPaymentByCartId(int cartId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_payments',
      where: 'cart_id = ?',
      whereArgs: [cartId],
    );

    if (maps.isNotEmpty) {
      return CartPayment.fromJson(maps.first);
    }
    return null;
  }

  // Get cart payments by status
  Future<List<CartPayment>> getCartPaymentsByStatus(String status) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_payments',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return CartPayment.fromJson(maps[i]);
    });
  }

  // Get cart payments by payment method
  Future<List<CartPayment>> getCartPaymentsByMethod(String paymentMethod) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_payments',
      where: 'payment_method = ?',
      whereArgs: [paymentMethod],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return CartPayment.fromJson(maps[i]);
    });
  }

  // Get total payment amount for a cart
  Future<double> getTotalPaymentAmount(int cartId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM cart_payments WHERE cart_id = ?',
      [cartId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get payment count for a cart
  Future<int> getPaymentCount(int cartId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cart_payments WHERE cart_id = ?',
      [cartId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Update payment status
  Future<int> updatePaymentStatus(int paymentId, String status) async {
    final db = await dbHelper.database;
    return await db.update(
      'cart_payments',
      {'status': status},
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  // Get payments within date range
  Future<List<CartPayment>> getPaymentsByDateRange(String startDate, String endDate) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_payments',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return CartPayment.fromJson(maps[i]);
    });
  }

  // Get payments by reference ID
  Future<CartPayment?> getPaymentByReference(String referenceId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_payments',
      where: 'reference_id = ?',
      whereArgs: [referenceId],
    );

    if (maps.isNotEmpty) {
      return CartPayment.fromJson(maps.first);
    }
    return null;
  }

  // Get recent payments (last N payments)
  Future<List<CartPayment>> getRecentPayments({int limit = 10}) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_payments',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return CartPayment.fromJson(maps[i]);
    });
  }

  // Get pending payments
  Future<List<CartPayment>> getPendingPayments() async {
    return getCartPaymentsByStatus('pending');
  }

  // Get completed payments
  Future<List<CartPayment>> getCompletedPayments() async {
    return getCartPaymentsByStatus('completed');
  }

  // Get failed payments
  Future<List<CartPayment>> getFailedPayments() async {
    return getCartPaymentsByStatus('failed');
  }

  // Get refunded payments
  Future<List<CartPayment>> getRefundedPayments() async {
    return getCartPaymentsByStatus('refunded');
  }
}
