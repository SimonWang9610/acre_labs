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

abstract interface class DisposableOverlay {
  void dispose();
  void hide();
}

class OverlayAnimator<T> implements DisposableOverlay {
  final _OverlayManager _overlay;
  final AnimationController _controller;

  OverlayAnimator(this._controller) : _overlay = _OverlayManager();

  Animation<double> get parent => _controller;
  bool get isShowing => _overlay.isShowing;

  Animation<T>? _currentAnimation;

  Future<void> show(
    BuildContext context, {
    required Animation<T> animation,
    required AnimatedWidgetBuilder<T> builder,
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    if (_overlay.isShowing) return;

    _currentAnimation = animation;
    _overlay._insert(context, (ctx) => builder(ctx, _currentAnimation!));

    await drive(
      animation: animation,
      duration: duration,
    );
  }

  @override
  void hide() {
    _overlay._remove();
  }

  @mustCallSuper
  FutureOr<T> drive({
    required Animation<T> animation,
    Duration? duration,
    bool animating = true,
  }) async {
    _currentAnimation = animation;

    if (!_overlay.hasOverlay) return _currentAnimation!.value;

    _controller.reset();

    if (duration != null) {
      _controller.duration = duration;
    }

    /// rebuild to apply the new animation
    _overlay._rebuild();

    if (animating) {
      /// force the animation direction to forward
      await _controller.animateTo(1.0);
    }

    return _currentAnimation!.value;
  }

  FutureOr<T> forward({double? from}) async {
    await _controller.forward(from: from);
    return _currentAnimation!.value;
  }

  FutureOr<T> reverse({double? from}) async {
    await _controller.reverse(from: from);
    return _currentAnimation!.value;
  }

  @override
  void dispose() {
    hide();
    _controller.dispose();
  }
}
