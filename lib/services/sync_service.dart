import 'dart:async';
import 'dart:developer';

import 'package:krishimandi/dao/charge_type_dao.dart';
import 'package:krishimandi/dao/customer_dao.dart';
import 'package:krishimandi/dao/customer_payment_dao.dart';
import 'package:krishimandi/dao/order_charge_dao.dart';
import 'package:krishimandi/dao/order_dao.dart';
import 'package:krishimandi/dao/order_expense_dao.dart';
import 'package:krishimandi/dao/order_item_dao.dart';
import 'package:krishimandi/dao/order_payment_dao.dart';
import 'package:krishimandi/dao/product_dao.dart';
import 'package:krishimandi/dao/product_variant_dao.dart';
import 'package:krishimandi/dao/stock_dao.dart';
import 'package:krishimandi/dao/user_dao.dart';
import 'package:krishimandi/dao/vegetable_dao.dart';
import 'package:krishimandi/models/charge_type_model.dart';
import 'package:krishimandi/models/customer_model.dart';
import 'package:krishimandi/models/customer_payment_model.dart';
import 'package:krishimandi/models/order_charge_model.dart';
import 'package:krishimandi/models/order_expense_model.dart';
import 'package:krishimandi/models/order_item_model.dart';
import 'package:krishimandi/models/order_model.dart';
import 'package:krishimandi/models/order_payment_model.dart';
import 'package:krishimandi/models/product_model.dart';
import 'package:krishimandi/models/product_variant_model.dart';
import 'package:krishimandi/models/stock_model.dart';
import 'package:krishimandi/models/user_model.dart';
import 'package:krishimandi/models/vegetable_model.dart';
import 'package:krishimandi/services/user_service.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  StreamSubscription? _messageSubscription;
  bool _syncing = false;

  final _tableUpdateController = StreamController<String>.broadcast();
  Stream<String> get tableUpdates => _tableUpdateController.stream;

  final _syncingController = StreamController<bool>.broadcast();
  Stream<bool> get syncingStream => _syncingController.stream;

  final CustomerDAO _customerDAO = CustomerDAO();
  final ProductDAO _productDAO = ProductDAO();
  final ProductVariantDAO _variantDAO = ProductVariantDAO();
  final OrderDAO _orderDAO = OrderDAO();
  final OrderItemDAO _orderItemDAO = OrderItemDAO();
  final OrderPaymentDAO _paymentDAO = OrderPaymentDAO();
  final OrderChargeDAO _chargeDAO = OrderChargeDAO();
  final OrderExpenseDao _expenseDAO = OrderExpenseDao();
  final ChargeTypeDAO _chargeTypeDAO = ChargeTypeDAO();
  final UserDAO _userDAO = UserDAO();
  final CustomerPaymentDAO _customerPaymentDAO = CustomerPaymentDAO();
  final VegetableDAO _vegetableDAO = VegetableDAO();
  final StockDAO _stockDAO = StockDAO();

  bool get isSyncing => _syncing;

  // ──────────────────────────────────────────────
  //  Pending record check
  // ──────────────────────────────────────────────

  /// Counts records with sync_status=0 across all synced tables
  /// (plus vegetables). Used to guard destructive actions like logout.
  Future<int> pendingRecordCount() async {
    final db = await _customerDAO.dbHelper.database;
    final tables = [...DbTables.synced, DbTables.vegetables];
    var count = 0;
    for (final table in tables) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM $table WHERE sync_status = 0',
      );
      count += (result.first['count'] as int?) ?? 0;
    }
    return count;
  }

  // ──────────────────────────────────────────────
  //  Broadcast listeners
  // ──────────────────────────────────────────────

  void startListening() {
    _messageSubscription?.cancel();
    _messageSubscription = null;

    _messageSubscription = UserService.instance.messages?.listen(
      _onMessage,
    );
    log('SyncService: started listening for broadcasts');
  }

  void stopListening() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    log('SyncService: stopped listening');
  }

  void _onMessage(Message message) {
    final eventName = message.event.value;

    if (eventName == 'record_updated') {
      _handleRecordUpdated(message.payload);
    }
  }

  Future<void> _handleRecordUpdated(dynamic payload) async {
    if (payload is! Map<String, dynamic>) return;

    final table = payload['table'] as String?;
    final record = payload['record'] as Map<String, dynamic>?;
    if (table == null || record == null) return;

    log('SyncService: record_updated → $table');
    await _upsertRecord(table, record);
  }

  // ──────────────────────────────────────────────
  //  Entity sync — single record push
  // ──────────────────────────────────────────────

  /// Fire-and-forget: push a single record to the server.
  /// Call this after any local create/update.
  void syncRecord({
    required String table,
    required Map<String, dynamic> record,
  }) {
    if (!UserService.instance.isConnected) return;
    entitySync(table: table, record: record);
  }

  /// Awaitable version — returns the server response on success, null on failure.
  Future<Map<String, dynamic>?> entitySync({
    required String table,
    required Map<String, dynamic> record,
  }) async {
    final response = await UserService.instance.push(
      'entity_sync',
      {
        'table': table,
        'record': record,
      },
    );

    if (response == null) {
      log('SyncService: entity_sync → no response');
      return null;
    }

    final body = response.response as Map<String, dynamic>?;
    if (body == null) {
      log('SyncService: entity_sync → empty response');
      return null;
    }

    if (body['success'] == true) {
      log('SyncService: entity_sync → success for $table');
      await _markRecordSynced(table, record);
      return body;
    }

    log('SyncService: entity_sync → error: ${body['message']}');
    return null;
  }

  // ──────────────────────────────────────────────
  //  Bulk sync — push pending + pull full data
  // ──────────────────────────────────────────────

  /// Collects all records with sync_status=0, pushes them,
  /// then upserts the full server response.
  /// Returns the response tables map on success, null on failure.
  Future<Map<String, dynamic>?> bulkSync() async {
    if (_syncing) {
      log('SyncService: bulkSync already in progress, skipping');
      return null;
    }
    _syncing = true;
    _syncingController.add(true);

    try {
      final pendingTables = await _collectPendingRecords();
      log('SyncService: bulkSync → sending ${pendingTables.length} tables');

      final response = await UserService.instance.push(
        'bulk_sync',
        {
          'tables': pendingTables,
        },
      );

      if (response == null) {
        log('SyncService: bulkSync → no response');
        return null;
      }

      final body = response.response as Map<String, dynamic>?;
      if (body == null) {
        log('SyncService: bulkSync → empty response');
        return null;
      }

      if (!response.isOk) {
        log('SyncService: bulkSync → rejected (status: ${response.status}): ${body['message']}');
        return null;
      }

      final tables = body['tables'] as Map<String, dynamic>?;
      if (tables != null) {
        await upsertBulkResponse(tables);
        log('SyncService: bulkSync → upserted ${tables.length} tables from server');
      }

      await _markAllSynced();

      return tables;
    } catch (e, st) {
      log('SyncService: bulkSync failed: $e', stackTrace: st);
      return null;
    } finally {
      _syncing = false;
      _syncingController.add(false);
    }
  }

  Future<Map<String, List>> _collectPendingRecords() async {
    final db = await _customerDAO.dbHelper.database;
    final tables = <String, List>{};

    // Each table: query sync_status=0, map to JSON
    final customers = await db
        .query(DbTables.customers, where: 'sync_status = ?', whereArgs: [0]);
    if (customers.isNotEmpty) {
      tables[DbTables.customers] =
          customers.map((m) => Customer.fromJson(m).toJson()).toList();
    }

    final products = await db
        .query(DbTables.products, where: 'sync_status = ?', whereArgs: [0]);
    if (products.isNotEmpty) {
      tables[DbTables.products] =
          products.map((m) => Product.fromJson(m).toJson()).toList();
    }

    final variants = await db.query(DbTables.productVariants,
        where: 'sync_status = ?', whereArgs: [0]);
    if (variants.isNotEmpty) {
      tables[DbTables.productVariants] =
          variants.map((m) => ProductVariant.fromJson(m).toJson()).toList();
    }

    final orders = await db
        .query(DbTables.orders, where: 'sync_status = ?', whereArgs: [0]);
    if (orders.isNotEmpty) {
      tables[DbTables.orders] =
          orders.map((m) => Order.fromJson(m).toJson()).toList();
    }

    final orderItems = await db
        .query(DbTables.orderItems, where: 'sync_status = ?', whereArgs: [0]);
    if (orderItems.isNotEmpty) {
      tables[DbTables.orderItems] =
          orderItems.map((m) => OrderItem.fromJson(m).toJson()).toList();
    }

    final orderPayments = await db.query(DbTables.orderPayments,
        where: 'sync_status = ?', whereArgs: [0]);
    if (orderPayments.isNotEmpty) {
      tables[DbTables.orderPayments] =
          orderPayments.map((m) => OrderPayment.fromJson(m).toJson()).toList();
    }

    final orderCharges = await db
        .query(DbTables.orderCharges, where: 'sync_status = ?', whereArgs: [0]);
    if (orderCharges.isNotEmpty) {
      tables[DbTables.orderCharges] =
          orderCharges.map((m) => OrderCharge.fromMap(m).toMap()).toList();
    }

    final orderExpenses = await db.query(DbTables.orderExpenses,
        where: 'sync_status = ?', whereArgs: [0]);
    if (orderExpenses.isNotEmpty) {
      tables[DbTables.orderExpenses] =
          orderExpenses.map((m) => OrderExpense.fromMap(m).toMap()).toList();
    }

    final chargeTypes = await db
        .query(DbTables.chargeTypes, where: 'sync_status = ?', whereArgs: [0]);
    if (chargeTypes.isNotEmpty) {
      tables[DbTables.chargeTypes] =
          chargeTypes.map((m) => ChargeType.fromJson(m).toJson()).toList();
    }

    final users = await db
        .query(DbTables.users, where: 'sync_status = ?', whereArgs: [0]);
    if (users.isNotEmpty) {
      tables[DbTables.users] =
          users.map((m) => User.fromJson(m).toJson()).toList();
    }

    final customerPayments = await db.query(DbTables.customerPayments,
        where: 'sync_status = ?', whereArgs: [0]);
    if (customerPayments.isNotEmpty) {
      tables[DbTables.customerPayments] = customerPayments
          .map((m) => CustomerPayment.fromJson(m).toJson())
          .toList();
    }

    final vegetables = await db
        .query(DbTables.vegetables, where: 'sync_status = ?', whereArgs: [0]);
    if (vegetables.isNotEmpty) {
      tables[DbTables.vegetables] =
          vegetables.map((m) => Vegetable.fromJson(m).toJson()).toList();
    }

    final stocks = await db
        .query(DbTables.stocks, where: 'sync_status = ?', whereArgs: [0]);
    if (stocks.isNotEmpty) {
      tables[DbTables.stocks] =
          stocks.map((m) => Stock.fromJson(m).toJson()).toList();
    }

    final stockTransactions = await db.query(DbTables.stockTransactions,
        where: 'sync_status = ?', whereArgs: [0]);
    if (stockTransactions.isNotEmpty) {
      tables[DbTables.stockTransactions] = stockTransactions
          .map((m) => StockTransaction.fromJson(m).toJson())
          .toList();
    }

    return tables;
  }

  // ──────────────────────────────────────────────
  //  Upsert bulk response from server
  // ──────────────────────────────────────────────

  Future<void> upsertBulkResponse(Map<String, dynamic> tables) async {
    for (final entry in tables.entries) {
      final tableName = entry.key;
      final records = entry.value;
      if (records is List) {
        for (final record in records) {
          if (record is Map<String, dynamic>) {
            try {
              await _upsertRecord(tableName, record);
            } catch (e) {
              log('SyncService: failed to upsert $tableName: $e');
            }
          }
        }
      }
    }
  }

  // ──────────────────────────────────────────────
  //  Mark all pending records as synced
  // ──────────────────────────────────────────────

  Future<void> _markAllSynced() async {
    final db = await _customerDAO.dbHelper.database;
    final tables = [...DbTables.synced, DbTables.vegetables];
    for (final table in tables) {
      await db.execute(
        'UPDATE $table SET sync_status = 1 WHERE sync_status = 0',
      );
    }
  }

  // ──────────────────────────────────────────────
  //  Mark a single record as synced
  // ──────────────────────────────────────────────

  Future<void> _markRecordSynced(
      String table, Map<String, dynamic> record) async {
    final db = await _customerDAO.dbHelper.database;
    final id = record['id'];
    if (id == null) return;
    // Raw write: must NOT go through SyncedDatabase.update, which would
    // trigger another sync push and cause an infinite entity_sync loop.
    await db.execute(
      'UPDATE $table SET sync_status = 1 WHERE id = ?',
      [id],
    );
  }

  // ──────────────────────────────────────────────
  //  Connect + sync convenience method
  // ──────────────────────────────────────────────

  /// Connects the websocket, starts broadcast listener, then runs bulkSync.
  /// Call this after login/registration.
  Future<void> connectAndSync() async {
    await UserService.instance.connect();
    startListening();
    await bulkSync();
  }

  // ──────────────────────────────────────────────
  //  Single record upsert dispatcher
  // ──────────────────────────────────────────────

  Future<void> _upsertRecord(String table, Map<String, dynamic> record) async {
    switch (table) {
      case DbTables.customers:
        await _customerDAO.bulkUpsertCustomers([Customer.fromJson(record)]);
        break;
      case DbTables.products:
        await _productDAO.bulkUpsertProducts([Product.fromJson(record)]);
        break;
      case DbTables.productVariants:
        await _variantDAO.bulkUpsertVariants([ProductVariant.fromJson(record)]);
        break;
      case DbTables.orders:
        await _orderDAO.bulkUpsertOrders([Order.fromJson(record)]);
        break;
      case DbTables.orderItems:
        await _orderItemDAO.bulkUpsertOrderItems([OrderItem.fromJson(record)]);
        break;
      case DbTables.orderPayments:
        await _paymentDAO
            .bulkUpsertOrderPayments([OrderPayment.fromJson(record)]);
        break;
      case DbTables.orderCharges:
        await _chargeDAO.bulkUpsertOrderCharges([OrderCharge.fromMap(record)]);
        break;
      case DbTables.orderExpenses:
        await _expenseDAO
            .bulkUpsertOrderExpenses([OrderExpense.fromMap(record)]);
        break;
      case DbTables.chargeTypes:
        await _chargeTypeDAO
            .bulkUpsertChargeTypes([ChargeType.fromJson(record)]);
        break;
      case DbTables.users:
        await _userDAO.bulkUpsertUsers([User.fromJson(record)]);
        break;
      case DbTables.customerPayments:
        await _customerPaymentDAO
            .bulkUpsertCustomerPayments([CustomerPayment.fromJson(record)]);
        break;
      case DbTables.vegetables:
        await _vegetableDAO.bulkUpsertVegetables([Vegetable.fromJson(record)]);
        break;
      case DbTables.stocks:
        await _stockDAO.bulkUpsertStocks([Stock.fromJson(record)]);
        break;
      case DbTables.stockTransactions:
        await _stockDAO
            .bulkUpsertStockTransactions([StockTransaction.fromJson(record)]);
        break;
      default:
        log('SyncService: unknown table "$table", skipping');
    }
    _tableUpdateController.add(table);
  }
}
