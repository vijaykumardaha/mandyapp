

import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class CustomerDAO {
  final dbHelper = DBHelper.instance;

  Future<void> bulkInsert(List<Customer> customers) async {
    final db = await dbHelper.database;
    await db.delete('customers');
    await db.transaction((txn) async {
      for (var customer in customers) {
        customer.id = DBHelper.generateUuidInt();
        await txn.insert('customers', customer.toJson());
      }
    });
  }

  Future<List<Customer>> getCustomers() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('customers', orderBy: 'name ASC');
    return List.generate(maps.length, (i) {
      return Customer.fromJson(maps[i]);
    });
  }

  Future<Customer> insertCustomer(Customer customer) async {
    final db = await dbHelper.database;
    final newCustomer = Customer(
      id: customer.id ?? DBHelper.generateUuidInt(),
      name: customer.name,
      phone: customer.phone,
      borrowAmount: customer.borrowAmount,
      advancedAmount: customer.advancedAmount,
    );

    await db.insert('customers', {
      'id': newCustomer.id,
      'name': newCustomer.name,
      'phone': newCustomer.phone,
      'borrow_amount': newCustomer.borrowAmount,
      'advanced_amount': newCustomer.advancedAmount,
    });

    return newCustomer;
  }

  Future<void> deleteCustomer(int customerId) async {
    final db = await dbHelper.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [customerId]);
  }

  Future<void> updateCustomer(Customer customer) async {
    if (customer.id == null) {
      throw ArgumentError('Customer ID is required for update');
    }

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
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    final countValue = result.isNotEmpty ? result.first['count'] as int? : null;
    return countValue ?? 0;
  }

}
