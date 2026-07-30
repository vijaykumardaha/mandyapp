import 'package:mandiapp/models/stock_model.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/utils/db_helper.dart';

class StockDAO {
  final dbHelper = DBHelper.instance;

  Future<int> insertStock(Stock stock) async {
    stock.id = DBHelper.generateUuidInt();
    stock.mandiId = await AppHelper.getCurrentMandiId();
    stock.updatedAt = DateTime.now().millisecondsSinceEpoch;
    stock.isDeleted = 0;
    stock.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.insert('stocks', stock.toJson());
  }

  Future<List<Stock>> getAllStocks() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stocks',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Stock.fromJson(maps[i]));
  }

  Future<Stock?> getStockById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stocks',
      where: 'id = ? AND is_deleted = ?',
      whereArgs: [id, 0],
    );
    if (maps.isNotEmpty) {
      return Stock.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Stock>> getStocksBySeller(int sellerId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stocks',
      where: 'seller_id = ? AND is_deleted = ?',
      whereArgs: [sellerId, 0],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Stock.fromJson(maps[i]));
  }

  Future<List<Stock>> getStocksByProduct(int productId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stocks',
      where: 'product_id = ? AND is_deleted = ?',
      whereArgs: [productId, 0],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Stock.fromJson(maps[i]));
  }

  Future<int> updateStock(Stock stock) async {
    stock.updatedAt = DateTime.now().millisecondsSinceEpoch;
    stock.isDeleted = 0;
    stock.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.update(
      'stocks',
      stock.toJson(),
      where: 'id = ?',
      whereArgs: [stock.id],
    );
  }

  Future<int> deleteStock(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'stocks',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreStock(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'stocks',
      {
        'is_deleted': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> bulkUpsertStocks(List<Stock> stocks) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final stock in stocks) {
        batch.rawInsert('''
          INSERT INTO stocks (
            id, mandi_id, seller_id, product_id, product_variant_id,
            initial_quantity, quantity, sold_quantity, loss_quantity,
            purchase_amount, sold_amount, updated_at, sync_status, is_deleted
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

          ON CONFLICT(id) DO UPDATE SET
            mandi_id = excluded.mandi_id,
            seller_id = excluded.seller_id,
            product_id = excluded.product_id,
            product_variant_id = excluded.product_variant_id,
            initial_quantity = excluded.initial_quantity,
            quantity = excluded.quantity,
            sold_quantity = excluded.sold_quantity,
            loss_quantity = excluded.loss_quantity,
            purchase_amount = excluded.purchase_amount,
            sold_amount = excluded.sold_amount,
            updated_at = excluded.updated_at,
            sync_status = excluded.sync_status,
            is_deleted = excluded.is_deleted

          WHERE excluded.updated_at > stocks.updated_at;
        ''', [
          stock.id,
          stock.mandiId,
          stock.sellerId,
          stock.productId,
          stock.productVariantId,
          stock.initialQuantity,
          stock.quantity,
          stock.soldQuantity,
          stock.lossQuantity,
          stock.purchaseAmount,
          stock.soldAmount,
          stock.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
          stock.syncStatus ?? 1,
          stock.isDeleted ?? 0,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }

  // ── Stock Transaction Methods ──────────────────────────

  Future<int> insertStockTransaction(StockTransaction transaction) async {
    transaction.id = DBHelper.generateUuidInt();
    transaction.mandiId = await AppHelper.getCurrentMandiId();
    transaction.updatedAt = DateTime.now().millisecondsSinceEpoch;
    transaction.isDeleted = 0;
    transaction.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.insert('stock_transactions', transaction.toJson());
  }

  Future<List<StockTransaction>> getAllStockTransactions() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_transactions',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => StockTransaction.fromJson(maps[i]));
  }

  Future<StockTransaction?> getStockTransactionById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_transactions',
      where: 'id = ? AND is_deleted = ?',
      whereArgs: [id, 0],
    );
    if (maps.isNotEmpty) {
      return StockTransaction.fromJson(maps.first);
    }
    return null;
  }

  Future<List<StockTransaction>> getTransactionsByStock(int stockId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_transactions',
      where: 'stock_id = ? AND is_deleted = ?',
      whereArgs: [stockId, 0],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => StockTransaction.fromJson(maps[i]));
  }

  Future<List<StockTransaction>> getTransactionsByBuyer(int buyerId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_transactions',
      where: 'buyer_id = ? AND is_deleted = ?',
      whereArgs: [buyerId, 0],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => StockTransaction.fromJson(maps[i]));
  }

  Future<List<StockTransaction>> getTransactionsByBill(int billId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_transactions',
      where: 'bill_id = ? AND is_deleted = ?',
      whereArgs: [billId, 0],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => StockTransaction.fromJson(maps[i]));
  }

  Future<int> updateStockTransaction(StockTransaction transaction) async {
    transaction.updatedAt = DateTime.now().millisecondsSinceEpoch;
    transaction.isDeleted = 0;
    transaction.syncStatus = 0;
    final db = await dbHelper.database;
    return await db.update(
      'stock_transactions',
      transaction.toJson(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteStockTransaction(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'stock_transactions',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'sync_status': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> bulkUpsertStockTransactions(List<StockTransaction> transactions) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final txn in transactions) {
        batch.rawInsert('''
          INSERT INTO stock_transactions (
            id, stock_id, mandi_id, product_id, product_variant_id,
            buyer_id, bill_id, buy_quantity, total_amount,
            updated_at, sync_status, is_deleted
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

          ON CONFLICT(id) DO UPDATE SET
            stock_id = excluded.stock_id,
            mandi_id = excluded.mandi_id,
            product_id = excluded.product_id,
            product_variant_id = excluded.product_variant_id,
            buyer_id = excluded.buyer_id,
            bill_id = excluded.bill_id,
            buy_quantity = excluded.buy_quantity,
            total_amount = excluded.total_amount,
            updated_at = excluded.updated_at,
            sync_status = excluded.sync_status,
            is_deleted = excluded.is_deleted

          WHERE excluded.updated_at > stock_transactions.updated_at;
        ''', [
          txn.id,
          txn.stockId,
          txn.mandiId,
          txn.productId,
          txn.productVariantId,
          txn.buyerId,
          txn.billId,
          txn.buyQuantity,
          txn.totalAmount,
          txn.updatedAt ?? DateTime.now().millisecondsSinceEpoch,
          txn.syncStatus ?? 1,
          txn.isDeleted ?? 0,
        ]);
      }

      await batch.commit(noResult: true);
    });
  }
}
