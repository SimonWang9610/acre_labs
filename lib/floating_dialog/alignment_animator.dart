import 'dart:async';

import 'package:acre_labs/floating_dialog/animator.dart';
import 'package:flutter/cupertino.dart';

class FloatingAlignment implements DisposableOverlay {
  final OverlayAnimator<Alignment> _animator;
  final double scale;

  late Alignment _alignment;
  late Offset _screenCenter;

  FloatingAlignment(
    AnimationController controller, {
    this.scale = 0.9,
  }) : _animator = OverlayAnimator<Alignment>(controller);

  Future<void> show(
    BuildContext context, {
    Alignment? start,
    Alignment? end,
    required AnimatedWidgetBuilder<Alignment> builder,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) async {
    assert(
      start != null || end != null,
      'Either start or end alignment must be provided',
    );

    _screenCenter = MediaQuery.of(context).size.center(Offset.zero);
    _alignment = start ?? end ?? Alignment.center;

    await _animator.show(
      context,
      animation: _createAnimation(
        start: start,
        end: end,
        curve: curve,
      ),
      builder: builder,
      duration: duration,
    );
  }

  /// Move to the given position.
  ///
  /// the position is used to calculate the new alignment.
  Future<bool> moveTo(Offset position) async {
    if (!_animator.isShowing) return false;

    double dx = (position.dx - _screenCenter.dx) / _screenCenter.dx;
    double dy = (position.dy - _screenCenter.dy) / _screenCenter.dy;

    dx = dx.abs() < 1 ? dx : dx / dx.abs();
    dy = dy.abs() < 1 ? dy : dy / dy.abs();

    final newAlign = Alignment(dx, dy);

    if (_alignment == newAlign) return false;

    _alignment = newAlign;

    await _animator.drive(
      /// purposely create an always stopped animation to avoid flickering
      animation: _createAnimation(
        start: _alignment,
        end: newAlign,
      ),
      duration: const Duration(milliseconds: 300),
    );

    // ensure the alignment is synced
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
    if (!_animator.isShowing) return;

    final newAlign = switch (axis) {
      Axis.horizontal => _adjustHorizontal(),
      Axis.vertical => _adjustVertical(),
    };

    if (_alignment == newAlign) return;

    await _animator.drive(
      animation: _createAnimation(
        start: _alignment,
        end: newAlign,
      ),
      duration: duration,
    );

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

  Animation<Alignment> _createAnimation({
    Alignment? start,
    Alignment? end,
    Curve? curve,
  }) {
    assert(
      start != null || end != null,
      'Either start or end alignment must be provided',
    );

    final tween = AlignmentTween(
      begin: start ?? _alignment,
      end: end ?? _alignment,
    );

    if (tween.begin == tween.end) {
      return AlwaysStoppedAnimation<Alignment>(tween.end!);
    }

    return tween.animate(
      CurvedAnimation(
        parent: _animator.parent,
        curve: curve ?? Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _animator.dispose();
  }

  @override
  void hide() {
    _animator.hide();
  }
}
