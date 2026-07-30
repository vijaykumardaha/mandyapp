import 'dart:async';
import 'dart:developer';

import 'package:mandiapp/models/user_model.dart';
import 'package:mandiapp/services/socket_config.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

class SocketService {
  SocketService._();

  static final SocketService instance = SocketService._();

  PhoenixSocket? _socket;
  PhoenixChannel? _channel;
  bool _isConnecting = false;
  bool _isConnected = false;
  int? _mandiId;
  final _connectionController = StreamController<bool>.broadcast();
  StreamSubscription? _closeSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _openSub;

  PhoenixSocket? get socket => _socket;
  PhoenixChannel? get channel => _channel;
  bool get isConnected => _isConnected;
  Stream<bool> get connectionStream => _connectionController.stream;

  void _onSocketClose(PhoenixSocketCloseEvent event) {
    log('Socket closed: code=${event.code} reason=${event.reason}');
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onSocketError(PhoenixSocketErrorEvent event) {
    log('Socket error: ${event.error}');
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onSocketOpen(PhoenixSocketOpenEvent event) {
    log('Socket reconnected');
    _isConnected = true;
    _connectionController.add(true);
  }

  void _listenToSocket() {
    _closeSub?.cancel();
    _errorSub?.cancel();
    _openSub?.cancel();
    if (_socket == null) return;
    _closeSub = _socket!.closeStream.listen(_onSocketClose);
    _errorSub = _socket!.errorStream.listen(_onSocketError);
    _openSub = _socket!.openStream.listen(_onSocketOpen);
  }

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
        _connectionController.add(false);
        return;
      }

      final user = User.fromJson(userData);
      _mandiId = user.mandiId;
      if (_mandiId == null) {
        log('No mandi_id found, skipping socket connect');
        _isConnecting = false;
        _connectionController.add(false);
        return;
      }

      _socket = PhoenixSocket(
        SocketConfig.wsUrl,
        socketOptions: PhoenixSocketOptions(
          params: {
            'mandi_id': '$_mandiId'
          },
        ),
      );

      final connectedSocket = await _socket!.connect();
      if (connectedSocket == null) {
        log('PhoenixSocket.connect() returned null - server unreachable?');
        _socket?.dispose();
        _socket = null;
        _isConnecting = false;
        _connectionController.add(false);
        return;
      }

      _listenToSocket();

      _channel = _socket!.addChannel(
        topic: '${SocketConfig.channelPrefix}$_mandiId',
      );

      final joinPush = _channel!.join();
      await joinPush.future;

      _isConnected = true;
      _isConnecting = false;
      _connectionController.add(true);
      log('Socket connected and channel joined for mandi_id=$_mandiId');
    } catch (e, st) {
      log('Socket connect failed: $e', stackTrace: st);
      _isConnecting = false;
      _isConnected = false;
      _connectionController.add(false);
      _channel = null;
      _socket?.dispose();
      _socket = null;
    }
  }

  Future<void> disconnect() async {
    _closeSub?.cancel();
    _errorSub?.cancel();
    _openSub?.cancel();
    _channel?.leave();
    _channel?.close();
    _channel = null;
    _socket?.close();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);
  }

  void dispose() {
    _closeSub?.cancel();
    _errorSub?.cancel();
    _openSub?.cancel();
    _connectionController.close();
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
