import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebRtcSignaling {
  final String wsUrl;

  WebSocketChannel? _channel;

  WebRtcSignaling(this.wsUrl, {bool autoConnect = true}) {
    if (autoConnect) {
      connect();
    }
  }

  Completer<bool>? _connectionCompleter;

  bool get isConnected => _channel != null && _channel!.closeCode == null;

  Future<bool> connect({int maxAttempts = 3}) async {
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      return _connectionCompleter!.future;
    }

    if (isConnected) {
      debugPrint('WebSocket is already connected.');
      return true;
    }

    _connectionCompleter = Completer<bool>();

    int attempts = 0;

    while (attempts < maxAttempts && !_connectionCompleter!.isCompleted) {
      try {
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        await _channel!.ready;
        _connectionCompleter?.complete(true);
      } catch (e) {
        attempts++;
        debugPrint(
          'Connection attempt $attempts failed: $e, Retry after 2 seconds',
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
      await _channel?.sink.close(status.goingAway);
    } catch (e) {
      debugPrint('Error while closing WebSocket: $e');
    } finally {
      _channel = null;
    }
  }

  void send(dynamic data) {
    if (!isConnected) {
      debugPrint('WebSocket is not connected. Cannot send data.');
      return;
    }

    try {
      final encoded = data is String ? data : jsonEncode(data);

      _channel!.sink.add(encoded);
    } catch (e) {
      debugPrint('Error while sending data over WebSocket: $e');
    }
  }

  StreamSubscription? subscribe(
    void Function(dynamic raw) onMessage, {
    void Function()? onDone,
    void Function(Object error)? onError,
  }) {
    if (!isConnected) {
      debugPrint('WebSocket is not connected. Cannot subscribe.');
      return null;
    }

    return _channel!.stream.listen(
      onMessage,
      onDone: onDone,
      onError: onError,
    );
  }

  Future<void> dispose() async {
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.completeError(
        "WebSocket connection was disposed before it could be established.",
      );
    }

    await disconnect();
  }
}
