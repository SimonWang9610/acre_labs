import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

abstract class ScaleDraggableController extends ChangeNotifier {
  ScaleDraggableController._();

  double get scale;
  Offset get offset;

  Matrix4 get transform => Matrix4.identity()
    ..translateByDouble(offset.dx, offset.dy, 0, 1.0)
    ..scaleByDouble(scale, scale, scale, 1.0);

  void startDragging(Offset localPosition);
  void updateDragging(Offset localPosition);
  void endDragging();

  void scaleByMouse(PointerSignalEvent event);
  void scaleByGesture(ScaleUpdateDetails details);

  bool apply({double? newScale, Offset? newOffset});

  set viewportSize(Size size) {}

  void restore();

  factory ScaleDraggableController({
    double minScale = 0.5,
    double maxScale = 5.0,
    double scaleSensitivity = 0.001,
    double? initialScale,
    Offset? initialOffset,
  }) => _ScaleDraggableControllerImpl(
    minScale: minScale,
    maxScale: maxScale,
    scaleSensitivity: scaleSensitivity,
    initialScale: initialScale,
    initialOffset: initialOffset,
  );
}

final class _ScaleDraggableControllerImpl extends ScaleDraggableController
    with
        ScaledFocalConstraintMixin,
        DragFocalPoint,
        ScaleAroundFocalPointMixin {
  _ScaleDraggableControllerImpl({
    double minScale = 0.5,
    double maxScale = 5.0,
    double scaleSensitivity = 0.001,
    double? initialScale,
    Offset? initialOffset,
  }) : assert(maxScale >= minScale),
       super._() {
    _minScale = minScale;
    _maxScale = maxScale;
    _scaleSensitivity = scaleSensitivity;

    _scale = initialScale?.clamp(minScale, maxScale) ?? 1.0;
    _offset = initialOffset ?? Offset.zero;
  }
}

mixin DragFocalPoint on ScaleDraggableController {
  Offset? _lastFocalPoint;

  @override
  void startDragging(Offset localPosition) {
    _lastFocalPoint = localPosition;
  }

  @override
  void endDragging() {
    _lastFocalPoint = null;
  }

  @override
  void updateDragging(Offset localPosition) {
    if (_lastFocalPoint == null) return;

    final delta = localPosition - _lastFocalPoint!;

    final updated = apply(newScale: scale, newOffset: offset + delta);

    if (updated) {
      _lastFocalPoint = localPosition;
    }
  }
}

mixin ScaleAroundFocalPointMixin on ScaleDraggableController, DragFocalPoint {
  double _scaleSensitivity = 0.001;
  double get scaleSensitivity => _scaleSensitivity;
  set scaleSensitivity(double value) {
    if (value <= 0) throw ArgumentError('scaleSensitivity must be > 0');
    _scaleSensitivity = value;
  }

  double _minScale = 0.5;
  double get minScale => _minScale;
  set minScale(double value) {
    if (value <= 0) throw ArgumentError('minScale must be > 0');
    _minScale = value;
    if (scale < _minScale) {
      apply(newScale: _minScale, newOffset: Offset.zero);
    }
  }

  double _maxScale = 5.0;
  double get maxScale => _maxScale;
  set maxScale(double value) {
    if (value < _minScale) {
      throw ArgumentError('maxScale must be >= $_minScale');
    }
    _maxScale = value;
    if (scale > _maxScale) {
      apply(newScale: _maxScale, newOffset: Offset.zero);
    }
  }

  @override
  void restore() {
    apply(newScale: 1.0, newOffset: Offset.zero);
  }

  @override
  void scaleByMouse(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final delta = -event.scrollDelta.dy * _scaleSensitivity;
    _apply(delta, event.localPosition);
  }

  @override
  void scaleByGesture(ScaleUpdateDetails details) {
    final scaleDelta = details.scale - 1.0;
    _apply(scaleDelta, details.focalPoint);
  }

  void _apply(double scaleDelta, Offset focalPoint) {
    final newScale = (scale + scaleDelta * scale).clamp(
      minScale,
      maxScale,
    );

    // Adjust offset so that the pixel under the cursor stays fixed.
    // offset_new = focalPoint - (focalPoint - offset_old) * (newScale / oldScale)
    final ratio = newScale / scale;
    final newOffset = focalPoint - (focalPoint - offset) * ratio;

    apply(newScale: newScale, newOffset: newOffset);
  }
}

mixin ScaledFocalConstraintMixin on ScaleDraggableController {
  Size? _viewportSize;

  @override
  set viewportSize(Size size) {
    if (size == _viewportSize) return;
    _viewportSize = size;
    apply(newScale: scale, newOffset: offset);
  }

  Offset _offset = Offset.zero;
  double _scale = 1.0;

  @override
  Offset get offset => _offset;

  @override
  double get scale => _scale;

  @override
  bool apply({double? newScale, Offset? newOffset}) {
    bool shouldNotify = false;

    if (newScale != null && newScale != _scale) {
      shouldNotify = true;
      _scale = newScale;
    }

    if (newOffset != null) {
      final clamped = _clamp(newOffset);

      if (clamped != _offset) {
        _offset = clamped;
        shouldNotify = true;
      }
    }

    if (shouldNotify) {
      notifyListeners();
    }

    return shouldNotify;
  }

  /// Clamps the focal point to ensure the content doesn't move out of bounds when scaling.
  ///
  /// if the content is scaled down (scale < 1),
  /// the focal point is clamped to the center of the viewport to prevent drifting.
  ///
  /// if the content is scaled up (scale > 1),
  /// the focal point is clamped to ensure that the edges of the content cannot be dragged inside the viewport.
  ///
  Offset _clamp(Offset offset) {
    if (_viewportSize == null || _viewportSize == Size.zero) return offset;

    final widthDiff = (1 - scale) * _viewportSize!.width;
    final heightDiff = (1 - scale) * _viewportSize!.height;

    /// The given [offset] describe the position of the scaled content's origin (top-left corner) relative to the viewport's origin.
    ///
    /// so we restrict the offset to be within [widthDiff, 0] for x and [heightDiff, 0] for y when scaled up,
    /// preventing the scaled content's origin from being dragged inside the viewport,
    /// which would cause empty space to appear.
    final dx = widthDiff < 0 ? offset.dx.clamp(widthDiff, 0.0) : widthDiff / 2;
    final dy = heightDiff < 0
        ? offset.dy.clamp(heightDiff, 0.0)
        : heightDiff / 2;

    return Offset(dx, dy);
  }
}
