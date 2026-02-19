import 'dart:async';

import 'package:acre_labs/vxg_webrtc/events/events.dart';
import 'package:acre_labs/vxg_webrtc/vxg_web_rtc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VxgWebRtcExample extends StatefulWidget {
  const VxgWebRtcExample({super.key});

  @override
  State<VxgWebRtcExample> createState() => _VxgWebRtcExampleState();
}

class _VxgWebRtcExampleState extends State<VxgWebRtcExample> {
  final urls = {
    "ice_servers": [
      {
        "urls": ["stun:stun.l.google.com:19302"],
      },
      {
        "username": "vxgturn",
        "credential": "vxgturn",
        "urls": ["turn:turn.vxg.io:3478?transport=udp"],
      },
    ],
    "version": "2.0.2",
    "connection_url":
        "wss://webrtc-1.inst.acre.acre.cloud-vms.com:443/25/watch/b93182b36c1da811bed43d449bfdc23b31340042/?ticket=media.eyJuIjogIjI1L3dhdGNoL2I5MzE4MmIzNmMxZGE4MTFiZWQ0M2Q0NDliZmRjMjNiMzEzNDAwNDIifQ.1771543307.79PmxdTY2wk2M31q68W3lFM3UnU&stream_id=0",
    "scripts": {
      "player":
          "https://web.acre.acre.cloud-vms.com:443/static/webrtc/CloudPlayer.webrtc2.js",
      "helpers":
          "https://web.acre.acre.cloud-vms.com:443/static/webrtc/CloudHelpers.js",
    },
  };

  late final rtc = VxgWebRTC(
    wsUrl: urls['connection_url'] as String,
    iceServers: urls['ice_servers'] as List<Map<String, dynamic>>,
    version: urls['version'] as String,
  );

  StreamSubscription? _eventSub;

  final render = ValueNotifier<RTCVideoRenderer?>(null);

  @override
  void initState() {
    super.initState();
    _eventSub = rtc.events.listen((event) {
      debugPrint("$event");

      if (event is RtcConnectionStateEvent) {
        render.value = rtc.renderers.lastOrNull;
      }

      if (event is RtcSignalingEvent && event.status == SignalingStatus.done) {
        render.value = null;
      }

      if (event is RtcMediaEvent) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    rtc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VxgWebRTC Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 20,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => rtc.start(),
                  child: const Text('Start WebRTC'),
                ),
                ElevatedButton(
                  onPressed: () => rtc.stop(),
                  child: const Text('Stop WebRTC'),
                ),
              ],
            ),
            Expanded(
              child: Container(
                color: Colors.black,

                child: ValueListenableBuilder(
                  valueListenable: render,
                  builder: (context, value, child) {
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: value != null
                          ? RTCVideoView(value)
                          : Center(
                              child: Text(
                                'Waiting for video stream...',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
