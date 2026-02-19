import 'dart:async';

import 'package:acre_labs/vxg_webrtc/signaling/websocket.dart';
import 'package:acre_labs/vxg_webrtc/web_rtc_event_sink.dart';

abstract interface class RTCSignalingSink {
  FutureOr<void> send(dynamic message);
}

class WebSocketSignaling implements RTCSignalingSink {
  final WebSocketWrapper _socket;

  WebSocketSignaling(
    String wsUrl, {
    bool autoConnect = true,
    WebRTCEventSink? eventSink,
  }) : _socket = WebSocketWrapper(
         wsUrl,
         autoConnect: autoConnect,
         eventSink: eventSink,
       );

  bool get isConnected => _socket.isConnected;

  Future<bool> connect([int maxAttempts = 3]) => _socket.connect(
    maxAttempts: maxAttempts,
  );

  @override
  FutureOr<void> send(message) {
    _socket.send(message);
  }

  StreamSubscription? subscribe(
    void Function(dynamic raw) onMessage, {
    void Function()? onDone,
    void Function(Object error)? onError,
  }) {
    if (!isConnected) {
      throw StateError(
        'WebSocket is not connected. Cannot subscribe to messages.',
      );
    }

    return _socket.messages!.listen(
      onMessage,
      onDone: onDone,
      onError: onError,
    );
  }

  void dispose() {
    _socket.dispose();
  }
}
