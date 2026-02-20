import 'dart:async';
import 'dart:convert';

import 'package:acre_labs/vxg_webrtc/events/events.dart';
import 'package:acre_labs/vxg_webrtc/events/sink.dart';
import 'package:acre_labs/vxg_webrtc/peer/base.dart';
import 'package:acre_labs/vxg_webrtc/peer/helper.dart';
import 'package:acre_labs/vxg_webrtc/signaling/base.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VxgWebRTC with _VxgSignalDataTransformer {
  final String wsUrl;
  final List<Map<String, dynamic>> iceServers;
  final bool sendVideo;
  final bool sendAudio;
  final String version;

  @override
  final RtcEventSink _eventSink = RtcEventSink();
  @override
  PeerPool? _peers;

  WebSocketSignaling? _signaling;
  StreamSubscription? _signalingSub;

  VxgWebRTC({
    required this.wsUrl,
    required this.iceServers,
    required this.version,
    this.sendVideo = false,
    this.sendAudio = false,
  });

  bool get isInitialized =>
      _signaling != null && _signaling!.isConnected && _peers != null;

  Stream<RtcEvent> get events => _eventSink.stream;

  Future<void> start() async {
    if (_signaling?.isConnected ?? false) {
      return;
    }

    _signalingSub?.cancel();

    _initComponents();

    final connected = await _signaling!.connect();

    if (connected) {
      _signaling!.send("HELLO $version");

      _signalingSub = _signaling!.subscribe(
        (msg) {
          _eventSink.add(
            RtcLogEvent(
              message: '$msg',
            ),
          );

          handleSignalingMessage(msg);
        },
        onError: (error) {
          _eventSink.add(
            RtcSignalingEvent(
              status: SignalingStatus.error,
              message: 'WebSocket error: $error',
            ),
          );
          _reset();
        },
        onDone: _reset,
      );
    }
  }

  Future<void> stop() async {
    _reset();
  }

  List<RTCVideoRenderer> get renderers => _peers?.renderers ?? [];

  RTCVideoRenderer? getRenderer(String peerId) => _peers?.getRenderer(peerId);

  void _initComponents() {
    _signaling ??= WebSocketSignaling(
      wsUrl,
      autoConnect: false,
      eventSink: _eventSink,
    );

    _peers ??= PeerPool(
      signaling: _signaling!,
      configurations: {
        'iceServers': iceServers,
        'sdpSemantics': 'unified-plan',
      },
      sendVideo: sendVideo,
      sendAudio: sendAudio,
      eventSink: _eventSink,
      dataTransformer: this,
    );
  }

  void _reset() {
    _signalingSub?.cancel();
    _signalingSub = null;

    _peers?.dispose();
    _peers = null;

    _signaling?.dispose();
    _signaling = null;

    _eventSink.add(
      RtcSignalingEvent(
        status: SignalingStatus.done,
        message: 'WebSocket and peer connections have been reset',
      ),
    );
  }

  void dispose() {
    _reset();
    _eventSink.dispose();
  }
}

abstract mixin class _VxgSignalDataTransformer
    implements SignalDataTransformer {
  RtcEventSink get _eventSink;
  PeerPool? get _peers;

  /// Patches H.264 profile-level-id to 42e01f (Baseline 3.1) — mirrors the JS
  /// sdp.sdp.replace(/profile-level-id=[^;]+/, 'profile-level-id=42e01f')
  static String _patchSdp(String sdp) => sdp.replaceAll(
    RegExp(r'profile-level-id=[^;]+'),
    'profile-level-id=42e01f',
  );

  const _VxgSignalDataTransformer();

  @override
  String serializeSdp(String peerId, Map<String, dynamic> sdp) {
    return jsonEncode({
      "to": peerId,
      "sdp": sdp,
    });
  }

  @override
  String serializeIce(String peerId, Map<String, dynamic> ice) {
    return jsonEncode({
      "to": peerId,
      "ice": ice,
    });
  }

  @override
  RTCSessionDescription transformSdp(
    Map<String, dynamic> sdp, {
    bool needAnswer = false,
  }) {
    final type = sdp['type'] as String;
    final rawSdp = sdp['sdp'] as String;
    final patchedSdp = _patchSdp(rawSdp);

    assert(() {
      if (needAnswer) {
        return type == 'offer';
      } else {
        return type == 'answer';
      }
    }(), 'Received unexpected SDP type "$type" from peer');

    return RTCSessionDescription(patchedSdp, type);
  }

  @override
  void handleSignalingMessage(dynamic message) {
    final handled = _handleSessionMessages(message);

    if (!handled) {
      _handleSignalingMessage(message);
    }
  }

  bool _handleSessionMessages(String message) {
    if (message.startsWith("HELLO")) {
      _eventSink.add(
        RtcLogEvent(
          message: 'Received greeting from server: $message',
        ),
      );
      return true;
    }

    if (message.startsWith("SESSION_STARTED")) {
      final peerId = message.split(' ')[1];
      _peers?.add(peerId, needOffer: false);
      return true;
    }

    if (message.startsWith('SESSION_STOPPED')) {
      final peerId = message.split(' ')[1];
      _peers?.remove(peerId);
      return true;
    }

    if (message.startsWith('START_SESSION')) {
      final peerId = message.split(' ')[1];
      _peers?.add(peerId, needOffer: true);
      return true;
    }

    if (message.startsWith("ERROR")) {
      _eventSink.add(
        RtcSignalingEvent(
          status: SignalingStatus.error,
          message: 'Received error from server: $message',
        ),
      );
      return true;
    }

    return false;
  }

  void _handleSignalingMessage(String message) {
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(message) as Map<String, dynamic>;
    } catch (e) {
      _eventSink.add(
        RtcSignalingEvent(
          status: SignalingStatus.error,
          message: 'Failed to parse signaling message: $message, error: $e',
        ),
      );
      return;
    }

    final fromPeer = msg['from'] as String?;

    if (fromPeer == null) {
      _eventSink.add(
        RtcSignalingEvent(
          status: SignalingStatus.error,
          message: 'Missing from field: $msg',
        ),
      );
      return;
    }

    final hasPeer = _peers?.containsPeer(fromPeer) ?? false;
    if (!hasPeer) {
      _eventSink.add(
        RtcSignalingEvent(
          status: SignalingStatus.error,
          message: 'Unknown peer: $fromPeer',
        ),
      );
      return;
    }

    if (msg.containsKey('sdp')) {
      final sdp = msg['sdp'] as Map<String, dynamic>;
      _peers?.onIncomingSdp(fromPeer, sdp);
      return;
    }

    if (msg.containsKey('ice')) {
      final ice = msg['ice'] as Map<String, dynamic>;
      _peers?.onIncomingIce(fromPeer, ice);
      return;
    }

    _eventSink.add(
      RtcSignalingEvent(
        status: SignalingStatus.error,
        message: 'Not handled message: $msg',
      ),
    );
  }
}
