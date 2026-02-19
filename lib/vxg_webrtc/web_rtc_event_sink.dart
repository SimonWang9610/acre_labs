import 'dart:async';

enum WebRtcState {
  idle,
  signalingConnecting,
  signalingConnected,
  signalingDisconnected,
  signalingError,
  peerConnectionCreated,
  peerDisconnected,
  peerConnectionSate,
  ice,
  iceState,
  sdp,
  mediaReceived,
  mediaRemoved,
  negotiating,
  peerError,
  other,
  done,
}

class WebRtcEvent {
  final WebRtcState state;
  final String? peerId;
  final String? message;

  const WebRtcEvent(this.state, {this.peerId, this.message});

  @override
  String toString() {
    return '===\n$state, peerId: $peerId\n$message\n===';
  }
}

class WebRTCEventSink {
  final _controller = StreamController<WebRtcEvent>.broadcast();

  Stream<WebRtcEvent> get stream => _controller.stream;

  void add(WebRtcEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}
