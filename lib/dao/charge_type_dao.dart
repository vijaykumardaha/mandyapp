import 'package:mandyapp/models/charge_type_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class ChargeTypeDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertChargeType(ChargeType chargeType) async {
    chargeType.id = DBHelper.generateUuidInt();
    final db = await dbHelper.database;
    return await db.insert('charge_types', chargeType.toJson());
  }

  Future<List<ChargeType>> getAllChargeTypes() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<List<ChargeType>> getActiveChargeTypes() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<ChargeType?> getChargeTypeById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ChargeType.fromJson(maps.first);
    }
    return null;
  }

  Future<ChargeType?> getChargeTypeByName(String chargeName) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'charge_name = ?',
      whereArgs: [chargeName],
    );
    if (maps.isNotEmpty) {
      return ChargeType.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateChargeType(ChargeType chargeType) async {
    final db = await dbHelper.database;
    return await db.update(
      'charge_types',
      chargeType.toJson(),
      where: 'id = ?',
      whereArgs: [chargeType.id],
    );
  }

  Future<int> deleteChargeType(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'charge_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> activateChargeType(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'charge_types',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deactivateChargeType(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'charge_types',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalActiveChargeTypes() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(charge_amount) as total FROM charge_types WHERE is_active = 1',
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Get charge types for a specific type (buyer/seller)
  Future<List<ChargeType>> getChargeTypesByType(String chargeFor) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'charge_for = ?',
      whereArgs: [chargeFor],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  // Get active charge types for a specific type
  Future<List<ChargeType>> getActiveChargeTypesByType(String chargeFor) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'charge_for = ? AND is_active = ?',
      whereArgs: [chargeFor, 1],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  // Get default charge types for a specific type
  Future<List<ChargeType>> getDefaultChargeTypes(String chargeFor) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'charge_for = ? AND is_default = ?',
      whereArgs: [chargeFor, 1],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  // Check if a charge type name already exists for a specific type
  Future<bool> chargeTypeExistsForType(String chargeName, String chargeFor) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'charge_types',
      where: 'charge_name = ? AND charge_for = ?',
      whereArgs: [chargeName, chargeFor],
    );
    return result.isNotEmpty;
  }
}
