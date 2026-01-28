import 'package:acre_labs/snapshot/snapshot_task.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

class LongListWidget extends StatelessWidget {
  final int count;
  const LongListWidget({super.key, this.count = 1000});

  @override
  Widget build(BuildContext context) {
    // return Column(
    //   mainAxisSize: MainAxisSize.min,
    //   mainAxisAlignment: MainAxisAlignment.end,
    //   children: [
    //     const Text('This is a long list'),
    //     for (var i = 0; i < count; i++)
    //       Padding(
    //         padding: const EdgeInsets.all(8.0),
    //         child: Text('Item #$i'),
    //       ),
    //   ],
    // );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.ltr,
        children: [
          const Text('This is a long list'),
          for (var i = 0; i < count; i++) Text('Item #$i'),
        ],
      ),
    );
  }
}

class SnapshotExample extends StatefulWidget {
  const SnapshotExample({super.key});

  @override
  State<SnapshotExample> createState() => _SnapshotExampleState();
}

class _SnapshotExampleState extends State<SnapshotExample> {
  final _snapshot = ValueNotifier<Uint8List?>(null);

  final controller = ScreenshotController();

  @override
  void dispose() {
    _snapshot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snapshot Example'),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              spacing: 20,
              children: [
                Builder(builder: (ctx) {
                  return ElevatedButton(
                    onPressed: () async {
                      // Take snapshot here
                      final task = OfflineSnapshotTask.withContext(
                        ctx,
                        signal: Future.delayed(const Duration(seconds: 1)),
                        target: const LongListWidget(count: 100),
                      );
                      try {
                        final bytes = await task.run();
                        _snapshot.value = bytes;
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: const Text('Take Snapshot'),
                  );
                }),
                LongListWidget(
                  count: 10,
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
              ),
              child: ValueListenableBuilder<Uint8List?>(
                valueListenable: _snapshot,
                builder: (context, bytes, child) {
                  if (bytes == null) {
                    return const Text('No snapshot taken yet.');
                  }
                  return SingleChildScrollView(
                    child: Image.memory(bytes),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
