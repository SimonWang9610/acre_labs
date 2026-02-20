import 'package:flutter_webrtc/flutter_webrtc.dart';

enum RtcConnectionState {
  /// connection and render are initialized,
  /// waiting for offer/answer exchange to start connection
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

  static RtcConnectionState fromIce(RTCIceConnectionState state) {
    return switch (state) {
      RTCIceConnectionState.RTCIceConnectionStateNew ||
      RTCIceConnectionState.RTCIceConnectionStateChecking ||
      RTCIceConnectionState.RTCIceConnectionStateCount =>
        RtcConnectionState.connecting,
      RTCIceConnectionState.RTCIceConnectionStateConnected ||
      RTCIceConnectionState.RTCIceConnectionStateCompleted =>
        RtcConnectionState.connected,
      RTCIceConnectionState.RTCIceConnectionStateDisconnected =>
        RtcConnectionState.disconnected,
      RTCIceConnectionState.RTCIceConnectionStateFailed =>
        RtcConnectionState.failed,
      RTCIceConnectionState.RTCIceConnectionStateClosed =>
        RtcConnectionState.closed,
    };
  }
}
