import 'package:mandyapp/models/customer_payment_model.dart';
import 'package:mandyapp/utils/app_helper.dart';
import 'package:mandyapp/utils/db_helper.dart';

class CustomerPaymentDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertPayment(CustomerPayment payment) async {
    final db = await dbHelper.database;
    final mandyId = await AppHelper.getCurrentMandyId();
    payment.id = DBHelper.generateUuidInt();
    payment.mandyId = mandyId;
    payment.updatedAt = DateTime.now().millisecondsSinceEpoch;
    payment.isDeleted = 0;
    payment.syncStatus = 0;
    return await db.insert('customer_payments', payment.toJson());
  }

  Future<int> updatePayment(CustomerPayment payment) async {
    final db = await dbHelper.database;
    payment.updatedAt = DateTime.now().millisecondsSinceEpoch;
    payment.syncStatus = 0;
    return await db.update(
      'customer_payments',
      payment.toJson(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int paymentId) async {
    final db = await dbHelper.database;
    return await db.update(
      'customer_payments',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  Future<List<CustomerPayment>> getPaymentsByCustomerId(int customerId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer_payments',
      where: 'customer_id = ? AND is_deleted = ?',
      whereArgs: [customerId, 0],
      orderBy: 'payment_date DESC',
    );
    return List.generate(maps.length, (i) {
      return CustomerPayment.fromJson(maps[i]);
    });
  }

  Future<CustomerPayment?> getPaymentById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer_payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CustomerPayment.fromJson(maps.first);
    }
    return null;
  }

  Future<double> getTotalByType(int customerId, String type) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM customer_payments WHERE customer_id = ? AND type = ? AND is_deleted = 0',
      [customerId, type],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
