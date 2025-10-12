import 'package:mandyapp/models/user_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class UserDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertUser(User user) async {
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

}
