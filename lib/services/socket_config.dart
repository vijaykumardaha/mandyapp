import 'app_config.dart';

class SocketConfig {
  SocketConfig._();

  static const String wsUrl = AppConfig.wsUrl;
  static const String channelPrefix = 'sync:';
  static const String userKey = 'user';
  static const String tokenKey = 'jwt_token';
  static const String lastSyncKey = 'last_sync';
}
