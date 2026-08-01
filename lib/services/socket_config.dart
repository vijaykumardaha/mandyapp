import 'package:mandiapp/utils/constants.dart';

import 'app_config.dart';

class SocketConfig {
  SocketConfig._();

  static const String wsUserUrl = 'ws://${AppConfig.host}/user/websocket';
  static const String customerWsUrl =
      'ws://${AppConfig.host}/customer/websocket';

  static const String userChannelPrefix = 'user:';
  static const String customerChannelPrefix = 'customer:';

  static const String userKey = PrefsKeys.user;
}
