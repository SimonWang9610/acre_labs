import 'dart:async';
import 'dart:convert';

import 'package:acre_labs/vxg_webrtc/peer/base.dart';
import 'package:acre_labs/vxg_webrtc/peer/helper.dart';
import 'package:acre_labs/vxg_webrtc/signaling/base.dart';
import 'package:acre_labs/vxg_webrtc/web_rtc_event_sink.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VxgWebRTC {
  final String wsUrl;
  final List<Map<String, dynamic>> iceServers;
  final bool sendVideo;
  final bool sendAudio;
  final String version;
  final WebRTCEventSink _eventSink = WebRTCEventSink();
  WebSocketSignaling? _signaling;
  PeerPool? _peers;
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

  Stream<WebRtcEvent> get events => _eventSink.stream;

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
            WebRtcEvent(
              WebRtcState.other,
              message: '$msg',
            ),
          );

          final handled = _handleSessionMessages(msg);

          if (!handled) {
            _handleSignalingMessage(msg);
          }
        },
        onError: (error) {
          _eventSink.add(
            WebRtcEvent(
              WebRtcState.signalingError,
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

  bool _handleSessionMessages(String message) {
    if (message.startsWith("HELLO")) {
      _eventSink.add(
        WebRtcEvent(
          WebRtcState.signalingConnected,
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
        WebRtcEvent(
          WebRtcState.signalingError,
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
        WebRtcEvent(
          WebRtcState.signalingError,
          message: 'Failed to parse signaling message: $message, error: $e',
        ),
      );
      return;
    }

    final fromPeer = msg['from'] as String?;

    if (fromPeer == null) {
      _eventSink.add(
        WebRtcEvent(
          WebRtcState.signalingError,
          message: 'Missing from field: $msg',
        ),
      );
      return;
    }

    final hasPeer = _peers?.containsPeer(fromPeer) ?? false;
    if (!hasPeer) {
      _eventSink.add(
        WebRtcEvent(
          WebRtcState.peerError,
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
      WebRtcEvent(
        WebRtcState.signalingError,
        message: 'Not handled message: $msg',
      ),
    );
  }

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
      dataTransformer: const VxgSignalDataTransformer(),
    );
  }

  void _reset() {
    _signalingSub?.cancel();
    _signalingSub = null;
    _signaling?.dispose();
    _signaling = null;
    _peers?.dispose();
    _peers = null;

    _eventSink.add(
      WebRtcEvent(
        WebRtcState.done,
        message: 'WebSocket and peer connections have been reset',
      ),
    );
  }

  void dispose() {
    _reset();
    _eventSink.dispose();
  }
}
