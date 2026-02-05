import 'dart:async';

import 'package:acre_labs/floating_dialog/alarm/event_alarm_tile.dart';
import 'package:acre_labs/floating_dialog/alignment_animator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalEventAlarmListener extends ConsumerStatefulWidget {
  const GlobalEventAlarmListener({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GlobalEventAlarmListenerState();
}

class _GlobalEventAlarmListenerState
    extends ConsumerState<GlobalEventAlarmListener>
    with SingleTickerProviderStateMixin {
  late final floating = FloatingAlignment(
    AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    ),
  );

  final events = <String>[];

  final streamController = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();

    // ensure the floating controller is shown after the first frame
    // this is a floating area for showing alarmed events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      floating.show(
        context,
        duration: const Duration(seconds: 2),

        // /// put the alarm list close to the bottom left
        // start: Alignment.topRight,
        end: const Alignment(-0.95, 0.8),
        builder: (_, animation) => AlignTransition(
          alignment: animation,
          child: _ShowingAlarmedEventList(streamController.stream, floating),
        ),
      );
    });
  }

  @override
  void dispose() {
    streamController.close();
    floating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Global Event Alarm Listener")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 15,
          children: [
            Text("Total: ${events.length} events"),
            Expanded(
              child: events.isEmpty
                  ? const Center(child: Text("No events yet"))
                  : ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return ListTile(
                          title: Text(event),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final time = DateTime.now();
          final ts = "${time.hour}:${time.minute}:${time.second}";
          final newEvents = <String>[];

          final count = 10;

          for (int i = 0; i < count; i++) {
            final event = "[$ts] Alarm Event #${events.length + 1}";
            newEvents.add(event);
            events.insert(0, event);
            streamController.add(event);
          }

          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ShowingAlarmedEventList extends ConsumerStatefulWidget {
  final FloatingAlignment floating;
  final Stream<String> lastEvent;
  const _ShowingAlarmedEventList(this.lastEvent, this.floating);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      __ShowingAlarmedEventListState();
}

class __ShowingAlarmedEventListState
    extends ConsumerState<_ShowingAlarmedEventList> {
  final listKey = GlobalKey<AnimatedListState>();
  final showing = <String>[];
  final Map<String, Timer> _dismissTimers = {};

  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();

    _sub = widget.lastEvent.listen((event) => _onMqttEvent(event));
  }

  @override
  void dispose() {
    _sub?.cancel();

    for (final timer in _dismissTimers.values) {
      timer.cancel();
    }

    _dismissTimers.clear();

    super.dispose();
  }

  Alignment _current = Alignment.bottomLeft;

  bool _end = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final height = screenSize.height * 0.3;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onPanUpdate: (details) {
              print("pan update: ${details.globalPosition}");
              widget.floating.moveTo(details.globalPosition);
            },
            onPanEnd: (details) {
              print("pan end");
              widget.floating.autoAlign(Axis.vertical);
            },
            // onTap: () {
            //   if (_current == Alignment.bottomLeft) {
            //     widget.floating.animate(target: Alignment.topRight);
            //     _current = Alignment.topRight;
            //   } else {
            //     widget.floating.animate(target: Alignment.bottomLeft);
            //     _current = Alignment.bottomLeft;
            //   }
            //   // if (_end) {
            //   //   widget.floating.reverse();
            //   // } else {
            //   //   widget.floating.forward();
            //   // }
            //   // widget.floating.forward(from: 0);
            //   _end = !_end;
            //   print("_end: $_end");
            // },
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height, maxWidth: 400),
              child: AnimatedList(
                key: listKey,
                shrinkWrap: true,
                initialItemCount: showing.length,
                itemBuilder: (_, index, animation) {
                  final event = showing[index];

                  final topPadding = index == 0 ? 6.0 : 0.0;

                  return SizeTransition(
                    sizeFactor: animation,
                    child: Padding(
                      padding: EdgeInsets.only(top: topPadding, bottom: 6.0),
                      child: TimelineEventAlarmTile(
                        event: event,
                        onDismissed: () => _dismiss(event),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onMqttEvent(String event) {
    if (showing.contains(event)) return;

    showing.insert(0, event);
    listKey.currentState?.insertItem(0);

    // auto dismiss after 5 seconds
    // _dismissTimers[event] = Timer(
    //   const Duration(seconds: 5),
    //   () => _dismiss(event),
    // );
  }

  void _dismiss(String event) {
    _dismissTimers.remove(event)?.cancel();

    final index = showing.indexWhere((e) => e == event);
    if (index == -1) return;

    final removed = showing.removeAt(index);

    assert(event == removed);

    listKey.currentState?.removeItem(
      index,
      duration: const Duration(milliseconds: 240),
      (context, animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: TimelineEventAlarmTile(
            event: event,

            /// purposely do nothing on dismissed to avoid re-entrance
            onDismissed: () {},
          ),
        );
      },
    );
  }
}
