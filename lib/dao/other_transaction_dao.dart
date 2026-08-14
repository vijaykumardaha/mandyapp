import 'package:krishimandi/models/other_transaction_model.dart';
import 'package:krishimandi/utils/app_helper.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/utils/db_helper.dart';

class OtherTransactionDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertTransaction(OtherTransaction transaction) async {
    transaction.id = DBHelper.generateUuidInt();
    transaction.mandiId = await AppHelper.getCurrentMandiId();
    transaction.updatedAt = DateTime.now().millisecondsSinceEpoch;
    transaction.isDeleted = 0;
    transaction.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.insert(DbTables.otherTransactions, transaction.toJson());
  }

  Future<List<OtherTransaction>> getAllTransactions() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.otherTransactions,
      where: '${DbColumns.isDeleted} = ?',
      whereArgs: [0],
      orderBy: '${DbColumns.updatedAt} DESC',
    );
    return List.generate(
        maps.length, (i) => OtherTransaction.fromJson(maps[i]));
  }

  Future<OtherTransaction?> getTransactionById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.otherTransactions,
      where: '${DbColumns.id} = ? AND ${DbColumns.isDeleted} = ?',
      whereArgs: [id, 0],
    );
    if (maps.isNotEmpty) {
      return OtherTransaction.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateTransaction(OtherTransaction transaction) async {
    transaction.updatedAt = DateTime.now().millisecondsSinceEpoch;
    transaction.isDeleted = 0;
    transaction.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.update(
      DbTables.otherTransactions,
      transaction.toJson(),
      where: '${DbColumns.id} = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      DbTables.otherTransactions,
      {
        DbColumns.isDeleted: 1,
        DbColumns.updatedAt: DateTime.now().millisecondsSinceEpoch,
        DbColumns.syncStatus: 0,
      },
      where: '${DbColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> bulkUpsertTransactions(
      List<OtherTransaction> transactions) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final transaction in transactions) {
        batch.rawInsert('''
          INSERT INTO ${DbTables.otherTransactions} (
            ${DbColumns.id}, ${DbColumns.mandiId}, ${DbColumns.transactionNote},
            ${DbColumns.transactionType}, ${DbColumns.transactionAmount},
            ${DbColumns.updatedAt}, ${DbColumns.isDeleted}, ${DbColumns.syncStatus}
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)

          ON CONFLICT(${DbColumns.id}) DO UPDATE SET
            ${DbColumns.mandiId} = excluded.${DbColumns.mandiId},
            ${DbColumns.transactionNote} = excluded.${DbColumns.transactionNote},
            ${DbColumns.transactionType} = excluded.${DbColumns.transactionType},
            ${DbColumns.transactionAmount} = excluded.${DbColumns.transactionAmount},
            ${DbColumns.updatedAt} = excluded.${DbColumns.updatedAt},
            ${DbColumns.isDeleted} = excluded.${DbColumns.isDeleted},
            ${DbColumns.syncStatus} = excluded.${DbColumns.syncStatus}

          WHERE excluded.${DbColumns.updatedAt} >
            ${DbTables.otherTransactions}.${DbColumns.updatedAt};
        ''', [
          transaction.id,
          transaction.mandiId,
          transaction.transactionNote,
          transaction.transactionType,
          transaction.transactionAmount,
          transaction.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
          transaction.isDeleted ?? 0,
          1,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }
}
