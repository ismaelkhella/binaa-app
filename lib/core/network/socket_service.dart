import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import '../../data/models/community.dart';

class SocketService {
  final TokenStorage _tokens;
  io.Socket? _socket;
  
  final _messageController = StreamController<CommunityMessage>.broadcast();
  Stream<CommunityMessage> get onNewMessage => _messageController.stream;

  final _deleteController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get onMessageDeleted => _deleteController.stream;

  SocketService(this._tokens) {
    _tokens.changes.listen((_) {
      if (_socket != null) {
        connect(); // Reconnect with new token
      }
    });
  }

  Future<void> connect() async {
    final token = await _tokens.read();
    
    if (_socket != null) {
      if (_socket!.connected) {
        // Update auth token if it changed
        _socket!.io.options?['auth'] = {'token': token};
        return;
      }
      _socket!.dispose();
    }

    final baseUrl = AppConfig.apiBaseUrl.replaceFirst('/api', '');

    _socket = io.io(
      '$baseUrl/community',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) => print('Socket connected to /community'));
    _socket!.onDisconnect((_) => print('Socket disconnected'));
    
    _socket!.on('message:new', (data) {
      final message = CommunityMessage.fromJson(data as Map<String, dynamic>);
      _messageController.add(message);
    });

    _socket!.on('message:deleted', (data) {
      _deleteController.add(Map<String, String>.from(data as Map));
    });
  }

  void joinSubject(String subjectId) {
    _socket?.emit('join', {'subjectId': subjectId});
  }

  void leaveSubject(String subjectId) {
    _socket?.emit('leave', {'subjectId': subjectId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _deleteController.close();
  }
}
