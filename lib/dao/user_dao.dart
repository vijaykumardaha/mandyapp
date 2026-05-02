import 'package:mandyapp/models/user_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class UserDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertUser(User user) async {
    user.id = DBHelper.generateUuidInt();
    final db = await dbHelper.database;
    return await db.insert('users', user.toJson());
  }

  Future<User?> userLogin(String mobile, String password) async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'mobile = ? AND password = ?',
        whereArgs: [mobile, password]);

    return result.isNotEmpty ? User.fromJson(result.first) : null;
  }

  Future<User?> getUserByMobile(String mobile) async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'mobile = ?',
        whereArgs: [mobile]);

    return result.isNotEmpty ? User.fromJson(result.first) : null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await dbHelper.database;
    var result = await db.query("users");

    return result.isNotEmpty 
        ? result.map((user) => User.fromJson(user)).toList() 
        : [];
  }

  Future<User?> getUserById(int id) async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'id = ?',
        whereArgs: [id]);

    return result.isNotEmpty ? User.fromJson(result.first) : null;
  }

  Future<int> updateUser(User user) async {
    final db = await dbHelper.database;
    return await db.update(
      'users',
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<User>> getUsersByRole(String role) async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'role = ?',
        whereArgs: [role]);

    return result.isNotEmpty 
        ? result.map((user) => User.fromJson(user)).toList() 
        : [];
  }

  Future<User?> getAdminUser() async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'role = ?',
        whereArgs: ['admin'],
        limit: 1);

    return result.isNotEmpty ? User.fromJson(result.first) : null;
  }

  Future<int> updateUserRole(int userId, String newRole) async {
    final db = await dbHelper.database;
    return await db.update(
      'users',
      {'role': newRole},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<User>> getUsersCreatedBy(int createdBy) async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'created_by = ?',
        whereArgs: [createdBy]);

    return result.isNotEmpty 
        ? result.map((user) => User.fromJson(user)).toList() 
        : [];
  }

  Future<User?> getCreatorInfo(int creatorId) async {
    final db = await dbHelper.database;
    var result = await db.query("users",
        where: 'id = ?',
        whereArgs: [creatorId]);

    return result.isNotEmpty ? User.fromJson(result.first) : null;
  }

  Future<int> insertUserWithCreator(User user, int createdBy) async {
    user.id = DBHelper.generateUuidInt();
    user.createdBy = createdBy;
    final db = await dbHelper.database;
    return await db.insert('users', user.toJson());
  }

}
