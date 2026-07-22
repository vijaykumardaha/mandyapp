import 'package:mandyapp/models/order_charge_model.dart';
import 'package:mandyapp/utils/app_helper.dart';
import 'package:mandyapp/utils/db_helper.dart';

class OrderChargeDAO {
  final dbHelper = DBHelper.instance;

  // Insert multiple order charges for an order (replaces existing ones)
  Future<void> bulkInsertForOrder(String orderId, List<OrderCharge> charges) async {
    final db = await dbHelper.database;
    final mandyId = await AppHelper.getCurrentMandyId();

    // Start transaction
    await db.transaction((txn) async {
      // Delete existing charges for this order
      await txn.delete('order_charges', where: 'order_id = ?', whereArgs: [orderId]);

      // Insert new charges
      for (var charge in charges) {
        charge.id = DBHelper.generateUuidInt();
        charge.mandyId = mandyId;
        charge.updatedAt = DateTime.now().millisecondsSinceEpoch;
        charge.isDeleted = 0;
        charge.syncStatus = 0;
        await txn.insert('order_charges', charge.toMap());
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
    charge.id = DBHelper.generateUuidInt();
    charge.mandyId = await AppHelper.getCurrentMandyId();
    charge.updatedAt = DateTime.now().millisecondsSinceEpoch;
    charge.isDeleted = 0;
    charge.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.insert('order_charges', charge.toMap());
  }

  // Update an existing order charge
  Future<int> updateOrderCharge(OrderCharge charge) async {
    charge.updatedAt = DateTime.now().millisecondsSinceEpoch;
    charge.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.update(
      'order_charges',
      charge.toMap(),
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

  // Bulk upsert order charges
  Future<void> bulkUpsertOrderCharges(List<OrderCharge> orderCharges) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final orderCharge in orderCharges) {
        batch.rawInsert('''
          INSERT INTO order_charges (
            mandy_id, order_id, charge_name, charge_amount,
            updated_at, is_deleted, sync_status
          )
          VALUES (?, ?, ?, ?, ?, ?, ?)

          ON CONFLICT(mandy_id) DO UPDATE SET
            order_id = excluded.order_id,
            charge_name = excluded.charge_name,
            charge_amount = excluded.charge_amount,
            updated_at = excluded.updated_at,
            is_deleted = excluded.is_deleted,
            sync_status = excluded.sync_status

          WHERE excluded.updated_at > order_charges.updated_at;
        ''', [
          orderCharge.mandyId,
          orderCharge.orderId,
          orderCharge.chargeName,
          orderCharge.chargeAmount,
          orderCharge.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
          orderCharge.isDeleted ?? 0,
          orderCharge.syncStatus ?? 1,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }
}
