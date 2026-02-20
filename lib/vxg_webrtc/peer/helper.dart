import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract interface class SignalDataTransformer {
  String serializeSdp(String peerId, Map<String, dynamic> sdp);
  String serializeIce(String peerId, Map<String, dynamic> ice);

  RTCSessionDescription transformSdp(
    Map<String, dynamic> sdp, {
    bool needAnswer = false,
  });

  @protected
  void handleSignalingMessage(dynamic message);
}
