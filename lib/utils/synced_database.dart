import 'package:mandiapp/services/sync_service.dart';
import 'package:sqflite/sqflite.dart';

const _syncedTables = {
  'users',
  'products',
  'product_variants',
  'orders',
  'order_items',
  'order_payments',
  'order_charges',
  'order_expenses',
  'charge_types',
  'customers',
  'customer_payments',
  'stocks',
  'stock_transactions',
};

class SyncedDatabase {
  final Database _db;

  SyncedDatabase(this._db);

  // ── Writes that trigger sync ──────────────────────────

  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final id = await _db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
    _sync(table, values);
    return id;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final count = await _db.update(table, values, where: where, whereArgs: whereArgs);

    final record = Map<String, dynamic>.from(values);
    if (!record.containsKey('id') && where != null && whereArgs != null && whereArgs.isNotEmpty) {
      if (RegExp(r'\bid\s*=\s*\?').hasMatch(where)) {
        record['id'] = whereArgs[0];
      }
    }
    if (record.containsKey('id')) {
      _sync(table, record);
    }

    return count;
  }

  // ── Hard deletes (no sync — used for cleanup/logout) ─

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    return _db.delete(table, where: where, whereArgs: whereArgs);
  }

  // ── Reads (pass-through) ──────────────────────────────

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
    String? groupBy,
    String? having,
  }) async {
    return _db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
      groupBy: groupBy,
      having: having,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? args]) async {
    return _db.rawQuery(sql, args);
  }

  Future<void> execute(String sql, [List<Object?>? params]) async {
    return _db.execute(sql, params);
  }

  // ── Delegates ─────────────────────────────────────────

  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) callback, {
    bool? exclusive,
  }) async {
    return _db.transaction(callback, exclusive: exclusive);
  }

  Batch batch() => _db.batch();

  // ── Internal ──────────────────────────────────────────

  void _sync(String table, Map<String, dynamic> record) {
    if (!_syncedTables.contains(table)) return;
    SyncService.instance.syncRecord(table: table, record: record);
  }
}
