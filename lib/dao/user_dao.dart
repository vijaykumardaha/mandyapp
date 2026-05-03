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
