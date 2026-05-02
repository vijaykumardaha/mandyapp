import 'package:mandyapp/models/order_expense_model.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class OrderExpenseDao {
  final dbHelper = DBHelper.instance;

  OrderExpenseDao();

  Future<int> insert(OrderExpense orderExpense) async {
    final db = await dbHelper.database;
    return await db.insert('order_expenses', orderExpense.toMap());
  }

  Future<OrderExpense?> getById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'order_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return OrderExpense.fromMap(maps.first);
    }
    return null;
  }

  Future<List<OrderExpense>> getAll() async {
    final db = await dbHelper.database;
    final maps = await db.query('order_expenses', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => OrderExpense.fromMap(maps[i]));
  }

  Future<List<OrderExpense>> getByOrderId(int orderId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'order_expenses',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => OrderExpense.fromMap(maps[i]));
  }

  Future<int> update(OrderExpense orderExpense) async {
    final db = await dbHelper.database;
    return await db.update(
      'order_expenses',
      orderExpense.toMap(),
      where: 'id = ?',
      whereArgs: [orderExpense.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'order_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByOrderId(int orderId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'order_expenses',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  Future<double> getTotalExpensesByOrderId(int orderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(expense_amount) as total FROM order_expenses WHERE order_id = ?',
      [orderId],
    );
    
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<int> count() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM order_expenses');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countByOrderId(int orderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM order_expenses WHERE order_id = ?',
      [orderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
