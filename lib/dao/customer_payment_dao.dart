import 'package:mandiapp/models/customer_payment_model.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/utils/db_helper.dart';

class CustomerPaymentDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertPayment(CustomerPayment payment) async {
    final db = await dbHelper.database;
    final mandiId = await AppHelper.getCurrentMandiId();
    payment.id = DBHelper.generateUuidInt();
    payment.mandiId = mandiId;
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

  // Bulk upsert customer payments
  Future<void> bulkUpsertCustomerPayments(List<CustomerPayment> customerPayments) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final payment in customerPayments) {
        batch.rawInsert('''
          INSERT INTO customer_payments (
            id, mandi_id, customer_id, amount, type, source,
            note, payment_date, updated_at, is_deleted, sync_status
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

          ON CONFLICT(id) DO UPDATE SET
            mandi_id = excluded.mandi_id,
            customer_id = excluded.customer_id,
            amount = excluded.amount,
            type = excluded.type,
            source = excluded.source,
            note = excluded.note,
            payment_date = excluded.payment_date,
            updated_at = excluded.updated_at,
            is_deleted = excluded.is_deleted,
            sync_status = excluded.sync_status

          WHERE excluded.updated_at > customer_payments.updated_at;
        ''', [
          payment.id,
          payment.mandiId,
          payment.customerId,
          payment.amount,
          payment.type,
          payment.source,
          payment.note,
          payment.paymentDate,
          payment.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
          payment.isDeleted ?? 0,
          payment.syncStatus ?? 1,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }
}
