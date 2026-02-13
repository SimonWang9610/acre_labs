import 'package:acre_labs/misc/scale_draggable_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A widget that allows its child to be scaled via mouse wheel
/// and dragged (panned) when scaled beyond its original size.
///
/// Usage:
/// ```dart
/// ScalePanWidget(
///   minScale: 0.5,
///   maxScale: 5.0,
///   child: Image.asset('assets/photo.jpg'),
/// )
/// ```
class ScalePanWidget extends StatefulWidget {
  const ScalePanWidget({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 5.0,
    this.scaleSensitivity = 0.001,
    this.clipBehavior = Clip.hardEdge,
  }) : assert(minScale > 0, 'minScale must be > 0'),
       assert(maxScale >= minScale, 'maxScale must be >= minScale');

  /// The widget to be scaled and panned.
  final Widget child;

  /// Minimum allowed scale factor. Defaults to 0.5.
  final double minScale;

  /// Maximum allowed scale factor. Defaults to 5.0.
  final double maxScale;

  /// How sensitive the mouse-wheel zoom feels.
  /// Higher values zoom faster. Defaults to 0.001.
  final double scaleSensitivity;

  /// Clip behaviour applied to the viewport. Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  @override
  State<ScalePanWidget> createState() => _ScalePanWidgetState();
}

class _ScalePanWidgetState extends State<ScalePanWidget> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // Tracks the pointer position during drag so we can compute delta.
  Offset? _lastFocalPoint;

  // ─── Mouse-wheel zoom ────────────────────────────────────────────────────

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final delta = -event.scrollDelta.dy * widget.scaleSensitivity;
    _applyScaleAroundFocalPoint(delta, event.localPosition);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Apply scale change
    if (details.scale != 1.0) {
      final scaleDelta = details.scale - 1.0;
      _applyScaleAroundFocalPoint(scaleDelta, details.focalPoint);
    }

    // Apply pan change
    if (details.focalPointDelta != Offset.zero) {
      setState(() {
        _offset += details.focalPointDelta;
      });
    }
  }

  /// Scales by [scaleDelta] while keeping [focalPoint] visually stationary.
  void _applyScaleAroundFocalPoint(double scaleDelta, Offset focalPoint) {
    final newScale = (_scale + scaleDelta * _scale).clamp(
      widget.minScale,
      widget.maxScale,
    );

    if (newScale == _scale) return;

    // Adjust offset so that the pixel under the cursor stays fixed.
    // offset_new = focalPoint - (focalPoint - offset_old) * (newScale / oldScale)
    final ratio = newScale / _scale;
    final newOffset = focalPoint - (focalPoint - _offset) * ratio;

    setState(() {
      _scale = newScale;
      _offset = newOffset;
    });
  }

  // ─── Drag / pan ──────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    _lastFocalPoint = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastFocalPoint == null) return;

    final delta = details.localPosition - _lastFocalPoint!;
    _lastFocalPoint = details.localPosition;

    setState(() {
      _offset += delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _lastFocalPoint = null;
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Only show the drag cursor / enable panning when the child is scaled up.
    final isPanned = _scale > 1.0;

    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        onPanStart: isPanned ? _onPanStart : null,
        onPanUpdate: isPanned ? _onPanUpdate : null,
        onPanEnd: isPanned ? _onPanEnd : null,
        onDoubleTap: () {
          setState(() {
            _scale = 1.0;
            _offset = Offset.zero;
          });
        },
        child: MouseRegion(
          cursor: isPanned ? SystemMouseCursors.grab : MouseCursor.defer,
          child: ClipRect(
            clipBehavior: widget.clipBehavior,
            child: Transform(
              transform: Matrix4.identity()
                ..translate(_offset.dx, _offset.dy)
                ..scale(_scale),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class ScalePanDemoPage extends StatelessWidget {
  const ScalePanDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ScalePanWidget Demo')),
      body: Column(
        children: [
          // Hint bar
          Container(
            width: double.infinity,
            color: Colors.white10,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Text(
              '🖱  Scroll to zoom  •  Drag to pan when zoomed in',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          // The interactive viewport
          // Expanded(
          //   child: ScalePanWidget(
          //     minScale: 0.3,
          //     maxScale: 8.0,
          //     child: _DemoContent(),
          //   ),
          // ),
          Expanded(
            child: ScaleDraggableInteractiveViewer(
              child: _DemoContent(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rich content widget to demonstrate the ScalePanWidget.
class _DemoContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 900,
      height: 600,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Grid of circles
          ..._buildGridDots(),
          // Center card
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.zoom_in_map_rounded,
                    size: 56,
                    color: Colors.cyanAccent,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ScalePanWidget',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scroll to zoom • Drag to pan',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          // Corner labels to make panning obvious
          for (final item in _cornerItems)
            Positioned(
              left: item.left,
              top: item.top,
              right: item.right,
              bottom: item.bottom,
              child: _CornerBadge(label: item.label, color: item.color),
            ),
        ],
      ),
    );
  }

  static List<Widget> _buildGridDots() {
    const count = 8;
    final dots = <Widget>[];
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        dots.add(
          Positioned(
            left: col * 115.0 + 20,
            top: row * 75.0 + 20,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }
    }
    return dots;
  }

  static final _cornerItems = [
    _CornerItem(label: 'TOP LEFT', color: Colors.pinkAccent, left: 24, top: 24),
    _CornerItem(
      label: 'TOP RIGHT',
      color: Colors.orangeAccent,
      right: 24,
      top: 24,
    ),
    _CornerItem(
      label: 'BOTTOM LEFT',
      color: Colors.greenAccent,
      left: 24,
      bottom: 24,
    ),
    _CornerItem(
      label: 'BOTTOM RIGHT',
      color: Colors.purpleAccent,
      right: 24,
      bottom: 24,
    ),
  ];
}

class _CornerItem {
  const _CornerItem({
    required this.label,
    required this.color,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });
  final String label;
  final Color color;
  final double? left, top, right, bottom;
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
