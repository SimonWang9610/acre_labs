import 'dart:async';

import 'package:acre_labs/vxg_webrtc/events/enums.dart';
import 'package:acre_labs/vxg_webrtc/events/events.dart';
import 'package:acre_labs/vxg_webrtc/peer/base.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

mixin PeerLocalMediaMixin on PeerPool {
  MediaStream? _localStream;
  Completer<MediaStream?>? _localStreamCompleter;

  FutureOr<MediaStream?> getLocalMediaStream() {
    if (_localStream != null) {
      return _localStream;
    }

    if (_localStreamCompleter != null && !_localStreamCompleter!.isCompleted) {
      return _localStreamCompleter!.future;
    }

    _localStreamCompleter = Completer<MediaStream?>();

    _requestLocalMediaStream();

    return _localStreamCompleter!.future;
  }

  Future<void> _requestLocalMediaStream() async {
    assert(_localStream == null, 'Local media stream is not available');
    assert(
      _localStreamCompleter != null && !_localStreamCompleter!.isCompleted,
      'Local media stream request is already in progress',
    );

    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'video': sendVideo,
        'audio': sendAudio,
      });

      _localStream = stream;

      eventSink?.add(
        RtcLogEvent(
          message:
              'Obtained local media stream with id ${stream.id}, tracks: ${stream.getTracks().map((t) => t.id).join(', ')}',
        ),
      );

      _localStreamCompleter?.complete(stream);
    } catch (e) {
      eventSink?.add(
        RtcErrorEvent(
          peerId: "<self>",
          message: 'Failed to get local media stream: $e',
        ),
      );
      _localStreamCompleter?.complete(null);
    }
  }
}

/// ===== Handle incoming remote media =====
mixin PeerMediaHandlerMixin on PeerPool {
  void onTrack(String peerId, RTCTrackEvent event) {
    if (event.streams.isEmpty) {
      return;
    }

    eventSink?.add(
      RtcMediaEvent(
        peerId: peerId,
        streamId: event.streams.first.id,
        trackId: event.track.id,
        message: "[onTrack]",
      ),
    );

    getRenderer(peerId)?.srcObject = event.streams.first;
  }

  void onAddTrack(String peerId, MediaStreamTrack track, MediaStream stream) {
    eventSink?.add(
      RtcMediaEvent(
        peerId: peerId,
        streamId: stream.id,
        trackId: track.id,
        message: "[onAddTrack]",
      ),
    );
    getRenderer(peerId)?.srcObject = stream;
  }

  // void onAddStream(String peerId, MediaStream stream) {
  //   eventSink?.add(
  //     RtcMediaEvent(
  //       peerId: peerId,
  //       streamId: stream.id,
  //       message: "[onAddStream]",
  //     ),
  //   );
  //   getRenderer(peerId)?.srcObject = stream;
  // }

  // void onRemoveStream(String peerId, MediaStream stream) {
  //   final renderer = getRenderer(peerId);
  //   if (renderer?.srcObject == stream) {
  //     eventSink?.add(
  //       RtcMediaEvent(
  //         peerId: peerId,
  //         streamId: stream.id,
  //         message: "[onRemoveStream]",
  //       ),
  //     );
  //     renderer?.srcObject = null;
  //   }
  // }

  void onRemoveTrack(String peerId, MediaStreamTrack track) {
    final renderer = getRenderer(peerId);
    final stream = renderer?.srcObject;

    if (stream != null && stream.getTracks().contains(track)) {
      eventSink?.add(
        RtcMediaEvent(
          peerId: peerId,
          streamId: stream.id,
          trackId: track.id,
          removed: true,
          message: "[onRemoveTrack]",
        ),
      );
      stream.removeTrack(track);
    }
  }
}

/// ===== Handle peer connection events =====
mixin PeerConnectionHandlerMixin on PeerPool {
  void onIncomingIceCandidate(String peerId, Map<String, dynamic> ice) async {
    final pc = getPeer(peerId);

    if (pc == null) {
      return;
    }

    final candidate = RTCIceCandidate(
      ice['candidate'] as String?,
      ice['sdpMid'] as String? ?? "",
      ice['sdpMLineIndex'] as int?,
    );

    eventSink?.add(
      RtcIceEvent(
        peerId: peerId,
        incoming: true,
        candidate: candidate.toMap(),
      ),
    );

    await pc.addCandidate(candidate);
  }

  void onIceConnectionState(String peerId, RTCIceConnectionState state) {
    eventSink?.add(
      RtcIceStateEvent(peerId: peerId, state: RtcIceState.fromIce(state)),
    );

    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        getPeer(peerId)?.restartIce();
        break;
      default:
        return;
    }
  }

  void onSignalingState(String peerId, RTCSignalingState state) {
    eventSink?.add(
      RtcLogEvent(
        message: 'Peer $peerId signaling state changed to $state',
      ),
    );
  }

  void onPeerConnectionState(String peerId, RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        getPeer(peerId)?.restartIce();
        break;
      default:
        break;
    }

    eventSink?.add(
      RtcConnectionStateEvent(
        peerId: peerId,
        state: RtcConnectionState.fromRaw(state),
      ),
    );
  }

  void onRenegotiationNeeded(String peerId) {
    eventSink?.add(
      RtcLogEvent(
        message: 'Peer $peerId renegotiation needed',
      ),
    );
  }
}
