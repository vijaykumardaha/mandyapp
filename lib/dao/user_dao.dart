import 'package:mandyapp/models/user_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class UserDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertUser(User user) async {
    user.id = DBHelper.generateUuidInt();
    user.updatedAt = DateTime.now().millisecondsSinceEpoch;
    user.isDeleted = 0;
    user.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.insert('users', user.toJson());
  }

  Future<User?> userLogin(String mobile, String password) async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'mobile = ? AND password = ? AND is_deleted = ?',
        whereArgs: [mobile, password, 0]);

    return result.isNotEmpty ? User.fromJson(result.first) : null;
  }

  Future<User?> getUserByMobile(String mobile) async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'mobile = ? AND is_deleted = ?',
        whereArgs: [mobile, 0]);

    return result.isNotEmpty ? User.fromJson(result.first) : null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await dbHelper.database;
    var result = await db.query("users", where: 'is_deleted = ?', whereArgs: [0]);

    return result.isNotEmpty 
        ? result.map((user) => User.fromJson(user)).toList() 
        : [];
  }

  Future<User?> getUserById(int id) async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'id = ? AND is_deleted = ?',
        whereArgs: [id, 0]);

    return result.isNotEmpty ? User.fromJson(result.first) : null;
  }

  Future<int> updateUser(User user) async {
    user.updatedAt = DateTime.now().millisecondsSinceEpoch;
    user.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.update(
      'users',
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> restoreUser(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'users',
      {
        'is_deleted': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'users',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Bulk upsert users
  Future<void> bulkUpsertUsers(List<User> users) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final user in users) {
        batch.rawInsert('''
          INSERT INTO users (
            mandy_id, name, mobile, password, role,
            updated_at, is_deleted, sync_status
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)

          ON CONFLICT(mandy_id) DO UPDATE SET
            name = excluded.name,
            mobile = excluded.mobile,
            password = excluded.password,
            role = excluded.role,
            updated_at = excluded.updated_at,
            is_deleted = excluded.is_deleted,
            sync_status = excluded.sync_status

          WHERE excluded.updated_at > users.updated_at;
        ''', [
          user.mandyId,
          user.name,
          user.mobile,
          user.password,
          user.role,
          user.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
          user.isDeleted ?? 0,
          user.syncStatus ?? 1,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }

  Future<List<User>> getUsersByRole(String role) async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'role = ? AND is_deleted = ?',
        whereArgs: [role, 0]);

    return result.isNotEmpty 
        ? result.map((user) => User.fromJson(user)).toList() 
        : [];
  }

  Future<User?> getAdminUser() async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'role = ? AND is_deleted = ?',
        whereArgs: ['admin', 0],
        limit: 1);

    return result.isNotEmpty ? User.fromJson(result.first) : null;
  }

  
}
