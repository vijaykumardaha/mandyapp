import 'dart:async';
import 'dart:developer';

import 'package:mandyapp/models/user_model.dart';
import 'package:mandyapp/sync/socket_config.dart';
import 'package:mandyapp/utils/app_helper.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

class PhoenixSocketService {
  PhoenixSocketService._();

  static final PhoenixSocketService instance = PhoenixSocketService._();

  PhoenixSocket? _socket;
  PhoenixChannel? _channel;
  bool _isConnecting = false;
  bool _isConnected = false;
  int? _mandyId;

  PhoenixSocket? get socket => _socket;
  PhoenixChannel? get channel => _channel;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnecting || _isConnected) {
      log('connect() skipped: _isConnecting=$_isConnecting, _isConnected=$_isConnected');
      return;
    }
    _isConnecting = true;

    try {
      final userData = await AppHelper.getPreferences(SocketConfig.userKey);
      if (userData == null) {
        log('No user data found, skipping socket connect');
        _isConnecting = false;
        return;
      }

      final user = User.fromJson(userData);
      _mandyId = user.mandyId;
      if (_mandyId == null) {
        log('No mandy_id found, skipping socket connect');
        _isConnecting = false;
        return;
      }

      final token = await AppHelper.getPreferences(SocketConfig.tokenKey);

      _socket = PhoenixSocket(
        SocketConfig.wsUrl,
        socketOptions: PhoenixSocketOptions(
          params: {
            'mandy_id': '$_mandyId',
            if (token != null) 'token': token,
          },
        ),
      );

      final connectedSocket = await _socket!.connect();
      if (connectedSocket == null) {
        log('PhoenixSocket.connect() returned null - server unreachable?');
        _socket?.dispose();
        _socket = null;
        _isConnecting = false;
        return;
      }

      _channel = _socket!.addChannel(
        topic: '${SocketConfig.channelPrefix}$_mandyId',
      );

      final joinPush = _channel!.join();
      await joinPush.future;

      _isConnected = true;
      _isConnecting = false;
      log('Socket connected and channel joined for mandy_id=$_mandyId');
    } catch (e, st) {
      log('Socket connect failed: $e', stackTrace: st);
      _isConnecting = false;
      _isConnected = false;
      _channel = null;
      _socket?.dispose();
      _socket = null;
    }
  }

  Future<void> disconnect() async {
    _channel?.leave();
    _channel?.close();
    _channel = null;
    _socket?.close();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
  }

  Future<void> ensureConnected() async {
    if (_isConnected && _channel != null) return;
    await connect();
  }

  Future<PushResponse?> push(String event, Map<String, dynamic> payload) async {
    await ensureConnected();

    if (_channel == null || !_isConnected) {
      log('push() skipped after ensureConnected: _channel=${_channel != null}, _isConnected=$_isConnected');
      return null;
    }

    try {
      final push = _channel!.push(event, payload);
      final response = await push.future;
      return response;
    } catch (e) {
      log('push() failed: $e');
      return null;
    }
  }

  Stream<Message>? get messages => _channel?.messages;
}
