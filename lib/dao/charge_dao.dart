import 'package:mandyapp/models/charge_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class ChargeDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertCharge(Charge charge) async {
    charge.id = DBHelper.generateUuidInt();
    final db = await dbHelper.database;
    return await db.insert('charges', charge.toJson());
  }

  Future<List<Charge>> getAllCharges() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charges',
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => Charge.fromJson(maps[i]));
  }

  Future<List<Charge>> getActiveCharges() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charges',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => Charge.fromJson(maps[i]));
  }

  Future<Charge?> getChargeById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charges',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Charge.fromJson(maps.first);
    }
    return null;
  }

  Future<Charge?> getChargeByName(String chargeName) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charges',
      where: 'charge_name = ?',
      whereArgs: [chargeName],
    );
    if (maps.isNotEmpty) {
      return Charge.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateCharge(Charge charge) async {
    final db = await dbHelper.database;
    return await db.update(
      'charges',
      charge.toJson(),
      where: 'id = ?',
      whereArgs: [charge.id],
    );
  }

  Future<int> deleteCharge(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'charges',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> activateCharge(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'charges',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deactivateCharge(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'charges',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalActiveCharges() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(charge_amount) as total FROM charges WHERE is_active = 1',
    );
    return result.first['total'] as double? ?? 0.0;
  }
}
