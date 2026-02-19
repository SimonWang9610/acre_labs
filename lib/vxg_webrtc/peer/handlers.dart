import 'dart:async';

import 'package:acre_labs/vxg_webrtc/peer/base.dart';
import 'package:acre_labs/vxg_webrtc/web_rtc_event_sink.dart';
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
        WebRtcEvent(
          WebRtcState.other,
          message: 'Local media stream obtained with id ${stream.id}',
        ),
      );

      _localStreamCompleter?.complete(stream);
    } catch (e) {
      eventSink?.add(
        WebRtcEvent(
          WebRtcState.peerError,
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
      WebRtcEvent(
        WebRtcState.mediaReceived,
        peerId: peerId,
        message:
            'Received remote track from $peerId, stream id: ${event.streams.first.id}',
      ),
    );

    getRenderer(peerId)?.srcObject = event.streams.first;
  }

  void onAddTrack(String peerId, MediaStreamTrack track, MediaStream stream) {
    // eventSink?.add(
    //   WebRtcEvent(
    //     WebRtcState.mediaReceived,
    //     peerId: peerId,
    //     message:
    //         'Added remote track from $peerId, track id: ${track.id}, stream id: ${stream.id}',
    //   ),
    // );
    // getRenderer(peerId)?.srcObject = stream;
  }

  // void onAddStream(String peerId, MediaStream stream) {
  //   eventSink?.add(
  //     WebRtcEvent(
  //       WebRtcState.mediaReceived,
  //       peerId: peerId,
  //       message:
  //           'Added remote stream from $peerId, stream id: ${stream.id}, tracks: ${stream.getTracks().map((t) => t.id).join(', ')}',
  //     ),
  //   );
  //   getRenderer(peerId)?.srcObject = stream;
  // }

  // void onRemoveStream(String peerId, MediaStream stream) {
  //   final renderer = getRenderer(peerId);
  //   if (renderer?.srcObject == stream) {
  //     eventSink?.add(
  //       WebRtcEvent(
  //         WebRtcState.mediaRemoved,
  //         peerId: peerId,
  //         message:
  //             'Removed remote stream from $peerId, stream id: ${stream.id}, tracks: ${stream.getTracks().map((t) => t.id).join(', ')}',
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
        WebRtcEvent(
          WebRtcState.mediaRemoved,
          peerId: peerId,
          message:
              'Removed remote track from $peerId, track id: ${track.id}, stream id: ${stream.id}',
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
      WebRtcEvent(
        WebRtcState.ice,
        peerId: peerId,
        message:
            'Received remote ICE candidate from $peerId: ${candidate.candidate}',
      ),
    );

    await pc.addCandidate(candidate);
  }

  void onIceConnectionState(String peerId, RTCIceConnectionState state) {
    eventSink?.add(
      WebRtcEvent(
        WebRtcState.iceState,
        peerId: peerId,
        message: 'ICE connection state for $peerId changed to $state',
      ),
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
      WebRtcEvent(
        WebRtcState.peerConnectionSate,
        peerId: peerId,
        message: 'Signaling state for $peerId changed to $state',
      ),
    );
  }

  void onPeerConnectionState(String peerId, RTCPeerConnectionState state) {
    final WebRtcState webRtcState;

    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        webRtcState = WebRtcState.peerDisconnected;
        getPeer(peerId)?.restartIce();
        break;
      default:
        webRtcState = WebRtcState.peerConnectionSate;
        break;
    }

    eventSink?.add(
      WebRtcEvent(
        webRtcState,
        peerId: peerId,
        message: 'Peer connection state for $peerId changed to $state',
      ),
    );
  }

  void onRenegotiationNeeded(String peerId) {
    eventSink?.add(
      WebRtcEvent(
        WebRtcState.negotiating,
        peerId: peerId,
        message: 'Renegotiation needed for peer $peerId',
      ),
    );
  }
}
