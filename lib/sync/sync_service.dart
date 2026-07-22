import 'dart:async';

import 'package:mandyapp/dao/charge_type_dao.dart';
import 'package:mandyapp/dao/customer_dao.dart';
import 'package:mandyapp/dao/order_charge_dao.dart';
import 'package:mandyapp/dao/order_dao.dart';
import 'package:mandyapp/dao/order_expense_dao.dart';
import 'package:mandyapp/dao/order_item_dao.dart';
import 'package:mandyapp/dao/order_payment_dao.dart';
import 'package:mandyapp/dao/product_dao.dart';
import 'package:mandyapp/dao/product_variant_dao.dart';
import 'package:mandyapp/dao/user_dao.dart';
import 'package:mandyapp/models/charge_type_model.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/order_charge_model.dart';
import 'package:mandyapp/models/order_expense_model.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/models/order_payment_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/models/user_model.dart';
import 'package:mandyapp/sync/phoenix_socket_service.dart';
import 'package:mandyapp/sync/socket_config.dart';
import 'package:mandyapp/utils/app_helper.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  StreamSubscription? _messageSubscription;
  bool _listening = false;

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

  void startListening() {
    if (_listening) return;
    _listening = true;

    _messageSubscription = PhoenixSocketService.instance.messages?.listen(
      _onMessage,
    );
  }

  void stopListening() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _listening = false;
  }

  void _onMessage(Message message) {
    final eventName = message.event.value;

    if (eventName == 'record_updated') {
      _handleRecordUpdated(message.payload);
    } else if (eventName == 'records_updated') {
      _handleRecordsUpdated(message.payload);
    }
  }

  Future<void> _handleRecordUpdated(dynamic payload) async {
    if (payload is! Map<String, dynamic>) return;

    final table = payload['table'] as String?;
    final record = payload['record'] as Map<String, dynamic>?;
    if (table == null || record == null) return;

    await _upsertRecord(table, record);
  }

  Future<void> _handleRecordsUpdated(dynamic payload) async {
    if (payload is! Map<String, dynamic>) return;

    final tables = payload['tables'] as Map<String, dynamic>?;
    if (tables == null) return;

    for (final entry in tables.entries) {
      final tableName = entry.key;
      final records = entry.value;
      if (records is List) {
        for (final record in records) {
          if (record is Map<String, dynamic>) {
            await _upsertRecord(tableName, record);
          }
        }
      }
    }
  }

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
    }
  }

  // --- Outgoing: Entity Sync ---

  Future<Map<String, dynamic>?> entitySync({
    required String table,
    required String action,
    required Map<String, dynamic> record,
  }) async {
    final response = await PhoenixSocketService.instance.push(
      'entity_sync',
      {
        'table': table,
        'action': action,
        'record': record,
      },
    );

    if (response == null || !response.isOk) return null;
    return response.response as Map<String, dynamic>?;
  }

  // --- Outgoing: Bulk Sync ---

  Future<Map<String, dynamic>?> bulkSync() async {
    final lastSync = await AppHelper.getPreferences(SocketConfig.lastSyncKey);

    final pendingTables = <String, List>{};

    pendingTables['customers'] = await _getPendingRecords(
      'customers',
      (maps) => maps.map((m) => Customer.fromJson(m).toJson()).toList(),
    );
    pendingTables['products'] = await _getPendingRecords(
      'products',
      (maps) => maps.map((m) => Product.fromJson(m).toJson()).toList(),
    );
    pendingTables['product_variants'] = await _getPendingRecords(
      'product_variants',
      (maps) => maps.map((m) => ProductVariant.fromJson(m).toJson()).toList(),
    );
    pendingTables['orders'] = await _getPendingRecords(
      'orders',
      (maps) => maps.map((m) => Order.fromJson(m).toJson()).toList(),
    );
    pendingTables['order_items'] = await _getPendingRecords(
      'order_items',
      (maps) => maps.map((m) => OrderItem.fromJson(m).toJson()).toList(),
    );
    pendingTables['order_payments'] = await _getPendingRecords(
      'order_payments',
      (maps) => maps.map((m) => OrderPayment.fromJson(m).toJson()).toList(),
    );
    pendingTables['order_charges'] = await _getPendingRecords(
      'order_charges',
      (maps) => maps.map((m) => OrderCharge.fromMap(m).toMap()).toList(),
    );
    pendingTables['order_expenses'] = await _getPendingRecords(
      'order_expenses',
      (maps) => maps.map((m) => OrderExpense.fromMap(m).toMap()).toList(),
    );
    pendingTables['charge_types'] = await _getPendingRecords(
      'charge_types',
      (maps) => maps.map((m) => ChargeType.fromJson(m).toJson()).toList(),
    );
    pendingTables['users'] = await _getPendingRecords(
      'users',
      (maps) => maps.map((m) => User.fromJson(m).toJson()).toList(),
    );

    final response = await PhoenixSocketService.instance.push(
      'bulk_sync',
      {
        'last_sync': lastSync ?? 0,
        'tables': pendingTables,
      },
    );

    if (response == null || !response.isOk) return null;

    await AppHelper.savePreferences(
      SocketConfig.lastSyncKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    return response.response as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> _getPendingRecords(
    String table,
    List<Map<String, dynamic>> Function(List<Map<String, dynamic>> maps) mapper,
  ) async {
    final db = await _getDatabase();
    final maps = await db.query(
      table,
      where: 'sync_status = ?',
      whereArgs: [0],
    );
    return mapper(maps);
  }

  Future<dynamic> _getDatabase() async {
    // Access DBHelper through any DAO's dbHelper instance
    return _customerDAO.dbHelper.database;
  }
}
