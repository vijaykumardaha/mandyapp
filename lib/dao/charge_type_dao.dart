import 'package:krishimandi/models/charge_type_model.dart';
import 'package:krishimandi/utils/app_helper.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/utils/db_helper.dart';
import 'package:krishimandi/utils/signup_sync.dart';

class ChargeTypeDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertChargeType(ChargeType chargeType) async {
    chargeType.id = DBHelper.generateUuidInt();
    chargeType.mandiId = await AppHelper.getCurrentMandiId();
    chargeType.updatedAt = DateTime.now().millisecondsSinceEpoch;
    chargeType.isDeleted = 0;
    chargeType.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.insert(DbTables.chargeTypes, chargeType.toJson());
  }

  Future<List<ChargeType>> getAllChargeTypes() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.chargeTypes,
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<List<ChargeType>> getActiveChargeTypes() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.chargeTypes,
      where: 'is_active = ? AND is_deleted = ?',
      whereArgs: [1, 0],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<ChargeType?> getChargeTypeById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.chargeTypes,
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
      DbTables.chargeTypes,
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
    chargeType.isDeleted = 0;
    chargeType.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.update(
      DbTables.chargeTypes,
      chargeType.toJson(),
      where: 'id = ?',
      whereArgs: [chargeType.id],
    );
  }

  Future<int> restoreChargeType(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      DbTables.chargeTypes,
      {
        'is_deleted': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteChargeType(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      DbTables.chargeTypes,
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> activateChargeType(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      DbTables.chargeTypes,
      {
        'is_active': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deactivateChargeType(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      DbTables.chargeTypes,
      {
        'is_active': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
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
      DbTables.chargeTypes,
      where: 'charge_for = ? AND is_deleted = ?',
      whereArgs: [chargeFor, 0],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<List<ChargeType>> getActiveChargeTypesByType(String chargeFor) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.chargeTypes,
      where: 'charge_for = ? AND is_active = ? AND is_deleted = ?',
      whereArgs: [chargeFor, 1, 0],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<List<ChargeType>> getDefaultChargeTypes(String chargeFor) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.chargeTypes,
      where: 'charge_for = ? AND is_default = ? AND is_deleted = ?',
      whereArgs: [chargeFor, 1, 0],
      orderBy: 'charge_name ASC',
    );
    return List.generate(maps.length, (i) => ChargeType.fromJson(maps[i]));
  }

  Future<bool> chargeTypeExistsForType(
      String chargeName, String chargeFor) async {
    final db = await dbHelper.database;
    final result = await db.query(
      DbTables.chargeTypes,
      where: 'charge_name = ? AND charge_for = ? AND is_deleted = ?',
      whereArgs: [chargeName, chargeFor, 0],
    );
    return result.isNotEmpty;
  }

  Future<void> bulkUpsertChargeTypes(List<ChargeType> chargeTypes) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final chargeType in chargeTypes) {
        batch.rawInsert('''
          INSERT INTO ${DbTables.chargeTypes} (
            id, mandi_id, charge_name, charge_type, charge_amount, charge_for,
            is_default, is_active, updated_at, is_deleted, sync_status
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

          ON CONFLICT(id) DO UPDATE SET
            mandi_id = excluded.mandi_id,
            charge_name = excluded.charge_name,
            charge_type = excluded.charge_type,
            charge_amount = excluded.charge_amount,
            charge_for = excluded.charge_for,
            is_default = excluded.is_default,
            is_active = excluded.is_active,
            updated_at = excluded.updated_at,
            is_deleted = excluded.is_deleted,
            sync_status = excluded.sync_status

          WHERE excluded.updated_at > ${DbTables.chargeTypes}.updated_at;
        ''', [
          chargeType.id,
          chargeType.mandiId,
          chargeType.chargeName,
          chargeType.chargeType,
          chargeType.chargeAmount,
          chargeType.chargeFor,
          chargeType.isDefault,
          chargeType.isActive,
          chargeType.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
          chargeType.isDeleted ?? 0,
          1,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }

  Future<void> insertDefaultCharges() async {
    final db = await dbHelper.database;
    for (final charge in SignupSync.defaultCharges) {
      final existing = await db.query(
        DbTables.chargeTypes,
        where: 'charge_name = ? AND charge_for = ? AND is_deleted = ?',
        whereArgs: [charge['charge_name'], charge['charge_for'], 0],
      );
      if (existing.isEmpty) {
        await insertChargeType(ChargeType(
          chargeName: charge['charge_name'],
          chargeType: charge['charge_type'],
          chargeAmount: charge['charge_amount'],
          chargeFor: charge['charge_for'],
          isDefault: charge['is_default'] ?? 1,
        ));
      }
    }
  }
}
