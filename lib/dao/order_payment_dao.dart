import 'package:mandyapp/models/order_payment_model.dart';
import 'package:mandyapp/utils/app_helper.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class OrderPaymentDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertOrderPayment(OrderPayment payment) async {
    final db = await dbHelper.database;
    final mandyId = await AppHelper.getCurrentMandyId();
    final json = payment.toJson();
    json.remove('id');
    json['mandy_id'] = mandyId;
    return await db.insert('order_payments', json);
  }

  Future<int> updateOrderPayment(OrderPayment payment) async {
    final db = await dbHelper.database;
    return await db.update(
      'order_payments',
      payment.toJson(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deleteOrderPayment(int id) async {
    final db = await dbHelper.database;
    return await db.delete('order_payments', where: 'id = ?', whereArgs: [id]);
  }

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

  Future<int> deleteOrderPayments(int orderId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'order_payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<OrderPayment>> getAllOrderPayments() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      orderBy: 'updated_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OrderPayment.fromJson(maps[i]);
    });
  }

  Future<List<OrderPayment>> getOrderPaymentsByOrderId(int orderId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'updated_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OrderPayment.fromJson(maps[i]);
    });
  }

  Future<double> getTotalPaymentAmount(int orderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM order_payments WHERE order_id = ?',
      [orderId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getPaymentCount(int orderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM order_payments WHERE order_id = ?',
      [orderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<OrderPayment>> getPaymentsByDateRange(String startDate, String endDate) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      where: 'updated_at BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'updated_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OrderPayment.fromJson(maps[i]);
    });
  }

  Future<List<OrderPayment>> getRecentPayments({int limit = 10}) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      orderBy: 'updated_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return OrderPayment.fromJson(maps[i]);
    });
  }

  Future<List<OrderPayment>> getPaymentsBySource(String source) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_payments',
      where: 'source = ?',
      whereArgs: [source],
      orderBy: 'updated_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OrderPayment.fromJson(maps[i]);
    });
  }

  Future<double> getTotalAmountBySource(int orderId, String source) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM order_payments WHERE order_id = ? AND source = ?',
      [orderId, source],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

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

  Future<void> bulkUpsertOrderPayments(List<OrderPayment> orderPayments) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final orderPayment in orderPayments) {
        batch.rawInsert('''
          INSERT INTO order_payments (
            order_id, source, amount, updated_at
          )
          VALUES (?, ?, ?, ?)

          ON CONFLICT(id) DO UPDATE SET
            order_id = excluded.order_id,
            source = excluded.source,
            amount = excluded.amount,
            updated_at = excluded.updated_at

          WHERE excluded.updated_at > order_payments.updated_at;
        ''', [
          orderPayment.orderId,
          orderPayment.source,
          orderPayment.amount,
          orderPayment.updatedAt,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }
}
