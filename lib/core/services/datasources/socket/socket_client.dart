import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:template_app/core/utilities/logger.dart';

typedef SocketEventCallback = void Function(dynamic data);

enum SocketStatus { disconnected, connecting, connected, error }

class SocketClient {
  static const String _label = 'SocketClient';
  static const int _defaultReconnectDelayMs = 3000;
  static const int _maxReconnectAttempts = 10;
  static const String _baseUrl = "";

  io.Socket? _socket;
  SocketStatus _status = SocketStatus.disconnected;

  Map<String, dynamic> _auth = {};
  Map<String, dynamic> _extraHeaders = {};
  int _reconnectAttempts = 0;
  bool _manualDisconnect = false;

  SocketStatus get status => _status;
  bool get isConnected => _status == SocketStatus.connected;

  void connect({
    Map<String, dynamic> auth = const {},
    Map<String, dynamic> extraHeaders = const {},
  }) {
    if (_baseUrl.isEmpty) {
      throw StateError('[$_label] Base URL belum diatur.');
    }

    if (isConnected) {
      Log.w('Socket sudah terhubung ke $_baseUrl', label: _label);
      return;
    }

    _auth = Map.from(auth);
    _extraHeaders = Map.from(extraHeaders);
    _manualDisconnect = false;
    _reconnectAttempts = 0;

    _createAndConnect();
  }

  /// Shortcut untuk connect dengan Bearer token.
  /// Setara dengan `connect(auth: {"token": token})`.
  void connectWithToken(
    String token, {
    Map<String, dynamic> extraHeaders = const {},
  }) {
    connect(auth: {'token': token}, extraHeaders: extraHeaders);
  }

  void _createAndConnect() {
    Log.i(
      'Menghubungkan ke $_baseUrl (percobaan: $_reconnectAttempts)',
      label: _label,
    );
    _status = SocketStatus.connecting;

    _socket?.dispose();
    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth(_auth)
          .setExtraHeaders(_extraHeaders)
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _status = SocketStatus.connected;
      _reconnectAttempts = 0;
      Log.i('Terhubung — id: ${_socket?.id}', label: _label);
    });

    _socket!.onDisconnect((reason) {
      _status = SocketStatus.disconnected;
      Log.w('Terputus — alasan: $reason', label: _label);
      if (!_manualDisconnect) _scheduleReconnect();
    });

    _socket!.onConnectError((error) {
      _status = SocketStatus.error;
      Log.e('Gagal terhubung', label: _label, error: error);
      if (!_manualDisconnect) _scheduleReconnect();
    });

    _socket!.onError((error) {
      Log.e('Socket error', label: _label, error: error);
    });

    _socket!.connect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      Log.e(
        'Batas maksimal reconnect ($_maxReconnectAttempts) tercapai. Berhenti mencoba.',
        label: _label,
      );
      return;
    }
    _reconnectAttempts++;
    final delay = _defaultReconnectDelayMs * _reconnectAttempts;
    Log.i(
      'Reconnect percobaan $_reconnectAttempts/$_maxReconnectAttempts dalam ${delay}ms...',
      label: _label,
    );
    Future.delayed(Duration(milliseconds: delay), () {
      if (!_manualDisconnect) _createAndConnect();
    });
  }

  void reconnect() {
    _manualDisconnect = false;
    _reconnectAttempts = 0;
    _socket?.dispose();
    _socket = null;
    _status = SocketStatus.disconnected;
    _createAndConnect();
  }

  void disconnect() {
    if (_socket == null) return;
    Log.i('Memutus koneksi socket', label: _label);
    _manualDisconnect = true;
    _socket!.disconnect();
    _socket!.dispose();
    _socket = null;
    _status = SocketStatus.disconnected;
  }

  void setAuth(Map<String, dynamic> auth) {
    _auth = Map.from(auth);
    Log.d('Auth diperbarui: $_auth', label: _label);
  }

  void emit(String event, [dynamic data]) {
    if (!isConnected) {
      Log.w('Emit "$event" dibatalkan — socket belum terhubung', label: _label);
      return;
    }
    Log.d('Emit "$event" → $data', label: _label);
    _socket!.emit(event, data);
  }

  void on(String event, SocketEventCallback callback) {
    _socket?.on(event, (data) {
      Log.d('Terima "$event" ← $data', label: _label);
      callback(data);
    });
  }

  void off(String event) {
    Log.d('Hapus listener "$event"', label: _label);
    _socket?.off(event);
  }
}
