import 'package:mandiapp/models/order_expense_model.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/utils/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class OrderExpenseDao {
  final dbHelper = DBHelper.instance;

  OrderExpenseDao();

  Future<int> insert(OrderExpense orderExpense) async {
    final db = await dbHelper.database;
    orderExpense.mandiId = await AppHelper.getCurrentMandiId();
    orderExpense.updatedAt = DateTime.now().millisecondsSinceEpoch;
    orderExpense.isDeleted = 0;
    orderExpense.syncStatus = 0;
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
    final maps = await db.query('order_expenses', orderBy: 'updated_at DESC');
    return List.generate(maps.length, (i) => OrderExpense.fromMap(maps[i]));
  }

  Future<List<OrderExpense>> getByOrderId(int orderId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'order_expenses',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => OrderExpense.fromMap(maps[i]));
  }

  Future<List<OrderExpense>> getByOrderIdOrNull(int orderId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'order_expenses',
      where: 'order_id = ? OR order_id IS NULL',
      whereArgs: [orderId],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => OrderExpense.fromMap(maps[i]));
  }

  Future<int> update(OrderExpense orderExpense) async {
    orderExpense.updatedAt = DateTime.now().millisecondsSinceEpoch;
    orderExpense.isDeleted = 0;
    orderExpense.syncStatus = 0;
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
    return await db.update(
      'order_expenses',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByOrderId(int orderId) async {
    final db = await dbHelper.database;
    return await db.update(
      'order_expenses',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
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

  // Bulk upsert order expenses
  Future<void> bulkUpsertOrderExpenses(List<OrderExpense> orderExpenses) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final orderExpense in orderExpenses) {
        batch.rawInsert('''
          INSERT INTO order_expenses (
            id, mandi_id, order_id, expense_name, expense_amount,
            expense_note, updated_at, is_deleted, sync_status
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)

          ON CONFLICT(id) DO UPDATE SET
            mandi_id = excluded.mandi_id,
            order_id = excluded.order_id,
            expense_name = excluded.expense_name,
            expense_amount = excluded.expense_amount,
            expense_note = excluded.expense_note,
            updated_at = excluded.updated_at,
            is_deleted = excluded.is_deleted,
            sync_status = excluded.sync_status

          WHERE excluded.updated_at > order_expenses.updated_at;
        ''', [
          orderExpense.id,
          orderExpense.mandiId,
          orderExpense.orderId,
          orderExpense.expenseName,
          orderExpense.expenseAmount,
          orderExpense.expenseNote,
          orderExpense.updatedAt,
          orderExpense.isDeleted ?? 0,
          orderExpense.syncStatus ?? 0,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }
}
