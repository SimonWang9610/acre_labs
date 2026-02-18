import 'dart:convert';

import 'package:acre_labs/vxg_webrtc/peer_manager.dart';
import 'package:acre_labs/vxg_webrtc/signaling.dart';
import 'package:flutter/material.dart';

class VxgWebRtc {
  final String wsUrl;
  final List<Map<String, dynamic>> iceServers;
  final bool sendVideo;
  final bool sendAudio;
  final String version;

  WebRTCPeerManager? _watchers;
  WebRTCPeerManager? _publishers;
  WebRtcSignaling? _signaling;

  VxgWebRtc({
    required this.wsUrl,
    required this.iceServers,
    required this.version,
    this.sendVideo = false,
    this.sendAudio = false,
  });

  bool get isInitialized => _signaling != null && _signaling!.isConnected;

  Future<void> start() async {
    if (isInitialized) {
      return;
    }

    _signaling ??= WebRtcSignaling(wsUrl, autoConnect: false);

    _watchers ??= WebRTCPeerManager.watchers(
      signaling: _signaling!,
      configurations: {'iceServers': iceServers},
      sendVideo: sendVideo,
      sendAudio: sendAudio,
    );

    _publishers ??= WebRTCPeerManager.publishers(
      signaling: _signaling!,
      configurations: {'iceServers': iceServers},
      sendVideo: sendVideo,
      sendAudio: sendAudio,
    );

    final connected = await _signaling!.connect();

    if (connected) {
      _signaling!.send("HELLO $version");

      _signaling!.subscribe(
        (msg) {
          final handled = _handleSessionMessages(msg);

          if (!handled) {
            _handleSignalingMessage(msg);
          }
        },
        onDone: () {
          debugPrint("WebSocket connection closed by server.");
          _signaling?.dispose();
          _signaling = null;
        },
      );
    }
  }

  bool _handleSessionMessages(String message) {
    if (message.startsWith("HELLO")) {
      debugPrint("Received HELLO from server: $message");
      return true;
    }

    if (message.startsWith("SESSION_STARTED")) {
      debugPrint("[watching] Session started: $message");
      final peerId = message.split(' ')[1];
      _watchers?.add(peerId);
      return true;
    }

    if (message.startsWith('SESSION_STOPPED')) {
      debugPrint("[watching] Session ended: $message");
      final peerId = message.split(' ')[1];
      _watchers?.remove(peerId);
      return true;
    }

    if (message.startsWith('START_SESSION')) {
      debugPrint("[publishing]Received request to start session: $message");
      final peerId = message.split(' ')[1];
      _publishers?.add(peerId);
      return true;
    }

    if (message.startsWith("ERROR")) {
      _handleErrorMessage(message);
      return true;
    }

    return false;
  }

  void _handleErrorMessage(String message) {
    debugPrint("Received error message: $message");
  }

  void _handleSignalingMessage(String message) {
    debugPrint("Received signaling message: $message");

    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(message) as Map<String, dynamic>;
    } catch (e) {
      _handleErrorMessage('Error parsing JSON: $message');
      return;
    }

    final fromPeer = msg['from'] as String?;

    if (fromPeer == null) {
      _handleErrorMessage('Missing from field: $msg');
      return;
    }

    final peers = _getPeerManagerForPeer(fromPeer);
    if (peers == null) {
      _handleErrorMessage('Unknown peer: $fromPeer');
      return;
    }

    if (msg.containsKey('sdp')) {
      final sdp = msg['sdp'] as Map<String, dynamic>;
      peers.onIncomingSdp(fromPeer, sdp);
      return;
    }

    if (msg.containsKey('ice')) {
      final ice = msg['ice'] as Map<String, dynamic>;
      peers.onIncomingIce(fromPeer, ice);
      return;
    }

    _handleErrorMessage('Not handled message: $msg');
  }

  WebRTCPeerManager? _getPeerManagerForPeer(String peerId) {
    if (_watchers?.contains(peerId) ?? false) {
      return _watchers;
    } else if (_publishers?.contains(peerId) ?? false) {
      return _publishers;
    } else {
      return null;
    }
  }

  void dispose() {
    _watchers?.dispose();
    _publishers?.dispose();
    _signaling?.dispose();

    _watchers = null;
    _publishers = null;
    _signaling = null;
  }
}
