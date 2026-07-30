import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';
import 'token_store.dart';

typedef SocketHandler = void Function(dynamic data);

/// Socket.io client authenticated with JWT.
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = await TokenStore.accessToken();
    if (token == null || token.isEmpty) return;

    await disconnect();
    _socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
  }

  Future<void> disconnect() async {
    _socket?.dispose();
    _socket = null;
  }

  void subscribeDocument(int documentId) {
    _socket?.emit('subscribe:document', documentId);
  }

  void unsubscribeDocument(int documentId) {
    _socket?.emit('unsubscribe:document', documentId);
  }

  void on(String event, SocketHandler handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [SocketHandler? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }
}
