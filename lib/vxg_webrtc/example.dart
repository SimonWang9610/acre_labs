import 'dart:async';

import 'package:acre_labs/vxg_webrtc/events/enums.dart';
import 'package:acre_labs/vxg_webrtc/events/events.dart';
import 'package:acre_labs/vxg_webrtc/vxg_web_rtc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';

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
        "wss://webrtc-1.inst.acre.acre.cloud-vms.com:443/25/watch/72937a7445c2d97d3d2b1fd17f5ce7282193ee6b/?ticket=media.eyJuIjogIjI1L3dhdGNoLzcyOTM3YTc0NDVjMmQ5N2QzZDJiMWZkMTdmNWNlNzI4MjE5M2VlNmIifQ.1771616642.ppwSHkgFDaleObHn2IHmRb5U5RA&stream_id=0",
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

      // if (event is RtcConnectionStateEvent &&
      //     event.state == RtcConnectionState.connected) {
      //   render.value = rtc.renderers.lastOrNull;
      // }

      // if (event is RtcSignalingEvent && event.status == SignalingStatus.done) {
      //   render.value = null;
      // }

      if (event is RtcConnectionStateEvent) {
        if (event.state == RtcConnectionState.disconnected ||
            event.state == RtcConnectionState.failed ||
            event.state == RtcConnectionState.closed) {
          render.value = null;
        }
      }

      if (event is RtcMediaEvent) {
        if (event.removed) {
          render.value = null;
        } else {
          render.value = rtc.getRenderer(event.peerId);
        }
      }

      // if (event is RtcMediaEvent) {
      //   setState(() {});
      // }
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
                ElevatedButton(
                  onPressed: () async {
                    final dir = await getTemporaryDirectory();
                    print("Temporary directory: ${dir.path}");
                  },
                  child: const Text('Capture Frame'),
                ),
              ],
            ),
            Expanded(
              child: Container(
                color: Colors.black,

                child: ValueListenableBuilder(
                  valueListenable: render,
                  builder: (context, value, child) {
                    return Stack(
                      children: [
                        AspectRatio(
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
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (value != null)
                                  _VolumeControl(
                                    render: value,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

class _VolumeControl extends StatelessWidget {
  final RTCVideoRenderer render;
  const _VolumeControl({
    super.key,
    required this.render,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: render,
      builder: (_, _, _) {
        return IconButton(
          onPressed: () async {
            final audioTracks = render.srcObject?.getAudioTracks();
            if (audioTracks == null || audioTracks.isEmpty) {
              return;
            }

            final enableStatus = audioTracks
                .map((track) => track.enabled)
                .toList();

            print("Current audio track enabled status: $enableStatus");
          },
          icon: Icon(
            Icons.volume_up,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
