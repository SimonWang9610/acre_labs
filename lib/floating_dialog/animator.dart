import 'dart:async';

import 'package:flutter/widgets.dart';

typedef AnimatedWidgetBuilder<T> =
    Widget Function(BuildContext context, Animation<T> animation);

class _OverlayManager {
  bool get hasOverlay => _overlay != null;
  bool get isShowing => hasOverlay && (_overlay?.mounted ?? false);

  OverlayEntry? _overlay;

  void _insert(BuildContext context, WidgetBuilder builder) {
    assert(!isShowing, 'Overlay is already showing');

    _overlay = OverlayEntry(
      builder: (ctx) {
        return builder(ctx);
      },
    );

    Overlay.of(context).insert(_overlay!);
  }

  void _remove() {
    _overlay?.remove();
    _overlay = null;
  }

  void _rebuild() {
    _overlay?.markNeedsBuild();
  }
}

abstract class OverlayAnimator<T> {
  final _OverlayManager _overlay;
  final AnimationController _controller;

  OverlayAnimator(this._controller) : _overlay = _OverlayManager();

  Animation<double> get parent => _controller;
  bool get isShowing => _overlay.isShowing;

  Future<void> show(
    BuildContext context, {
    Tween<T>? tween,
    T? target,
    required AnimatedWidgetBuilder<T> builder,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) async {
    if (_overlay.isShowing) return;

    assert(
      tween != null || target != null,
      'Either tween or target must be provided',
    );

    setupAnimation(
      tween: tween,
      target: target,
      curve: curve,
    );

    _overlay._insert(context, (ctx) => builder(ctx, animation));

    await animate(
      tween: tween,
      target: target,
      duration: duration,
      curve: curve,
    );
  }

  void hide() {
    _overlay._remove();
  }

  @mustCallSuper
  FutureOr<void> animate({
    Tween<T>? tween,
    T? target,
    Duration? duration,
    Curve? curve,
    bool animating = true,
    bool reverse = false,
  }) async {
    if (!_overlay.hasOverlay) return;

    _controller.reset();

    setupAnimation(
      tween: tween,
      target: target,
      curve: curve,
    );

    final usingAnimation = animation;

    if (duration != null) {
      _controller.duration = duration;
    }

    /// rebuild to apply the new animation
    _overlay._rebuild();

    if (animating) {
      /// force the animation direction to forward
      await _controller.animateTo(1.0);
    }

    onAnimationComplete(usingAnimation.value);
  }

  FutureOr<void> forward({double? from}) async {
    await _controller.forward(from: from);
  }

  FutureOr<void> reverse({double? from}) async {
    await _controller.reverse(from: from);
  }

  void dispose() {
    hide();
    _controller.dispose();
  }

  void setupAnimation({
    Tween<T>? tween,
    T? target,
    Curve? curve,
  });

  void onAnimationComplete(T endValue) {}

  Animation<T> get animation;
}
