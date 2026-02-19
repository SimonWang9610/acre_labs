import 'package:flutter_webrtc/flutter_webrtc.dart';

enum RtcConnectionState {
  initialized,
  connecting,
  connected,
  disconnected,
  failed,
  closed;

  static RtcConnectionState fromRaw(RTCPeerConnectionState state) {
    return switch (state) {
      RTCPeerConnectionState.RTCPeerConnectionStateNew ||
      RTCPeerConnectionState.RTCPeerConnectionStateConnecting =>
        RtcConnectionState.connecting,
      RTCPeerConnectionState.RTCPeerConnectionStateConnected =>
        RtcConnectionState.connected,
      RTCPeerConnectionState.RTCPeerConnectionStateDisconnected =>
        RtcConnectionState.disconnected,
      RTCPeerConnectionState.RTCPeerConnectionStateFailed =>
        RtcConnectionState.failed,
      RTCPeerConnectionState.RTCPeerConnectionStateClosed =>
        RtcConnectionState.closed,
    };
  }
}

enum RtcIceState {
  idle,
  checking,
  connected,
  failed,
  disconnected,
  closed;

  static RtcIceState fromIce(RTCIceConnectionState state) {
    return switch (state) {
      RTCIceConnectionState.RTCIceConnectionStateNew ||
      RTCIceConnectionState.RTCIceConnectionStateChecking =>
        RtcIceState.checking,
      RTCIceConnectionState.RTCIceConnectionStateConnected ||
      RTCIceConnectionState.RTCIceConnectionStateCompleted ||
      RTCIceConnectionState.RTCIceConnectionStateCount => RtcIceState.connected,
      RTCIceConnectionState.RTCIceConnectionStateDisconnected =>
        RtcIceState.disconnected,
      RTCIceConnectionState.RTCIceConnectionStateFailed => RtcIceState.failed,
      RTCIceConnectionState.RTCIceConnectionStateClosed => RtcIceState.closed,
    };
  }
}
