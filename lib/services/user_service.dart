import 'package:krishimandi/models/user_model.dart';
import 'package:krishimandi/services/socket_config.dart';
import 'package:krishimandi/services/socket_service_base.dart';

class UserService extends SocketServiceBase {
  UserService._();

  static final UserService instance = UserService._();

  @override
  String get serviceName => 'UserSocket';

  @override
  String get wsUrl => SocketConfig.wsUserUrl;

  @override
  String get channelTopicPrefix => SocketConfig.userChannelPrefix;

  @override
  Map<String, String>? connectionParams(User user) {
    final mandiId = user.mandiId;
    if (mandiId == null) return null;
    return {'mandi_id': '$mandiId'};
  }
}
