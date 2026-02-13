import 'package:acre_labs/misc/scale_draggable_controller.dart';
import 'package:flutter/material.dart';

class ScaleDraggableInteractiveViewer extends StatefulWidget {
  final double minScale;
  final double maxScale;
  final double scaleSensitivity;
  final double? initialScale;
  final Offset? initialOffset;
  final ScaleDraggableController? controller;
  final Clip clipBehavior;
  final Widget child;

  const ScaleDraggableInteractiveViewer({
    super.key,
    this.controller,
    this.minScale = 0.5,
    this.maxScale = 5.0,
    this.scaleSensitivity = 0.001,
    this.initialScale,
    this.initialOffset,
    this.clipBehavior = Clip.hardEdge,
    required this.child,
  });

  @override
  State<ScaleDraggableInteractiveViewer> createState() =>
      _ScaleDraggableInteractiveViewerState();
}

class _ScaleDraggableInteractiveViewerState
    extends State<ScaleDraggableInteractiveViewer> {
  ScaleDraggableController? _fallbackController;

  ScaleDraggableController get _effectiveController =>
      widget.controller ??
      (_fallbackController ??= ScaleDraggableController(
        initialScale: widget.initialScale,
        initialOffset: widget.initialOffset,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
      ));

  final childKey = GlobalKey();

  @override
  void dispose() {
    _fallbackController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _effectiveController.scaleByMouse,
      child: GestureDetector(
        onDoubleTap: () {
          _effectiveController.restore();
        },
        onPanStart: (details) {
          _effectiveController.startDragging(details.localPosition);
        },
        onPanUpdate: (details) {
          _effectiveController.updateDragging(details.localPosition);
        },
        onPanEnd: (details) {
          _effectiveController.endDragging();
        },
        child: ListenableBuilder(
          listenable: _effectiveController,
          builder: (_, child) {
            _measureSizes();

            return MouseRegion(
              cursor: _effectiveController.offset == Offset.zero
                  ? SystemMouseCursors.zoomIn
                  : SystemMouseCursors.grabbing,
              child: Transform(
                transform: _effectiveController.transform,
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: childKey,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Size _viewportSize = Size.zero;
  Size _childSize = Size.zero;

  void _measureSizes() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _effectiveController.viewportSize = context.size ?? Size.zero;
      print(
        "offset: ${_effectiveController.offset}, scale: ${_effectiveController.scale}",
      );
    });
  }
}
