import 'package:mandyapp/models/charge_type_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class ChargeTypeDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertChargeType(ChargeType chargeType) async {
    chargeType.id = DBHelper.generateUuidInt();
    chargeType.updatedAt = DateTime.now().millisecondsSinceEpoch;
    chargeType.isDeleted = 0;
    chargeType.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.insert('charge_types', chargeType.toJson());
  }

  Future<List<ChargeType>> getAllChargeTypes() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<List<ChargeType>> getActiveChargeTypes() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'is_active = ? AND is_deleted = ?',
      whereArgs: [1, 0],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<ChargeType?> getChargeTypeById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'id = ? AND is_deleted = ?',
      whereArgs: [id, 0],
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
      where: 'charge_name = ? AND is_deleted = ?',
      whereArgs: [chargeName, 0],
    );
    if (maps.isNotEmpty) {
      return ChargeType.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateChargeType(ChargeType chargeType) async {
    chargeType.updatedAt = DateTime.now().millisecondsSinceEpoch;
    chargeType.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.update(
      'charge_types',
      chargeType.toJson(),
      where: 'id = ?',
      whereArgs: [chargeType.id],
    );
  }

  Future<int> restoreChargeType(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'charge_types',
      {
        'is_deleted': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteChargeType(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'charge_types',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
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
      'SELECT SUM(charge_amount) as total FROM charge_types WHERE is_active = 1 AND is_deleted = 0',
    );
    return result.first['total'] as double? ?? 0.0;
  }

  Future<List<ChargeType>> getChargeTypesByType(String chargeFor) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'charge_for = ? AND is_deleted = ?',
      whereArgs: [chargeFor, 0],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<List<ChargeType>> getActiveChargeTypesByType(String chargeFor) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'charge_for = ? AND is_active = ? AND is_deleted = ?',
      whereArgs: [chargeFor, 1, 0],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<List<ChargeType>> getDefaultChargeTypes(String chargeFor) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'charge_types',
      where: 'charge_for = ? AND is_default = ? AND is_deleted = ?',
      whereArgs: [chargeFor, 1, 0],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<bool> chargeTypeExistsForType(String chargeName, String chargeFor) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'charge_types',
      where: 'charge_name = ? AND charge_for = ? AND is_deleted = ?',
      whereArgs: [chargeName, chargeFor, 0],
    );
    return result.isNotEmpty;
  }
}
