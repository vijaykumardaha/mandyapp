import 'package:mandyapp/models/vegetable_model.dart';
import 'package:mandyapp/utils/app_helper.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:mandyapp/utils/sync_vegetable.dart';

class VegetableDAO {
  final dbHelper = DBHelper.instance;

  Future<void> syncVegetables() async {
    final db = await dbHelper.database;
    final mandyId = await AppHelper.getCurrentMandyId();

    final existing = await db.query(
      'vegetables',
      where: 'mandy_id = ? AND is_deleted = ?',
      whereArgs: [mandyId, 0],
      limit: 1,
    );

    final now = DateTime.now().millisecondsSinceEpoch;

    if (existing.isNotEmpty) {
      for (final veg in SyncVegetable.vegetables) {
        await db.update(
          'vegetables',
          {
            'price': double.tryParse(veg['price'] ?? '0.0') ?? 0.0,
            'unit': veg['unit'] ?? 'Kilogram',
            'common': veg['common'] ?? 0,
          },
          where: 'mandy_id = ? AND key = ?',
          whereArgs: [mandyId, veg['key']],
        );
      }
      return;
    }

    final batch = db.batch();

    for (final veg in SyncVegetable.vegetables) {
      batch.rawInsert('''
        INSERT INTO vegetables (mandy_id, key, name, path, price, unit, common, updated_at, is_deleted, sync_status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0)
      ''', [mandyId, veg['key'], veg['name'], veg['path'], double.tryParse(veg['price'] ?? '0.0') ?? 0.0, veg['unit'] ?? 'Kilogram', veg['common'] ?? 0, now]);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Vegetable>> getVegetables() async {
    final db = await dbHelper.database;
    final mandyId = await AppHelper.getCurrentMandyId();
    final List<Map<String, dynamic>> maps = await db.query(
      'vegetables',
      where: 'mandy_id = ? AND is_deleted = ?',
      whereArgs: [mandyId, 0],
    );
    return List.generate(maps.length, (i) => Vegetable.fromJson(maps[i]));
  }

  Future<Vegetable?> getVegetableByKey(String key) async {
    final db = await dbHelper.database;
    final mandyId = await AppHelper.getCurrentMandyId();
    final List<Map<String, dynamic>> maps = await db.query(
      'vegetables',
      where: 'mandy_id = ? AND key = ? AND is_deleted = ?',
      whereArgs: [mandyId, key, 0],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Vegetable.fromJson(maps.first);
    }
    return null;
  }
}
