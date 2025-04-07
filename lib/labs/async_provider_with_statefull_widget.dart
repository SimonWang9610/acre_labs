import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _futureProvider = FutureProvider<List<String>>(
  (ref) async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Hello', 'World'];
  },
);

final _otherFutureProvider = FutureProvider.family<List<String>, String>(
  (ref, param) async {
    await Future.delayed(const Duration(seconds: 2));
    return ["param: $param"];
  },
);

String _param = 'initial';

class _TestWidget extends StatefulWidget {
  final String initValue;
  const _TestWidget({
    super.key,
    required this.initValue,
  });

  @override
  State<_TestWidget> createState() => __TestWidgetState();
}

class __TestWidgetState extends State<_TestWidget> {
  @override
  void initState() {
    super.initState();
    print('Init state: ${widget.initValue}');
  }

  @override
  void didUpdateWidget(covariant _TestWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('Did update widget: ${widget.initValue}');
  }

  @override
  void dispose() {
    print('Dispose: ${widget.initValue}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.initValue),
        Consumer(
          builder: (_, ref, __) {
            return TextButton(
              onPressed: () {
                ref.invalidate(_otherFutureProvider(_param));
                _param = DateTime.now().toString();
              },
              child: Text("invalidate"),
            );
          },
        )
      ],
    );
  }
}

final _key = UniqueKey();

class AsyncProviderWithStatefulWidget extends ConsumerWidget {
  const AsyncProviderWithStatefulWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final data = ref.watch(_futureProvider);
    final other = ref.watch(_otherFutureProvider(_param));

    final child = other.when(
      skipLoadingOnReload: true,
      skipError: true,
      data: (data) {
        print("Loaded other data: $data");
        return _TestWidget(
          initValue: data.join(','),
        );
      },
      error: (error, stackTrace) {
        return Center(
          child: Text('Error: $error'),
        );
      },
      loading: () => const Center(
        child: Text('Loading...'),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Page'),
      ),
      body: KeyedSubtree(
        key: _key,
        child: child,
      ),
    );
  }
}
