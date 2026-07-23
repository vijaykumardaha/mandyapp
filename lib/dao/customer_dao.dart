

import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/utils/app_helper.dart';
import 'package:mandyapp/utils/db_helper.dart';

class CustomerDAO {
  final dbHelper = DBHelper.instance;

  Future<void> bulkInsert(List<Customer> customers) async {
    final db = await dbHelper.database;
    final mandyId = await AppHelper.getCurrentMandyId();
    await db.update('customers', {
      'is_deleted': 1,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
    await db.transaction((txn) async {
      for (var customer in customers) {
        customer.id = DBHelper.generateUuidInt();
        customer.mandyId = mandyId;
        customer.updatedAt = DateTime.now().millisecondsSinceEpoch;
        customer.isDeleted = 0;
        customer.syncStatus = 0;
        await txn.insert('customers', customer.toJson());
      }
    });
  }

  Future<List<Customer>> getCustomers() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('customers', where: 'is_deleted = ?', whereArgs: [0], orderBy: 'name ASC');
    return List.generate(maps.length, (i) {
      return Customer.fromJson(maps[i]);
    });
  }

  Future<Customer> insertCustomer(Customer customer) async {
    final db = await dbHelper.database;
    customer.id = DBHelper.generateUuidInt();
    customer.mandyId = await AppHelper.getCurrentMandyId();
    customer.updatedAt = DateTime.now().millisecondsSinceEpoch;
    customer.isDeleted = 0;
    customer.syncStatus = 0;

    await db.insert('customers', customer.toJson());

    return customer;
  }

  Future<int> restoreCustomer(int customerId) async {
    final db = await dbHelper.database;
    return await db.update(
      'customers',
      {
        'is_deleted': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  Future<void> deleteCustomer(int customerId) async {
    final db = await dbHelper.database;
    await db.update(
      'customers',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  Future<void> updateCustomer(Customer customer) async {
    if (customer.id == null) {
      throw ArgumentError('Customer ID is required for update');
    }
    customer.updatedAt = DateTime.now().millisecondsSinceEpoch;
    customer.syncStatus = 0;
    final db = await dbHelper.database;
    await db.update(
      'customers',
      customer.toJson(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> getCustomerCount() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM customers WHERE is_deleted = ?',
      [0],
    );
    return result.first['count'] as int? ?? 0;
  }

  // Bulk upsert customers
  Future<void> bulkUpsertCustomers(List<Customer> customers) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final customer in customers) {
          batch.rawInsert('''
          INSERT INTO customers (
            mandy_id, name, phone,
            updated_at, is_deleted, sync_status
          )
          VALUES (?, ?, ?, ?, ?, ?)

          ON CONFLICT(mandy_id) DO UPDATE SET
            name = excluded.name,
            phone = excluded.phone,
            updated_at = excluded.updated_at,
            is_deleted = excluded.is_deleted,
            sync_status = excluded.sync_status

          WHERE excluded.updated_at > customers.updated_at;
        ''', [
          customer.mandyId,
          customer.name,
          customer.phone,
          customer.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
          customer.isDeleted ?? 0,
          customer.syncStatus ?? 1,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }
}
