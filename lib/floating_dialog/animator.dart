import 'dart:async';

import 'package:flutter/widgets.dart';

typedef AnimatedWidgetBuilder<T> =
    Widget Function(BuildContext context, Animation<T> animation);

abstract class OverlayAnimator<T> {
  final AnimationController _controller;

  OverlayAnimator(this._controller) {
    // _controller.addListener(_rebuild);
    _controller.addStatusListener((status) {
      print("Animation status: $status");
    });
  }

  Animation<double> get parent => _controller;

  FutureOr<void> forward({double? from}) async {
    await _controller.forward(from: from);
  }

  FutureOr<void> reverse({double? from}) async {
    await _controller.reverse(from: from);
  }

  bool get hasOverlay => _overlay != null;
  bool get isShowing => hasOverlay && (_overlay?.mounted ?? false);

  OverlayEntry? _overlay;

  void _rebuild() {
    _overlay?.markNeedsBuild();
  }

  Future<void> show(
    BuildContext context, {
    Tween<T>? tween,
    T? target,
    required AnimatedWidgetBuilder<T> builder,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) async {
    if (isShowing) return;

    assert(
      tween != null || target != null,
      'Either tween or target must be provided',
    );

    setupAnimation(
      tween: tween,
      target: target,
      curve: curve,
    );

    _overlay = OverlayEntry(
      builder: (_) => ValueListenableBuilder(
        valueListenable: animation,
        builder: (ctx, animation, _) {
          print(
            "Building overlay with animation value: ${animation.value}, hascode: ${animation.hashCode}, status: ${animation.status}",
          );
          return builder(ctx, animation);
        },
      ),
      // builder: (ctx) {
      //   print("Building overlay with animation value: ${animation}");
      //   return AnimatedBuilder(
      //     animation: _controller,
      //     builder: (ctx, child) {
      //       return builder(ctx, animation);
      //     },
      //   );
      // },
    );

    Overlay.of(context).insert(_overlay!);

    _controller.duration = duration;

    await _controller.forward(from: 0.0);
  }

  @mustCallSuper
  Future<void> animate({
    Tween<T>? tween,
    T? target,
    Duration? duration,
    Curve? curve,
    bool animating = false,
    bool reverse = false,
  }) async {
    if (!isShowing) return;

    _controller.reset();

    setupAnimation(
      tween: tween,
      target: target,
      curve: curve,
    );

    if (duration != null) {
      _controller.duration = duration;
    }

    if (animating) {
      /// force the animation direction to forward
      await _controller.animateTo(1.0);
    } else {
      _rebuild();
    }
  }

  void setupAnimation({
    Tween<T>? tween,
    T? target,
    Curve? curve,
  });

  ValueNotifier<Animation<T>> get animation;

  void hide() {
    if (!hasOverlay) return;

    _overlay?.remove();
    _overlay = null;
  }

  void dispose() {
    hide();
    _controller.removeListener(_rebuild);
    _controller.dispose();
  }
}
