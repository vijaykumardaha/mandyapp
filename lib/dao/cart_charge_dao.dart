import 'package:mandyapp/models/cart_charge_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class CartChargeDAO {
  final dbHelper = DBHelper.instance;

  // Insert multiple cart charges for a cart (replaces existing ones)
  Future<void> bulkInsertForCart(String cartId, List<CartCharge> charges) async {
    final db = await dbHelper.database;

    // Start transaction
    await db.transaction((txn) async {
      // Delete existing charges for this cart
      await txn.delete('cart_charges', where: 'cart_id = ?', whereArgs: [cartId]);

      // Insert new charges
      for (var charge in charges) {
        await txn.insert('cart_charges', {
          'id': DBHelper.generateUuidInt(),
          'cart_id': charge.cartId,
          'charge_name': charge.chargeName,
          'charge_amount': charge.chargeAmount,
        });
      }
    });
  }

  // Get all charges for a specific cart
  Future<List<CartCharge>> getCartCharges(String cartId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_charges',
      where: 'cart_id = ?',
      whereArgs: [cartId],
      orderBy: 'charge_name ASC',
    );

    return List.generate(maps.length, (i) {
      return CartCharge.fromJson(maps[i]);
    });
  }

  // Insert a single cart charge
  Future<int> insertCartCharge(CartCharge charge) async {
    final db = await dbHelper.database;
    return await db.insert('cart_charges', {
      'id': DBHelper.generateUuidInt(),
      'cart_id': charge.cartId,
      'charge_name': charge.chargeName,
      'charge_amount': charge.chargeAmount,
    });
  }

  // Update an existing cart charge
  Future<int> updateCartCharge(CartCharge charge) async {
    final db = await dbHelper.database;
    return await db.update(
      'cart_charges',
      {
        'cart_id': charge.cartId,
        'charge_name': charge.chargeName,
        'charge_amount': charge.chargeAmount,
      },
      where: 'id = ?',
      whereArgs: [charge.id],
    );
  }

  // Delete a cart charge by ID
  Future<int> deleteCartCharge(int chargeId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'cart_charges',
      where: 'id = ?',
      whereArgs: [chargeId],
    );
  }

  // Delete all charges for a specific cart
  Future<int> deleteCartCharges(String cartId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'cart_charges',
      where: 'cart_id = ?',
      whereArgs: [cartId],
    );
  }

  // Get total charge amount for a cart
  Future<double> getCartChargesTotal(String cartId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(charge_amount) as total FROM cart_charges WHERE cart_id = ?',
      [cartId],
    );

    return result.isNotEmpty && result.first['total'] != null
        ? (result.first['total'] as num).toDouble()
        : 0.0;
  }

  // Check if a charge name already exists for a cart
  Future<bool> chargeExistsForCart(String cartId, String chargeName) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'cart_charges',
      where: 'cart_id = ? AND charge_name = ?',
      whereArgs: [cartId, chargeName],
    );

    return result.isNotEmpty;
  }
}
