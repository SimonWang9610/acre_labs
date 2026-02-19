import 'dart:async';

import 'package:acre_labs/vxg_webrtc/events/events.dart';

class RtcEventSink {
  final _controller = StreamController<RtcEvent>.broadcast();

  RtcEventSink();

  void add(RtcEvent event) {
    if (_controller.isClosed) {
      return;
    }

    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }

  Stream<RtcEvent> get stream => _controller.stream;

  Stream<T> whereType<T extends RtcEvent>() {
    return stream.where((event) => event is T).cast<T>();
  }
}
