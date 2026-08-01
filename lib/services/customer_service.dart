import 'dart:developer';

import 'package:krishimandi/models/user_model.dart';
import 'package:krishimandi/services/socket_config.dart';
import 'package:krishimandi/services/socket_service_base.dart';
import 'package:krishimandi/services/sync_service.dart';

class CustomerService extends SocketServiceBase {
  CustomerService._();

  static final CustomerService instance = CustomerService._();

  @override
  String get serviceName => 'CustomerSocket';

  @override
  String get wsUrl => SocketConfig.customerWsUrl;

  @override
  String get channelTopicPrefix => SocketConfig.customerChannelPrefix;

  @override
  Map<String, String>? connectionParams(User user) {
    final mandiId = user.mandiId;
    final customerId = user.id;
    if (mandiId == null || customerId == null) return null;
    return {
      'mandi_id': '$mandiId',
      'customer_id': '$customerId',
    };
  }

  /// Pushes the customer_sync event on the CustomerSyncChannel and upserts
  /// the returned tables into the local database.
  /// Returns the tables map on success, null on failure.
  Future<Map<String, dynamic>?> sync() async {
    await ensureConnected();

    if (channel == null || !isConnected) {
      log('$serviceName sync() skipped: not connected');
      return null;
    }

    try {
      final push = channel!.push('customer_sync', {});
      final response = await push.future;

      final body = response.response as Map<String, dynamic>?;
      if (body == null) {
        log('$serviceName sync() -> empty response');
        return null;
      }

      final data = body['data'] as Map<String, dynamic>?;
      final tables = data?['tables'] as Map<String, dynamic>?;
      if (tables == null || tables.isEmpty) {
        log('$serviceName sync() -> no tables in response');
        return null;
      }

      await SyncService.instance.upsertBulkResponse(tables);
      log('$serviceName sync() -> upserted ${tables.length} tables from server');
      return tables;
    } catch (e, st) {
      log('$serviceName sync() failed: $e', stackTrace: st);
      return null;
    }
  }
}
