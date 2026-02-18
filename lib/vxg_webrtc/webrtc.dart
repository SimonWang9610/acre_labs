// vxg_webrtc_player.dart
//
// Flutter/Dart port of VXG CloudPlayerWebRTC0 and CloudPlayerWebRTC2 (webrtc.js).
// Requires: flutter_webrtc ^0.9.x
//
// pubspec.yaml dependencies:
//   flutter_webrtc: ^0.9.0
//
// Usage:
//   // WEBRTC0 – pure viewer
//   final player = VxgWebRtc0Player(
//     wsUrl: 'wss://your-server/ws',
//     rtmpUrl: 'rtmp://...',
//   );
//   player.onRemoteStream = (stream) => renderer.srcObject = stream;
//   player.start();
//
//   // WEBRTC2 – publisher or watcher
//   final player = VxgWebRtc2Player(
//     wsUrl: 'wss://your-server/ws',
//     iceServers: [...],
//     sendVideo: true,
//     sendAudio: true,
//   );
//   player.onRemoteStream = (stream) => renderer.srcObject = stream;
//   player.start();

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_webrtc/flutter_webrtc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

const _defaultIceServers = [
  {
    'urls': 'stun:stun.l.google.com:19302',
  },
  {
    'urls': ['turn:turn.vxg.io:3478?transport=udp'],
    'username': 'vxgturn',
    'credential': 'vxgturn',
  },
];

/// Patches H.264 profile-level-id to 42e01f (Baseline 3.1) — mirrors the JS
/// sdp.sdp.replace(/profile-level-id=[^;]+/, 'profile-level-id=42e01f')
String _patchSdp(String sdp) => sdp.replaceAll(
  RegExp(r'profile-level-id=[^;]+'),
  'profile-level-id=42e01f',
);

// ─────────────────────────────────────────────────────────────────────────────
// VxgWebRtc0Player — mirrors CloudPlayerWebRTC0
//
// Role    : Viewer / receiver only
// Protocol: Client → HELLO <peerId>
//           Client → SPAWN <rtmpUrl>
//           Server → HELLO  (ACK)
//           Server → { sdp: offer }
//           Client → { sdp: answer }
//           Both   → { ice: candidate }
// ─────────────────────────────────────────────────────────────────────────────
class VxgWebRtc0Player {
  VxgWebRtc0Player({
    required this.wsUrl,
    required this.rtmpUrl,
    List<Map<String, dynamic>>? iceServers,
  }) : _iceServers = iceServers ?? _defaultIceServers;

  final String wsUrl;
  final String rtmpUrl;
  final List<Map<String, dynamic>> _iceServers;

  // Callbacks for UI integration
  void Function(MediaStream stream)? onRemoteStream;
  void Function(String error)? onError;
  void Function()? onClose;

  WebSocket? _ws;
  RTCPeerConnection? _pc;
  int _connectAttempts = 0;
  late final String _peerId;
  bool _disposed = false;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> start() async {
    _peerId = (Random().nextInt(9000 - 10) + 10).toString();
    await _connectWebSocket();
  }

  void stop() {
    _disposed = true;
    _ws?.close();
  }

  // ── WebSocket ──────────────────────────────────────────────────────────────

  Future<void> _connectWebSocket() async {
    _connectAttempts++;
    if (_connectAttempts > 3) {
      _log('Too many connection attempts, aborting.');
      return;
    }
    _log('Connecting to $wsUrl …');
    try {
      _ws = await WebSocket.connect(wsUrl);
      _log('WebSocket opened — registering with server');
      // Step 2: register and spawn in one open handler
      _ws!.add('HELLO $_peerId');
      _ws!.add('SPAWN $rtmpUrl');

      _ws!.listen(
        _onMessage,
        onError: (e) {
          _log('WS error: $e');
          onError?.call(e.toString());
        },
        onDone: _onClose,
      );
    } catch (e) {
      _log('WS connect failed: $e');
      onError?.call(e.toString());
    }
  }

  // ── Message dispatcher ─────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    final data = raw as String;
    _log('Received: $data');

    // Step 3: server ACK
    if (data == 'HELLO') {
      _log('Registered with server, waiting for stream');
      return;
    }

    if (data.startsWith('ERROR')) {
      _handleError(data);
      return;
    }

    // JSON branch — SDP offer or ICE candidate
    Map<String, dynamic> msg;
    try {
      msg = json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      _handleError('Error parsing JSON: $data');
      return;
    }

    // Step 5: create peer connection on first JSON message
    if (_pc == null) _createPeerConnection();

    if (msg['sdp'] != null) {
      // Step 4 → 6: incoming SDP offer
      _onIncomingSdp(msg['sdp'] as Map<String, dynamic>);
    } else if (msg['ice'] != null) {
      // Step 9: incoming ICE candidate
      _onIncomingIce(msg['ice'] as Map<String, dynamic>);
    } else {
      _handleError('Unknown JSON message: $msg');
    }
  }

  // ── Peer connection ────────────────────────────────────────────────────────

  void _createPeerConnection() {
    _log('Creating RTCPeerConnection');
    final config = {'iceServers': _iceServers};

    createPeerConnection(config).then((pc) {
      _pc = pc;

      // Step 9: send ICE candidates via WebSocket
      pc.onIceCandidate = (candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) {
          _log('ICE candidate was null/empty — done');
          return;
        }
        _wsSend({'ice': candidate.toMap()});
      };

      // Step 10: stream from server
      pc.onAddStream = (stream) {
        _log(
          'Remote stream added — ${stream.getVideoTracks().length} video, '
          '${stream.getAudioTracks().length} audio tracks',
        );
        if (stream.getVideoTracks().isNotEmpty) {
          onRemoteStream?.call(stream);
        } else {
          _handleError('Stream has no video tracks');
        }
      };
    });
  }

  // ── SDP handling ───────────────────────────────────────────────────────────

  Future<void> _onIncomingSdp(Map<String, dynamic> sdpMap) async {
    if (_pc == null) return;

    final type = sdpMap['type'] as String;
    final rawSdp = sdpMap['sdp'] as String;
    final patchedSdp = _patchSdp(rawSdp);

    _log('Incoming SDP (type=$type)');
    // Step 6: set remote description
    await _pc!.setRemoteDescription(RTCSessionDescription(patchedSdp, type));
    _log('Remote SDP set');

    if (type != 'offer') return;

    // Step 7: create answer
    _log('Creating SDP answer');
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    // Step 8: send answer
    _log('Sending SDP answer');

    final localDescription = await _pc!.getLocalDescription();
    _wsSend({'sdp': localDescription!.toMap()});
  }

  // ── ICE handling ───────────────────────────────────────────────────────────

  Future<void> _onIncomingIce(Map<String, dynamic> iceMap) async {
    if (_pc == null) return;
    _log('Incoming ICE candidate');
    final candidate = RTCIceCandidate(
      iceMap['candidate'] as String,
      iceMap['sdpMid'] as String?,
      iceMap['sdpMLineIndex'] as int?,
    );
    await _pc!.addCandidate(candidate);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _wsSend(Map<String, dynamic> obj) {
    _ws?.add(json.encode(obj));
  }

  void _handleError(String error) {
    _log('ERROR: $error');
    onError?.call(error);
    _ws?.close();
  }

  void _onClose() {
    _log('WebSocket closed');
    _pc?.close();
    _pc = null;
    onClose?.call();
    if (!_disposed) {
      // Optional auto-reconnect after 1 second
      // Future.delayed(const Duration(seconds: 1), _connectWebSocket);
    }
  }

  void _log(String msg) => print('[WEBRTC0] $msg');
}

// ─────────────────────────────────────────────────────────────────────────────
// VxgWebRtc2Player — mirrors CloudPlayerWebRTC2
//
// Role    : Publisher OR watcher (determined by server messages)
// Protocol:
//  Watcher  : HELLO → (HELLO ACK) → SESSION_STARTED → [SDP offer] → [SDP answer] → ICE
//  Publisher: HELLO → (HELLO ACK) → START_SESSION → [SDP offer] → [SDP answer] → ICE
//
// Multi-peer sessions are tracked in _peers: Map<String, RTCPeerConnection>
// All JSON messages include 'to'/'from' fields for routing.
// ─────────────────────────────────────────────────────────────────────────────
class VxgWebRtc2Player {
  VxgWebRtc2Player({
    required this.wsUrl,
    List<Map<String, dynamic>>? iceServers,
    this.sendVideo = false,
    this.sendAudio = false,
    this.version = '1.0',
  }) : _iceServers = iceServers ?? [];

  final String wsUrl;
  final String version;
  final bool sendVideo;
  final bool sendAudio;
  final List<Map<String, dynamic>> _iceServers;

  // Callbacks
  void Function(MediaStream stream, String peerUid)? onRemoteStream;
  void Function(String peerUid)? onSessionStopped;
  void Function()? onStartStreaming;
  void Function(String error)? onError;
  void Function()? onClose;

  WebSocket? _ws;
  bool _isPublisher = false;
  int _connectAttempts = 0;
  bool _disposed = false;

  // peer UID → RTCPeerConnection
  final Map<String, RTCPeerConnection> _peers = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> start() async {
    await _connectWebSocket();
  }

  void stop() {
    _disposed = true;
    _ws?.close();
  }

  // ── WebSocket ──────────────────────────────────────────────────────────────

  Future<void> _connectWebSocket() async {
    _connectAttempts++;
    if (_connectAttempts > 3) {
      _log('Too many connection attempts, aborting.');
      return;
    }
    _log('Connecting to $wsUrl …');
    try {
      _ws = await WebSocket.connect(wsUrl);
      _log('WebSocket opened — registering with server');
      _ws!.add('HELLO $version');

      _ws!.listen(
        _onMessage,
        onError: (e) {
          _log('WS error: $e');
          onError?.call(e.toString());
        },
        onDone: _onClose,
      );
    } catch (e) {
      _log('WS connect failed: $e');
      onError?.call(e.toString());
    }
  }

  // ── Message dispatcher ─────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    final data = raw as String;
    _log('Received: $data');

    if (data.startsWith('HELLO')) {
      _log('Registered with server, waiting for stream');
      return;
    }

    if (data.startsWith('SESSION_STARTED')) {
      // Watcher path: a publisher came online
      final peerUid = data.split(' ')[1];
      _log('Publisher $peerUid is going to start session');
      _createWatchingConnection(peerUid);
      return;
    }

    if (data.startsWith('SESSION_STOPPED')) {
      final peerUid = data.split(' ')[1];
      _log('Session of publisher $peerUid is terminated');
      _closePeer(peerUid);
      onSessionStopped?.call(peerUid);
      return;
    }

    if (data.startsWith('START_SESSION')) {
      // Publisher path: a watcher joined
      final peerUid = data.split(' ')[1];
      _log('Watcher $peerUid has come and awaiting for publishing');
      _createPublishingConnection(peerUid);
      return;
    }

    if (data.startsWith('ERROR')) {
      _handleError(data);
      return;
    }

    // JSON branch — SDP or ICE, routed by 'from' field
    Map<String, dynamic> msg;
    try {
      msg = json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      _handleError('Error parsing JSON: $data');
      return;
    }

    final peerUid = msg['from'] as String?;
    if (peerUid == null || !_peers.containsKey(peerUid)) {
      _handleError('Unknown peer or missing from field: $msg');
      return;
    }
    final pc = _peers[peerUid]!;

    if (msg['sdp'] != null) {
      _onIncomingSdp(peerUid, pc, msg['sdp'] as Map<String, dynamic>);
    } else if (msg['ice'] != null) {
      _onIncomingIce(peerUid, pc, msg['ice'] as Map<String, dynamic>);
    } else {
      _handleError('Unknown JSON: $msg');
    }
  }

  // ── Watcher connection ─────────────────────────────────────────────────────

  Future<void> _createWatchingConnection(String peerUid) async {
    assert(!_peers.containsKey(peerUid));
    _connectAttempts = 0;
    final config = {'iceServers': _iceServers};
    final pc = await createPeerConnection(config);
    _peers[peerUid] = pc;

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) {
        _log('ICE candidate was null — done');
        return;
      }
      _wsSend({'to': peerUid, 'ice': candidate.toMap()});
    };

    pc.onAddStream = (stream) => _handleRemoteStream(stream, peerUid);

    _log('Created watching peer connection for $peerUid, waiting for SDP');
  }

  // ── Publisher connection ───────────────────────────────────────────────────

  Future<void> _createPublishingConnection(String peerUid) async {
    assert(!_peers.containsKey(peerUid));
    _isPublisher = true;
    _connectAttempts = 0;

    if (!sendAudio && !sendVideo) {
      _log('Publisher must send audio or video stream');
      return;
    }

    final localStream = await navigator.mediaDevices.getUserMedia({
      'audio': sendAudio,
      'video': sendVideo,
    });
    _log('Local stream received');

    final config = {'iceServers': _iceServers};
    final pc = await createPeerConnection(config);
    _peers[peerUid] = pc;

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) {
        _log('ICE candidate was null — done');
        return;
      }
      _wsSend({'to': peerUid, 'ice': candidate.toMap()});
    };

    pc.onAddStream = (stream) => _handleRemoteStream(stream, peerUid);

    pc.onConnectionState = (state) {
      _log('Connection state changed: $state');
    };

    await pc.addStream(localStream);
    _log('Created publishing peer connection for $peerUid');

    // Publisher creates and sends the offer
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    _log('Sending SDP offer to $peerUid');
    _wsSend({'to': peerUid, 'sdp': pc.localDescription!.toMap()});
  }

  // ── SDP handling ───────────────────────────────────────────────────────────

  Future<void> _onIncomingSdp(
    String peerUid,
    RTCPeerConnection pc,
    Map<String, dynamic> sdpMap,
  ) async {
    final type = sdpMap['type'] as String;
    final rawSdp = sdpMap['sdp'] as String;
    final patchedSdp = _patchSdp(rawSdp);

    _log('Incoming SDP from $peerUid (type=$type)');
    await pc.setRemoteDescription(RTCSessionDescription(patchedSdp, type));
    _log('Remote SDP set');

    if (_isPublisher) {
      // Publisher receives 'answer' — no further action needed
      assert(type == 'answer');
      _log('Got SDP answer from $peerUid');
      return;
    }

    // Watcher receives 'offer' — must create answer
    assert(type == 'offer');
    _log('Got SDP offer from $peerUid — creating answer');

    if (sendVideo || sendAudio) {
      // Watcher configured to also send a stream
      final localStream = await navigator.mediaDevices.getUserMedia({
        'audio': sendAudio,
        'video': sendVideo,
      });
      await pc.addStream(localStream);
    }

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    _log('Sending SDP answer to $peerUid');
    _wsSend({'to': peerUid, 'sdp': pc.localDescription!.toMap()});

    onStartStreaming?.call();
  }

  // ── ICE handling ───────────────────────────────────────────────────────────

  Future<void> _onIncomingIce(
    String peerUid,
    RTCPeerConnection pc,
    Map<String, dynamic> iceMap,
  ) async {
    _log('Incoming ICE from $peerUid');
    final candidate = RTCIceCandidate(
      iceMap['candidate'] as String,
      iceMap['sdpMid'] as String?,
      iceMap['sdpMLineIndex'] as int?,
    );
    await pc.addCandidate(candidate);
  }

  // ── Stream rendering ───────────────────────────────────────────────────────

  void _handleRemoteStream(MediaStream stream, String peerUid) {
    final vTracks = stream.getVideoTracks();
    final aTracks = stream.getAudioTracks();
    if (vTracks.isNotEmpty || aTracks.isNotEmpty) {
      _log(
        'Incoming stream from $peerUid: ${vTracks.length} video, ${aTracks.length} audio',
      );
      onRemoteStream?.call(stream, peerUid);
    } else {
      _handleError('Stream with unknown tracks from $peerUid');
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  void _closePeer(String peerUid) {
    final pc = _peers.remove(peerUid);
    pc?.close();
  }

  void _handleError(String error) {
    _log('ERROR: $error');
    onError?.call(error);
    _ws?.close();
  }

  void _onClose() {
    _log('WebSocket closed');
    for (final pc in _peers.values) {
      pc.close();
    }
    _peers.clear();
    onClose?.call();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _wsSend(Map<String, dynamic> obj) {
    _ws?.add(json.encode(obj));
  }

  void _log(String msg) => print('[WEBRTC2] $msg');
}

// ─────────────────────────────────────────────────────────────────────────────
// Example Flutter widget integration (usage reference)
// ─────────────────────────────────────────────────────────────────────────────

/*
class VxgPlayerWidget extends StatefulWidget {
  final String wsUrl;
  final String rtmpUrl;
  const VxgPlayerWidget({required this.wsUrl, required this.rtmpUrl, super.key});

  @override
  State<VxgPlayerWidget> createState() => _VxgPlayerWidgetState();
}

class _VxgPlayerWidgetState extends State<VxgPlayerWidget> {
  late RTCVideoRenderer _renderer;
  VxgWebRtc0Player? _player;

  @override
  void initState() {
    super.initState();
    _renderer = RTCVideoRenderer();
    _renderer.initialize().then((_) {
      _player = VxgWebRtc0Player(wsUrl: widget.wsUrl, rtmpUrl: widget.rtmpUrl);
      _player!.onRemoteStream = (stream) {
        setState(() => _renderer.srcObject = stream);
      };
      _player!.onError = (e) => debugPrint('Player error: $e');
      _player!.onClose = () => debugPrint('Player closed');
      _player!.start();
    });
  }

  @override
  void dispose() {
    _player?.stop();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RTCVideoView(_renderer);
}
*/
