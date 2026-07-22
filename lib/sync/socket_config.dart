class SocketConfig {
  SocketConfig._();

  static const String wsUrl = 'ws://192.168.1.6:4000/socket/websocket';
  static const String channelPrefix = 'sync:';
  static const String userKey = 'user';
  static const String tokenKey = 'jwt_token';
  static const String lastSyncKey = 'last_sync';
}
