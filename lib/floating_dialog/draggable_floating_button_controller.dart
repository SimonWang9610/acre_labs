import 'package:flutter/widgets.dart';

import 'overlay/animated_overlay.dart';
import 'overlay/overlay_alignment.dart';

class FloatingDialogController extends AnimatedOverlay {
  FloatingDialogController();

  OverlayEntry? _overlay;

  OverlayAlignmentAnimator? _animator;
  OverlayAlignment? _alignment;

  bool _showing = false;
  bool get isShowing => _showing;

  // todo: allow show a different widget when the previous one is showing
  void show(
    BuildContext context,
    WidgetBuilder builder, {
    bool useSafeArea = true,
    Tween<Alignment>? alignment,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (isShowing) return;

    _animator ??= OverlayAlignmentAnimator(createController(duration))
      ..addRebuildListener(_rebuild);

    _overlay ??= createOverlay(
      builder: (innerContext) =>
          _buildOverlayChild(innerContext, builder, useSafeArea: useSafeArea),
    );

    Overlay.of(context).insert(_overlay!);

    _alignment = OverlayAlignment(
      screenSize: MediaQuery.of(context).size,
      alignment: alignment?.end,
    );
    _animator?.animate(
      begin: alignment?.begin ?? Alignment.center,
      end: _alignment!.value,
      startAfterCreated: true,
    );

    _showing = true;
  }

  void hide() {
    if (!isShowing) return;

    _overlay?.remove();
    _overlay = null;
    _alignment = null;
    _showing = false;
  }

  void dispose() {
    hide();
    _animator?.dispose();
    _animator = null;
  }

  void move(Offset offset) {
    if (!isShowing) return;

    if (_alignment!.moveTo(offset)) {
      _animator?.animate(end: _alignment!.value);
      // _overlay?.markNeedsBuild();
    }
  }

  void autoAlign(Axis axis) {
    if (!isShowing) return;
    final newAlign = _alignment!.adjust(axis);

    _animator?.animate(
      begin: _alignment!.value,
      end: newAlign,
      startAfterCreated: true,
    );
  }

  void _rebuild() {
    _overlay?.markNeedsBuild();
  }

  Widget _buildOverlayChild(
    BuildContext context,
    WidgetBuilder builder, {
    bool useSafeArea = true,
  }) {
    return _AnimatedAlign(
      animation: _animator!.animation,
      child: useSafeArea ? SafeArea(child: builder(context)) : builder(context),
    );
  }
}

class _AnimatedAlign extends AnimatedWidget {
  final Animation<AlignmentGeometry> animation;
  final Widget child;
  const _AnimatedAlign({required this.child, required this.animation})
      : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return Align(alignment: animation.value, child: child);
  }
}
