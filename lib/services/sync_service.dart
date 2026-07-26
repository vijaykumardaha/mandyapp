import 'dart:async';
import 'dart:developer';

import 'package:mandyapp/dao/charge_type_dao.dart';
import 'package:mandyapp/dao/customer_dao.dart';
import 'package:mandyapp/dao/customer_payment_dao.dart';
import 'package:mandyapp/dao/order_charge_dao.dart';
import 'package:mandyapp/dao/order_dao.dart';
import 'package:mandyapp/dao/order_expense_dao.dart';
import 'package:mandyapp/dao/order_item_dao.dart';
import 'package:mandyapp/dao/order_payment_dao.dart';
import 'package:mandyapp/dao/product_dao.dart';
import 'package:mandyapp/dao/product_variant_dao.dart';
import 'package:mandyapp/dao/user_dao.dart';
import 'package:mandyapp/dao/vegetable_dao.dart';
import 'package:mandyapp/models/charge_type_model.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/customer_payment_model.dart';
import 'package:mandyapp/models/order_charge_model.dart';
import 'package:mandyapp/models/order_expense_model.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/models/order_payment_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/models/user_model.dart';
import 'package:mandyapp/models/vegetable_model.dart';
import 'package:mandyapp/services/socket_service.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  StreamSubscription? _messageSubscription;
  bool _listening = false;
  bool _syncing = false;

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

  bool get isSyncing => _syncing;

  // ──────────────────────────────────────────────
  //  Broadcast listeners
  // ──────────────────────────────────────────────

  void startListening() {
    if (_listening) return;
    _listening = true;

    _messageSubscription = SocketService.instance.messages?.listen(
      _onMessage,
    );
    log('SyncService: started listening for broadcasts');
  }

  void stopListening() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _listening = false;
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
    if (!SocketService.instance.isConnected) return;
    entitySync(table: table, record: record);
  }

  /// Awaitable version — returns the server response on success, null on failure.
  Future<Map<String, dynamic>?> entitySync({
    required String table,
    required Map<String, dynamic> record,
  }) async {
    final response = await SocketService.instance.push(
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

    try {
      final pendingTables = await _collectPendingRecords();
      log('SyncService: bulkSync → sending ${pendingTables.length} tables');

      final response = await SocketService.instance.push(
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

      final tables = body['tables'] as Map<String, dynamic>?;
      if (tables != null) {
        await _upsertBulkResponse(tables);
        log('SyncService: bulkSync → upserted ${tables.length} tables from server');
      }

      await _markAllSynced();

      return tables;
    } catch (e, st) {
      log('SyncService: bulkSync failed: $e', stackTrace: st);
      return null;
    } finally {
      _syncing = false;
    }
  }

  // ──────────────────────────────────────────────
  //  Collect pending (sync_status=0) records
  // ──────────────────────────────────────────────

  Future<Map<String, List>> _collectPendingRecords() async {
    final db = await _customerDAO.dbHelper.database;
    final tables = <String, List>{};

    // Each table: query sync_status=0, map to JSON
    final customers = await db.query('customers', where: 'sync_status = ?', whereArgs: [0]);
    if (customers.isNotEmpty) {
      tables['customers'] = customers.map((m) => Customer.fromJson(m).toJson()).toList();
    }

    final products = await db.query('products', where: 'sync_status = ?', whereArgs: [0]);
    if (products.isNotEmpty) {
      tables['products'] = products.map((m) => Product.fromJson(m).toJson()).toList();
    }

    final variants = await db.query('product_variants', where: 'sync_status = ?', whereArgs: [0]);
    if (variants.isNotEmpty) {
      tables['product_variants'] = variants.map((m) => ProductVariant.fromJson(m).toJson()).toList();
    }

    final orders = await db.query('orders', where: 'sync_status = ?', whereArgs: [0]);
    if (orders.isNotEmpty) {
      tables['orders'] = orders.map((m) => Order.fromJson(m).toJson()).toList();
    }

    final orderItems = await db.query('order_items', where: 'sync_status = ?', whereArgs: [0]);
    if (orderItems.isNotEmpty) {
      tables['order_items'] = orderItems.map((m) => OrderItem.fromJson(m).toJson()).toList();
    }

    final orderPayments = await db.query('order_payments', where: 'sync_status = ?', whereArgs: [0]);
    if (orderPayments.isNotEmpty) {
      tables['order_payments'] = orderPayments.map((m) => OrderPayment.fromJson(m).toJson()).toList();
    }

    final orderCharges = await db.query('order_charges', where: 'sync_status = ?', whereArgs: [0]);
    if (orderCharges.isNotEmpty) {
      tables['order_charges'] = orderCharges.map((m) => OrderCharge.fromMap(m).toMap()).toList();
    }

    final orderExpenses = await db.query('order_expenses', where: 'sync_status = ?', whereArgs: [0]);
    if (orderExpenses.isNotEmpty) {
      tables['order_expenses'] = orderExpenses.map((m) => OrderExpense.fromMap(m).toMap()).toList();
    }

    final chargeTypes = await db.query('charge_types', where: 'sync_status = ?', whereArgs: [0]);
    if (chargeTypes.isNotEmpty) {
      tables['charge_types'] = chargeTypes.map((m) => ChargeType.fromJson(m).toJson()).toList();
    }

    final users = await db.query('users', where: 'sync_status = ?', whereArgs: [0]);
    if (users.isNotEmpty) {
      tables['users'] = users.map((m) => User.fromJson(m).toJson()).toList();
    }

    final customerPayments = await db.query('customer_payments', where: 'sync_status = ?', whereArgs: [0]);
    if (customerPayments.isNotEmpty) {
      tables['customer_payments'] = customerPayments.map((m) => CustomerPayment.fromJson(m).toJson()).toList();
    }

    final vegetables = await db.query('vegetables', where: 'sync_status = ?', whereArgs: [0]);
    if (vegetables.isNotEmpty) {
      tables['vegetables'] = vegetables.map((m) => Vegetable.fromJson(m).toJson()).toList();
    }

    return tables;
  }

  // ──────────────────────────────────────────────
  //  Upsert bulk response from server
  // ──────────────────────────────────────────────

  Future<void> _upsertBulkResponse(Map<String, dynamic> tables) async {
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
    final tables = [
      'customers',
      'products',
      'product_variants',
      'orders',
      'order_items',
      'order_payments',
      'order_charges',
      'order_expenses',
      'charge_types',
      'users',
      'customer_payments',
      'vegetables',
    ];
    for (final table in tables) {
      await db.update(table, {'sync_status': 1}, where: 'sync_status = ?', whereArgs: [0]);
    }
  }

  // ──────────────────────────────────────────────
  //  Mark a single record as synced
  // ──────────────────────────────────────────────

  Future<void> _markRecordSynced(String table, Map<String, dynamic> record) async {
    final db = await _customerDAO.dbHelper.database;
    final id = record['id'];
    if (id == null) return;
    await db.update(
      table,
      {'sync_status': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ──────────────────────────────────────────────
  //  Connect + sync convenience method
  // ──────────────────────────────────────────────

  /// Connects the websocket, starts broadcast listener, then runs bulkSync.
  /// Call this after login/registration.
  Future<void> connectAndSync() async {
    await SocketService.instance.connect();
    startListening();
    await bulkSync();
  }

  // ──────────────────────────────────────────────
  //  Single record upsert dispatcher
  // ──────────────────────────────────────────────

  Future<void> _upsertRecord(String table, Map<String, dynamic> record) async {
    switch (table) {
      case 'customers':
        await _customerDAO.bulkUpsertCustomers([Customer.fromJson(record)]);
        break;
      case 'products':
        await _productDAO.bulkUpsertProducts([Product.fromJson(record)]);
        break;
      case 'product_variants':
        await _variantDAO.bulkUpsertVariants([ProductVariant.fromJson(record)]);
        break;
      case 'orders':
        await _orderDAO.bulkUpsertOrders([Order.fromJson(record)]);
        break;
      case 'order_items':
        await _orderItemDAO.bulkUpsertOrderItems([OrderItem.fromJson(record)]);
        break;
      case 'order_payments':
        await _paymentDAO.bulkUpsertOrderPayments([OrderPayment.fromJson(record)]);
        break;
      case 'order_charges':
        await _chargeDAO.bulkUpsertOrderCharges([OrderCharge.fromMap(record)]);
        break;
      case 'order_expenses':
        await _expenseDAO.bulkUpsertOrderExpenses([OrderExpense.fromMap(record)]);
        break;
      case 'charge_types':
        await _chargeTypeDAO.bulkUpsertChargeTypes([ChargeType.fromJson(record)]);
        break;
      case 'users':
        await _userDAO.bulkUpsertUsers([User.fromJson(record)]);
        break;
      case 'customer_payments':
        await _customerPaymentDAO.bulkUpsertCustomerPayments([CustomerPayment.fromJson(record)]);
        break;
      case 'vegetables':
        await _vegetableDAO.bulkUpsertVegetables([Vegetable.fromJson(record)]);
        break;
      default:
        log('SyncService: unknown table "$table", skipping');
    }
  }
}
