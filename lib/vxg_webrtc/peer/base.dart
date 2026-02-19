import 'package:acre_labs/vxg_webrtc/peer/handlers.dart';
import 'package:acre_labs/vxg_webrtc/peer/helper.dart';
import 'package:acre_labs/vxg_webrtc/signaling/base.dart';
import 'package:acre_labs/vxg_webrtc/web_rtc_event_sink.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class PeerPool {
  final bool sendVideo;
  final bool sendAudio;
  final RTCSignalingSink signaling;
  final Map<String, dynamic> configurations;
  final SignalDataTransformer dataTransformer;
  final WebRTCEventSink? eventSink;

  const PeerPool._({
    required this.signaling,
    required this.configurations,
    required this.dataTransformer,
    this.sendVideo = false,
    this.sendAudio = false,
    this.eventSink,
  });

  RTCVideoRenderer? getRenderer(String peerId);
  List<RTCVideoRenderer> get renderers;
  RTCPeerConnection? getPeer(String peerId);

  bool containsPeer(String peerId);

  Future<void> add(String peerId, {required bool needOffer});
  Future<void> remove(String peerId);

  void onIncomingSdp(String peerId, Map<String, dynamic> sdp);
  void onIncomingIce(String peerId, Map<String, dynamic> ice);

  void dispose();

  factory PeerPool({
    required RTCSignalingSink signaling,
    required Map<String, dynamic> configurations,
    required SignalDataTransformer dataTransformer,
    WebRTCEventSink? eventSink,
    bool sendVideo = false,
    bool sendAudio = false,
  }) => _PeerPoolImpl(
    signaling: signaling,
    configurations: configurations,
    dataTransformer: dataTransformer,
    sendVideo: sendVideo,
    sendAudio: sendAudio,
    eventSink: eventSink,
  );
}

class _PeerPoolImpl extends PeerPool
    with
        PeerMediaHandlerMixin,
        PeerConnectionHandlerMixin,
        PeerLocalMediaMixin,
        _PeerOfferHandlerMixin,
        _PeerAnswerHandlerMixin {
  _PeerPoolImpl({
    required super.signaling,
    required super.configurations,
    required super.dataTransformer,
    super.sendVideo = false,
    super.sendAudio = false,
    super.eventSink,
  }) : super._();

  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, RTCVideoRenderer> _renderers = {};

  /// peers whose are interested in receiving media from us (i.e. we need to offer to them)
  final Set<String> _offeredPeers = {};

  @override
  bool containsPeer(String peerId) => _peers.containsKey(peerId);

  @override
  RTCPeerConnection? getPeer(String peerId) {
    return _peers[peerId];
  }

  @override
  RTCVideoRenderer? getRenderer(String peerId) {
    return _renderers[peerId];
  }

  @override
  List<RTCVideoRenderer> get renderers => _renderers.values.toList();

  @override
  Future<void> remove(String peerId) {
    final pc = _peers.remove(peerId);
    final render = _renderers.remove(peerId);
    final removed = _offeredPeers.remove(peerId);

    eventSink?.add(
      WebRtcEvent(
        WebRtcState.other,
        peerId: peerId,
        message: 'Peer $peerId removed, wasOffered: $removed',
      ),
    );

    return Future.wait([
      if (pc != null) pc.close(),
      if (render != null) render.dispose(),
    ]);
  }

  @override
  Future<void> add(String peerId, {required bool needOffer}) async {
    eventSink?.add(
      WebRtcEvent(
        WebRtcState.other,
        peerId: peerId,
        message: 'Adding peer $peerId, needOffer: $needOffer',
      ),
    );

    try {
      await _createPeerConnection(peerId);

      if (needOffer) {
        assert(
          !_offeredPeers.contains(peerId),
          'Peer $peerId is already an offered peer',
        );
        _offeredPeers.add(peerId);
        await offerToPeer(peerId);
      }
    } catch (e) {
      eventSink?.add(
        WebRtcEvent(
          WebRtcState.peerError,
          peerId: peerId,
          message: 'Failed to create peer connection for $peerId: $e',
        ),
      );
    }
  }

  @override
  void onIncomingIce(String peerId, Map<String, dynamic> ice) {
    onIncomingIceCandidate(peerId, ice);
  }

  @override
  void onIncomingSdp(String peerId, Map<String, dynamic> sdp) async {
    final pc = getPeer(peerId);

    if (pc == null) return;

    final needAnswer = !_offeredPeers.contains(peerId);

    try {
      final remoteDesc = dataTransformer.transformSdp(
        sdp,
        needAnswer: needAnswer,
      );

      await pc.setRemoteDescription(remoteDesc);

      if (needAnswer) {
        await answerPeer(peerId);
      }
    } catch (e) {
      eventSink?.add(
        WebRtcEvent(
          WebRtcState.peerError,
          peerId: peerId,
          message: 'Failed to handle incoming SDP from $peerId: $e',
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final render in _renderers.values) {
      render.dispose();
    }

    _renderers.clear();
    for (final peer in _peers.values) {
      peer.close();
    }

    _peers.clear();
  }

  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    assert(
      !_peers.containsKey(peerId),
      'Peer $peerId already exists in the pool',
    );
    assert(
      !_renderers.containsKey(peerId),
      'Renderer for peer $peerId already exists in the pool',
    );

    final render = RTCVideoRenderer();
    await render.initialize();

    final pc = await createPeerConnection(configurations);

    _peers[peerId] = pc;
    _renderers[peerId] = render;

    pc.onIceCandidate = (candidate) =>
        _signalLocalIceGathered(peerId, candidate);

    pc.onConnectionState = (state) => onPeerConnectionState(peerId, state);
    // pc.onAddStream = (stream) => onAddStream(peerId, stream);
    // pc.onRemoveStream = (stream) => onRemoveStream(peerId, stream);

    pc.onTrack = (event) => onTrack(peerId, event);
    pc.onAddTrack = (stream, track) => onAddTrack(peerId, track, stream);
    pc.onRemoveTrack = (stream, track) => onRemoveTrack(peerId, track);

    pc.onRenegotiationNeeded = () => onRenegotiationNeeded(peerId);

    eventSink?.add(
      WebRtcEvent(
        WebRtcState.peerConnectionCreated,
        peerId: peerId,
        message:
            'Peer $peerId connection is created, waiting for ices and remote medias',
      ),
    );

    return pc;
  }

  void _signalLocalIceGathered(String peerId, RTCIceCandidate candidate) {
    if (candidate.candidate?.isEmpty ?? true) {
      return;
    }

    eventSink?.add(
      WebRtcEvent(
        WebRtcState.ice,
        peerId: peerId,
        message:
            'Local ICE candidate gathered for peer $peerId: ${candidate.toMap()}',
      ),
    );

    signaling.send(dataTransformer.serializeIce(peerId, candidate.toMap()));
  }
}

mixin _PeerOfferHandlerMixin on PeerPool, PeerLocalMediaMixin {
  Future<void> offerToPeer(String peerId) async {
    final pc = getPeer(peerId);

    if (pc == null) return;

    try {
      MediaStream? localStream;

      if (sendVideo || sendAudio) {
        localStream = await getLocalMediaStream();
      }

      if (localStream != null) {
        await pc.addStream(localStream);
      }

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      signaling.send(dataTransformer.serializeSdp(peerId, offer.toMap()));

      eventSink?.add(
        WebRtcEvent(
          WebRtcState.sdp,
          peerId: peerId,
          message: 'Offer sent to peer $peerId, waiting for answer',
        ),
      );
    } catch (e) {
      eventSink?.add(
        WebRtcEvent(
          WebRtcState.peerError,
          peerId: peerId,
          message: 'Failed to offer to peer $peerId: $e',
        ),
      );
    }
  }
}

mixin _PeerAnswerHandlerMixin on PeerPool, PeerLocalMediaMixin {
  Future<void> answerPeer(String peerId) async {
    final pc = getPeer(peerId);

    if (pc == null) return;

    try {
      final localStream = (sendAudio || sendVideo)
          ? await getLocalMediaStream()
          : null;

      if (localStream != null) {
        await pc.addStream(localStream);
      }

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      signaling.send(dataTransformer.serializeSdp(peerId, answer.toMap()));

      eventSink?.add(
        WebRtcEvent(
          WebRtcState.sdp,
          peerId: peerId,
          message: 'Answer sent to peer $peerId, waiting for connection',
        ),
      );
    } catch (e) {
      eventSink?.add(
        WebRtcEvent(
          WebRtcState.peerError,
          peerId: peerId,
          message: 'Failed to answer peer $peerId: $e',
        ),
      );
    }
  }
}
