import 'package:mandyapp/models/order_charge_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class OrderChargeDAO {
  final dbHelper = DBHelper.instance;

  // Insert multiple order charges for an order (replaces existing ones)
  Future<void> bulkInsertForOrder(String orderId, List<OrderCharge> charges) async {
    final db = await dbHelper.database;

    // Start transaction
    await db.transaction((txn) async {
      // Delete existing charges for this order
      await txn.delete('order_charges', where: 'order_id = ?', whereArgs: [orderId]);

      // Insert new charges
      for (var charge in charges) {
        await txn.insert('order_charges', {
          'id': DBHelper.generateUuidInt(),
          'order_id': charge.orderId,
          'charge_name': charge.chargeName,
          'charge_amount': charge.chargeAmount,
        });
      }
    });
  }

  // Get all charges for a specific order
  Future<List<OrderCharge>> getOrderCharges(String orderId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_charges',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'charge_name ASC',
    );

    return List.generate(maps.length, (i) {
      return OrderCharge.fromMap(maps[i]);
    });
  }

  // Insert a single order charge
  Future<int> insertOrderCharge(OrderCharge charge) async {
    final db = await dbHelper.database;
    return await db.insert('order_charges', {
      'id': DBHelper.generateUuidInt(),
      'order_id': charge.orderId,
      'charge_name': charge.chargeName,
      'charge_amount': charge.chargeAmount,
    });
  }

  // Update an existing order charge
  Future<int> updateOrderCharge(OrderCharge charge) async {
    final db = await dbHelper.database;
    return await db.update(
      'order_charges',
      {
        'order_id': charge.orderId,
        'charge_name': charge.chargeName,
        'charge_amount': charge.chargeAmount,
      },
      where: 'id = ?',
      whereArgs: [charge.id],
    );
  }

  // Delete an order charge by ID
  Future<int> deleteOrderCharge(int chargeId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'order_charges',
      where: 'id = ?',
      whereArgs: [chargeId],
    );
  }

  // Delete all charges for a specific order
  Future<int> deleteOrderCharges(int orderId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'order_charges',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  // Get total charge amount for an order
  Future<double> getOrderChargesTotal(String orderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(charge_amount) as total FROM order_charges WHERE order_id = ?',
      [orderId],
    );

    return result.isNotEmpty && result.first['total'] != null
        ? (result.first['total'] as num).toDouble()
        : 0.0;
  }

  // Check if a charge name already exists for an order
  Future<bool> chargeExistsForOrder(String orderId, String chargeName) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'order_charges',
      where: 'order_id = ? AND charge_name = ?',
      whereArgs: [orderId, chargeName],
    );

    return result.isNotEmpty;
  }
}
