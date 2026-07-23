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

    if (existing.isNotEmpty) return;

    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final veg in SyncVegetable.vegetables) {
      batch.rawInsert('''
        INSERT INTO vegetables (mandy_id, key, name, path, updated_at, is_deleted, sync_status)
        VALUES (?, ?, ?, ?, ?, 0, 0)
      ''', [mandyId, veg['key'], veg['name'], veg['path'], now]);
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
