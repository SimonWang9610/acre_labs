import 'package:acre_labs/vxg_webrtc/events/enums.dart';

sealed class RtcEvent {
  final String? message;
  const RtcEvent({this.message});
}

enum SignalingStatus {
  connecting,
  connected,
  active,
  disconnected,
  error,
  done,
}

final class RtcLogEvent extends RtcEvent {
  const RtcLogEvent({super.message});

  @override
  String toString() => 'RtcLogEvent(message: $message)';
}

final class RtcSignalingEvent extends RtcEvent {
  final SignalingStatus status;

  const RtcSignalingEvent({
    required this.status,
    super.message,
  });

  @override
  String toString() => 'RtcSignalingEvent(status: $status, message: $message)';
}

final class RtcPeerEvent extends RtcEvent {
  final String peerId;

  const RtcPeerEvent({
    required this.peerId,
    super.message,
  });
}

final class RtcIceEvent extends RtcPeerEvent {
  final bool incoming;
  final Map<String, dynamic> candidate;

  const RtcIceEvent({
    required super.peerId,
    required this.candidate,
    required this.incoming,
    super.message,
  });

  @override
  String toString() =>
      'RtcIceEvent(peerId: $peerId, incoming: $incoming, candidate: $candidate, message: $message)';
}

final class RtcSdpEvent extends RtcPeerEvent {
  final bool incoming;
  final Map<String, dynamic> sdp;

  const RtcSdpEvent({
    required super.peerId,
    required this.sdp,
    required this.incoming,
    super.message,
  });

  @override
  String toString() =>
      'RtcSdpEvent(peerId: $peerId, incoming: $incoming, sdp: $sdp, message: $message)';
}

final class RtcMediaEvent extends RtcPeerEvent {
  final String? streamId;
  final String? trackId;
  final bool removed;
  const RtcMediaEvent({
    required super.peerId,
    this.streamId,
    this.trackId,
    this.removed = false,
    super.message,
  });

  @override
  String toString() =>
      'RtcMediaEvent(peerId: $peerId, streamId: $streamId, trackId: $trackId, removed: $removed, message: $message)';
}

final class RtcConnectionStateEvent extends RtcPeerEvent {
  final RtcConnectionState state;
  const RtcConnectionStateEvent({
    required super.peerId,
    required this.state,
    super.message,
  });

  @override
  String toString() =>
      'RtcConnectionStateEvent(peerId: $peerId, state: $state, message: $message)';
}

final class RtcIceStateEvent extends RtcPeerEvent {
  final RtcIceState state;
  const RtcIceStateEvent({
    required super.peerId,
    required this.state,
    super.message,
  });

  @override
  String toString() =>
      'RtcIceStateEvent(peerId: $peerId, state: $state, message: $message)';
}

final class RtcErrorEvent extends RtcPeerEvent {
  const RtcErrorEvent({
    required super.peerId,
    super.message,
  });

  @override
  String toString() => 'RtcErrorEvent(peerId: $peerId, message: $message)';
}
