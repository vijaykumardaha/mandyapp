

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

}
