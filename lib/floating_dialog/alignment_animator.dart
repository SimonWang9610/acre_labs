import 'dart:async';

import 'package:acre_labs/floating_dialog/animator.dart';
import 'package:flutter/cupertino.dart';

class AlignmentAnimator extends OverlayAnimator<Alignment> {
  final double scale;

  late Alignment _alignment;
  late Offset _screenCenter;

  AlignmentAnimator(
    super.controller, {
    this.scale = 0.95,
  });

  /// Move to the given position.
  ///
  /// the position is used to calculate the new alignment.
  Future<bool> moveTo(Offset position) async {
    if (!isShowing) return false;

    double dx = (position.dx - _screenCenter.dx) / _screenCenter.dx;
    double dy = (position.dy - _screenCenter.dy) / _screenCenter.dy;

    dx = dx.abs() < 1 ? dx : dx / dx.abs();
    dy = dy.abs() < 1 ? dy : dy / dy.abs();

    final newAlign = Alignment(dx, dy);

    if (_alignment == newAlign) return false;

    await animate(target: newAlign, animating: false);
    _alignment = newAlign;

    return true;
  }

  /// Adjust alignment based on the given axis.
  ///
  /// It will align to the closest edge on the given axis.
  ///
  /// [Axis.horizontal]: align to left or right edge.
  ///
  /// [Axis.vertical]: align to top or bottom edge.
  Future<void> autoAlign(
    Axis axis, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    if (!isShowing) return;

    final newAlign = switch (axis) {
      Axis.horizontal => _adjustHorizontal(),
      Axis.vertical => _adjustVertical(),
    };

    await animate(target: newAlign, animating: true);

    _alignment = newAlign;
  }

  Alignment _adjustHorizontal() {
    double dx = _alignment.x;

    if (dx != 0) {
      dx = dx / dx.abs() * scale;
    }

    return Alignment(dx, _alignment.y);
  }

  Alignment _adjustVertical() {
    double dy = _alignment.y;

    if (dy != 0) {
      dy = dy / dy.abs() * scale;
    }

    return Alignment(_alignment.x, dy);
  }

  @override
  ValueNotifier<Animation<Alignment>> get animation => _animation!;

  ValueNotifier<Animation<Alignment>>? _animation;

  @override
  void setupAnimation({
    Tween<Alignment>? tween,
    Alignment? target,
    Curve? curve,
  }) {
    assert(
      tween != null || target != null,
      'Either tween or target must be provided',
    );

    final targetTween =
        tween ??
        Tween<Alignment>(
          begin: _alignment,
          end: target,
        );

    final Animation<Alignment> animation;

    if (targetTween.begin == null || targetTween.begin == targetTween.end) {
      animation = AlwaysStoppedAnimation<Alignment>(
        targetTween.end as Alignment,
      );
    } else {
      animation = parent.drive(targetTween);
    }

    if (_animation == null) {
      _animation = ValueNotifier<Animation<Alignment>>(animation);
    } else {
      _animation!.value = animation;
    }
  }

  @override
  Future<void> show(
    BuildContext context, {
    Tween<Alignment>? tween,
    Alignment? target,
    required AnimatedWidgetBuilder<Alignment> builder,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) async {
    _screenCenter = MediaQuery.of(context).size.center(Offset.zero);
    _alignment = tween?.end ?? target ?? Alignment.center;

    return super.show(
      context,
      tween: tween,
      target: target ?? _alignment,
      builder: builder,
      duration: duration,
    );
  }
}
