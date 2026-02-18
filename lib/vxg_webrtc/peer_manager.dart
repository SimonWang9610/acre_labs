import 'package:acre_labs/vxg_webrtc/signaling.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class WebRTCPeerManager {
  final bool sendVideo;
  final bool sendAudio;
  final WebRtcSignaling signaling;
  final Map<String, dynamic> configurations;

  const WebRTCPeerManager({
    required this.signaling,
    required this.configurations,
    this.sendVideo = false,
    this.sendAudio = false,
  });

  Future<void> add(String peerId);
  Future<void> remove(String peerId);

  RTCVideoRenderer? getRenderer(String peerId);
  List<RTCVideoRenderer> get renderers;

  bool contains(String peerId);

  void onIncomingSdp(String peerId, Map<String, dynamic> sdp);

  void onIncomingIce(String peerId, Map<String, dynamic> ice);

  void dispose();

  factory WebRTCPeerManager.watchers({
    required WebRtcSignaling signaling,
    required Map<String, dynamic> configurations,
    bool sendVideo = false,
    bool sendAudio = false,
  }) => _Watchers(
    signaling: signaling,
    configurations: configurations,
    sendVideo: sendVideo,
    sendAudio: sendAudio,
  );

  factory WebRTCPeerManager.publishers({
    required WebRtcSignaling signaling,
    required Map<String, dynamic> configurations,
    bool sendVideo = true,
    bool sendAudio = true,
  }) => _Publishers(
    signaling: signaling,
    configurations: configurations,
    sendVideo: sendVideo,
    sendAudio: sendAudio,
  );
}

class _Watchers extends WebRTCPeerManager with _BaseManager {
  _Watchers({
    required super.signaling,
    required super.configurations,
    super.sendVideo = false,
    super.sendAudio = false,
  });

  @override
  Future<void> add(String peerId) async {
    debugPrint('[watchers]: adding watcher peer: $peerId');
    assert(!_peers.containsKey(peerId), 'Peer $peerId already exists');

    try {
      final pc = await createPeerConnection(configurations);
      _peers[peerId] = pc;
      await _createVideoRenderer(peerId);

      pc.onIceCandidate = (c) => _onIceCandidate(peerId, c);
      pc.onAddStream = (s) => _onAddStream(peerId, s);
    } catch (e) {
      debugPrint('Failed to create peer connection for $peerId: $e');
    }
  }

  @override
  void onIncomingSdp(String peerId, Map<String, dynamic> sdp) async {
    debugPrint('[watchers]: received SDP from peer: $peerId');
    final type = sdp['type'] as String;
    final rawSdp = sdp['sdp'] as String;
    final patchedSdp = _patchSdp(rawSdp);

    final pc = _peers[peerId];

    if (pc == null) {
      debugPrint('Received SDP for unknown peer $peerId');
      return;
    }

    assert(type == "offer");

    try {
      await pc.setRemoteDescription(
        RTCSessionDescription(patchedSdp, type),
      );

      if (sendAudio || sendVideo) {
        final localStream = await navigator.mediaDevices.getUserMedia({
          'audio': sendAudio,
          'video': sendVideo,
        });

        await pc.addStream(localStream);
      }

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      signaling.send({'to': peerId, 'sdp': answer.toMap()});
    } catch (e) {
      debugPrint('[watchers] Failed to handle incoming SDP from $peerId: $e');
    }
  }
}

class _Publishers extends WebRTCPeerManager with _BaseManager {
  _Publishers({
    required super.signaling,
    required super.configurations,
    super.sendVideo = true,
    super.sendAudio = true,
  });

  @override
  @override
  Future<void> add(String peerId) async {
    debugPrint('[publishers]: adding publisher peer: $peerId');
    assert(!_peers.containsKey(peerId), 'Peer $peerId already exists');

    if (!sendAudio && !sendVideo) {
      debugPrint(
        'Neither audio nor video is enabled for publishing. Skipping peer $peerId.',
      );
      return;
    }

    try {
      final localStream = await navigator.mediaDevices.getUserMedia({
        'audio': sendAudio,
        'video': sendVideo,
      });

      final pc = await createPeerConnection(configurations);
      _peers[peerId] = pc;
      await _createVideoRenderer(peerId);

      pc.onIceCandidate = (c) => _onIceCandidate(peerId, c);
      pc.onAddStream = (s) => _onAddStream(peerId, s);

      pc.onConnectionState = (state) {
        debugPrint('Peer $peerId connection state changed: $state');
      };

      await pc.addStream(localStream);

      final offer = await pc.createOffer();

      await pc.setLocalDescription(offer);

      signaling.send({'to': peerId, 'sdp': offer.toMap()});
    } catch (e) {
      debugPrint(
        '[publishers] Failed to create peer connection for $peerId: $e',
      );
    }
  }

  @override
  void onIncomingSdp(String peerId, Map<String, dynamic> sdp) async {
    debugPrint('[publishers]: received SDP from peer: $peerId');
    final type = sdp['type'] as String;
    final rawSdp = sdp['sdp'] as String;
    final patchedSdp = _patchSdp(rawSdp);

    assert(type == "answer");

    await _peers[peerId]?.setRemoteDescription(
      RTCSessionDescription(patchedSdp, type),
    );
  }
}

mixin _BaseManager on WebRTCPeerManager {
  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, RTCVideoRenderer> _renderers = {};

  @override
  bool contains(String peerId) {
    return _peers.containsKey(peerId);
  }

  @override
  Future<void> remove(String peerId) async {
    final pc = _peers.remove(peerId);
    final render = _renderers.remove(peerId);

    await Future.wait([
      if (pc != null) pc.close(),
      if (render != null) render.dispose(),
    ]);
  }

  @override
  RTCVideoRenderer? getRenderer(String peerId) {
    return _renderers[peerId];
  }

  @override
  List<RTCVideoRenderer> get renderers => _renderers.values.toList();

  @override
  void dispose() {
    for (final pc in _peers.values) {
      pc.close();
    }
    for (final renderer in _renderers.values) {
      renderer.dispose();
    }

    _peers.clear();
    _renderers.clear();
  }

  @override
  void onIncomingIce(String peerId, Map<String, dynamic> ice) async {
    final pc = _peers[peerId];

    if (pc == null) {
      debugPrint('Received ICE candidate for unknown peer $peerId');
      return;
    }

    final candidate = RTCIceCandidate(
      ice['candidate'] as String?,
      ice['sdpMid'] as String?,
      ice['sdpMLineIndex'] as int?,
    );

    await pc.addCandidate(candidate);
  }

  void _onIceCandidate(String peerId, RTCIceCandidate candidate) {
    if (candidate.candidate?.isEmpty ?? true) {
      return;
    }

    signaling.send({'to': peerId, 'ice': candidate.toMap()});
  }

  void _onAddStream(String peerId, MediaStream stream) {
    debugPrint('Received remote stream from $peerId: ${stream.id}');
    _renderers[peerId]?.srcObject = stream;
  }

  Future<void> _createVideoRenderer(String peerId) async {
    assert(
      !_renderers.containsKey(peerId),
      'Renderer for peer $peerId already exists',
    );

    final render = RTCVideoRenderer();
    _renderers[peerId] = render;
    await render.initialize();
  }
}

/// Patches H.264 profile-level-id to 42e01f (Baseline 3.1) — mirrors the JS
/// sdp.sdp.replace(/profile-level-id=[^;]+/, 'profile-level-id=42e01f')
String _patchSdp(String sdp) => sdp.replaceAll(
  RegExp(r'profile-level-id=[^;]+'),
  'profile-level-id=42e01f',
);
