import 'package:flutter/cupertino.dart';

class OverlayAlignment {
  final Offset center;
  final double scale;

  Alignment _alignment;

  Alignment get value => _alignment;

  OverlayAlignment({
    required Size screenSize,
    Alignment? alignment,
    this.scale = 0.95,
  }) : center = Offset(screenSize.width / 2, screenSize.height / 2),
       _alignment = alignment ?? Alignment(scale, 0);

  /// Adjust alignment based on the given axis.
  ///
  /// It will align to the closest edge on the given axis.
  ///
  /// [Axis.horizontal]: align to left or right edge.
  ///
  /// [Axis.vertical]: align to top or bottom edge.
  Alignment adjust(Axis axis) {
    final align = switch (axis) {
      Axis.horizontal => _adjustHorizontal(),
      Axis.vertical => _adjustVertical(),
    };

    _alignment = align;

    return align;
  }

  /// Move to the given position.
  ///
  /// the position is used to calculate the new alignment.
  bool moveTo(Offset position) {
    double dx = (position.dx - center.dx) / center.dx;
    double dy = (position.dy - center.dy) / center.dy;

    dx = dx.abs() < 1 ? dx : dx / dx.abs();
    dy = dy.abs() < 1 ? dy : dy / dy.abs();

    final newAlign = Alignment(dx, dy);

    if (_alignment == newAlign) return false;

    _alignment = newAlign;
    return true;
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
}

class OverlayAlignmentAnimator {
  final AnimationController controller;

  OverlayAlignmentAnimator(this.controller) : _enabled = false;

  bool _enabled;

  Animation<AlignmentGeometry>? _animation;

  Animation<AlignmentGeometry> get animation => _animation!;

  void animate({
    Alignment? begin,
    required Alignment end,
    bool startAfterCreated = false,
    Curve? curve,
    Duration? duration,
  }) {
    _enabled = startAfterCreated;

    if (!_enabled || begin == null || begin == end) {
      _animation = AlwaysStoppedAnimation<AlignmentGeometry>(end);
    } else {
      _animation = Tween<AlignmentGeometry>(begin: begin, end: end).animate(
        CurvedAnimation(parent: controller, curve: curve ?? Curves.easeInOut),
      );
    }

    if (duration != null) {
      controller.duration = duration;
    }

    if (_enabled) {
      if (!controller.isDismissed) {
        controller.reset();
      }

      controller.forward();
    } else {
      _rebuildListener?.call();
    }
  }

  VoidCallback? _rebuildListener;

  void addRebuildListener(VoidCallback listener) {
    if (listener == _rebuildListener) {
      return;
    }

    if (_rebuildListener != null) {
      controller.removeListener(_rebuildListener!);
    }

    _rebuildListener = listener;

    controller.addListener(_rebuildListener!);
  }

  void dispose() {
    if (_rebuildListener != null) {
      controller.removeListener(_rebuildListener!);
    }
    controller.dispose();
  }
}
