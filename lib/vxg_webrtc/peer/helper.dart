import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract interface class SignalDataTransformer {
  String serializeSdp(String peerId, Map<String, dynamic> sdp);
  String serializeIce(String peerId, Map<String, dynamic> ice);

  RTCSessionDescription transformSdp(
    Map<String, dynamic> sdp, {
    bool needAnswer = false,
  });
}

final class VxgSignalDataTransformer implements SignalDataTransformer {
  /// Patches H.264 profile-level-id to 42e01f (Baseline 3.1) — mirrors the JS
  /// sdp.sdp.replace(/profile-level-id=[^;]+/, 'profile-level-id=42e01f')
  static String _patchSdp(String sdp) => sdp.replaceAll(
    RegExp(r'profile-level-id=[^;]+'),
    'profile-level-id=42e01f',
  );

  const VxgSignalDataTransformer();

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
}
