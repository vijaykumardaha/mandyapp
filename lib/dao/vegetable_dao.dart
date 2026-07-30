import 'package:mandiapp/models/vegetable_model.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/utils/db_helper.dart';
import 'package:mandiapp/utils/signup_sync.dart';

class VegetableDAO {
  final dbHelper = DBHelper.instance;

  Future<void> syncVegetables() async {
    final db = await dbHelper.database;
    final mandiId = await AppHelper.getCurrentMandiId();

    final existing = await db.query(
      'vegetables',
      where: 'mandi_id = ? AND is_deleted = ?',
      whereArgs: [mandiId, 0],
      limit: 1,
    );

    final now = DateTime.now().millisecondsSinceEpoch;

    if (existing.isNotEmpty) {
      for (final veg in SignupSync.vegetables) {
        await db.update(
          'vegetables',
          {
            'price': double.tryParse(veg['price'] ?? '0.0') ?? 0.0,
            'unit': veg['unit'] ?? 'Kilogram',
            'common': veg['common'] ?? 0,
          },
          where: 'mandi_id = ? AND key = ?',
          whereArgs: [mandiId, veg['key']],
        );
      }
      return;
    }

    final batch = db.batch();

    for (final veg in SignupSync.vegetables) {
      batch.rawInsert('''
        INSERT INTO vegetables (mandi_id, key, name, path, price, unit, common, updated_at, is_deleted, sync_status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0)
      ''', [mandiId, veg['key'], veg['name'], veg['path'], double.tryParse(veg['price'] ?? '0.0') ?? 0.0, veg['unit'] ?? 'Kilogram', veg['common'] ?? 0, now]);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Vegetable>> getVegetables() async {
    final db = await dbHelper.database;
    final mandiId = await AppHelper.getCurrentMandiId();
    final List<Map<String, dynamic>> maps = await db.query(
      'vegetables',
      where: 'mandi_id = ? AND is_deleted = ?',
      whereArgs: [mandiId, 0],
    );
    return List.generate(maps.length, (i) => Vegetable.fromJson(maps[i]));
  }

  Future<Vegetable?> getVegetableByKey(String key) async {
    final db = await dbHelper.database;
    final mandiId = await AppHelper.getCurrentMandiId();
    final List<Map<String, dynamic>> maps = await db.query(
      'vegetables',
      where: 'mandi_id = ? AND key = ? AND is_deleted = ?',
      whereArgs: [mandiId, key, 0],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Vegetable.fromJson(maps.first);
    }
    return null;
  }

  // Bulk upsert vegetables
  Future<void> bulkUpsertVegetables(List<Vegetable> vegetables) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final veg in vegetables) {
        batch.rawInsert('''
          INSERT INTO vegetables (
            id, mandi_id, key, name, path, price, unit,
            common, updated_at, is_deleted, sync_status
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

          ON CONFLICT(id) DO UPDATE SET
            mandi_id = excluded.mandi_id,
            key = excluded.key,
            name = excluded.name,
            path = excluded.path,
            price = excluded.price,
            unit = excluded.unit,
            common = excluded.common,
            updated_at = excluded.updated_at,
            is_deleted = excluded.is_deleted,
            sync_status = excluded.sync_status

          WHERE excluded.updated_at > vegetables.updated_at;
        ''', [
          veg.id,
          veg.mandiId,
          veg.key,
          veg.name,
          veg.path,
          veg.price,
          veg.unit,
          veg.common,
          veg.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
          veg.isDeleted ?? 0,
          veg.syncStatus ?? 1,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }
}
