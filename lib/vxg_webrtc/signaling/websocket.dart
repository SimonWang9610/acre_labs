import 'dart:async';
import 'dart:convert';

import 'package:acre_labs/vxg_webrtc/events/events.dart';
import 'package:acre_labs/vxg_webrtc/events/sink.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketWrapper {
  final String wsUrl;
  final RtcEventSink? eventSink;

  WebSocketChannel? _channel;

  WebSocketWrapper(
    this.wsUrl, {
    bool autoConnect = true,
    this.eventSink,
  }) {
    if (autoConnect) {
      connect();
    }
  }

  Completer<bool>? _connectionCompleter;

  bool get isConnected => _isConnected;

  bool _isConnected = false;

  Stream<dynamic>? get messages => _channel?.stream;

  Future<bool> connect({int maxAttempts = 3}) async {
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      return _connectionCompleter!.future;
    }

    if (isConnected) {
      return true;
    }

    eventSink?.add(
      RtcSignalingEvent(
        status: SignalingStatus.connecting,
        message: 'Connecting to WebSocket at $wsUrl',
      ),
    );

    _connectionCompleter = Completer<bool>();

    int attempts = 0;

    while (attempts < maxAttempts && !_connectionCompleter!.isCompleted) {
      try {
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        await _channel!.ready;
        _isConnected = true;
        _connectionCompleter?.complete(true);
        eventSink?.add(
          RtcSignalingEvent(
            status: SignalingStatus.connected,
            message: 'WebSocket connection established to $wsUrl',
          ),
        );
        break;
      } catch (e) {
        attempts++;
        eventSink?.add(
          RtcSignalingEvent(
            status: SignalingStatus.error,
            message:
                'Failed to connect to WebSocket at $wsUrl (attempt $attempts): $e',
          ),
        );
        await Future.delayed(Duration(seconds: 2)); // Wait before retrying
      }
    }

    if (!_connectionCompleter!.isCompleted) {
      _connectionCompleter!.complete(false);
    }

    return _connectionCompleter!.future;
  }

  Future<void> disconnect() async {
    if (!isConnected) return;

    try {
      await _channel?.sink.close(status.normalClosure);
    } catch (e) {
      eventSink?.add(
        RtcSignalingEvent(
          status: SignalingStatus.error,
          message: '[socket] Error while disconnecting WebSocket: $e',
        ),
      );
    } finally {
      _channel = null;
      _isConnected = false;
      eventSink?.add(
        RtcSignalingEvent(
          status: SignalingStatus.disconnected,
          message: 'WebSocket connection closed',
        ),
      );
    }
  }

  void send(dynamic data) {
    if (!isConnected) {
      eventSink?.add(
        RtcSignalingEvent(
          status: SignalingStatus.error,
          message: 'Cannot send message, WebSocket is not connected.',
        ),
      );
      return;
    }

    try {
      final encoded = data is String ? data : jsonEncode(data);

      _channel!.sink.add(encoded);
    } catch (e) {
      eventSink?.add(
        RtcSignalingEvent(
          status: SignalingStatus.error,
          message: '[socket] Error while sending data over WebSocket: $e',
        ),
      );
    }
  }

  Future<void> dispose() async {
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.complete(false);
    }

    await disconnect();
  }
}
