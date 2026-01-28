import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

final _pipelineOwner = PipelineOwner();

abstract interface class SnapshotTask {
  Future<Uint8List> run({ui.ImageByteFormat format = ui.ImageByteFormat.png});
}

final class OnlineSnapshotTask implements SnapshotTask {
  final RenderRepaintBoundary boundary;
  final double pixelRatio;

  const OnlineSnapshotTask({
    required this.boundary,
    this.pixelRatio = 1.0,
  });

  factory OnlineSnapshotTask.withContext(BuildContext context,
      {double? pixelRatio}) {
    final boundary = context.findRenderObject() as RenderRepaintBoundary? ??
        (throw ArgumentError(
            'The provided context does not contain a RenderRepaintBoundary.'));

    return OnlineSnapshotTask(
      boundary: boundary,
      pixelRatio: pixelRatio ?? View.of(context).devicePixelRatio,
    );
  }

  @override
  Future<Uint8List> run(
      {ui.ImageByteFormat format = ui.ImageByteFormat.png}) async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);

    return _imageToBytes(image, format);
  }
}

final class OfflineSnapshotTask implements SnapshotTask {
  final Widget target;
  final Future signal;
  final Size? logicalSize;
  final Size? imageSize;
  late final FlutterView _view;

  OfflineSnapshotTask({
    required this.target,
    required this.signal,
    this.logicalSize,
    this.imageSize,
    FlutterView? view,
  }) {
    _view = view ?? PlatformDispatcher.instance.implicitView!;
  }

  factory OfflineSnapshotTask.withContext(
    BuildContext context, {
    required Future signal,
    required Widget target,
    Size? imageSize,
    Size? logicalSize,
  }) {
    final view = View.of(context);

    final lSize = logicalSize ??
        view.physicalSize / view.devicePixelRatio; // logical size

    final iSize = imageSize ?? view.physicalSize; // image size

    return OfflineSnapshotTask(
      target: target,
      signal: signal,
      logicalSize: Size.fromWidth(lSize.width),
      imageSize: Size.fromWidth(iSize.width),
      view: view,
    );
  }

  @override
  Future<Uint8List> run({
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    // final pipelineOwner = PipelineOwner();
    final focusManager = FocusManager();
    final buildOwner = BuildOwner(focusManager: focusManager);
    final repaintBoundary = RenderRepaintBoundary();

    final lSize = logicalSize ??
        _view.physicalSize / _view.devicePixelRatio; // logical size
    final iSize = imageSize ?? _view.physicalSize; // image size

    assert(lSize.aspectRatio == iSize.aspectRatio,
        'The aspect ratio of logicalSize and imageSize must be the same.');

    final renderView = RenderView(
      // child: RenderPositionedBox(
      //   alignment: Alignment.topCenter,
      //   child: repaintBoundary,
      // ),
      child: repaintBoundary,
      configuration: ViewConfiguration(
        // physicalConstraints: BoxConstraints.tight(_view.physicalSize),
        logicalConstraints: BoxConstraints.loose(lSize),
        devicePixelRatio: _view.devicePixelRatio,
      ),
      view: _view,
    );

    try {
      _pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      final RenderObjectToWidgetElement<RenderBox> rootElement =
          RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,

        /// ensure the View.of(context) works in the target widget
        /// typically for scrollable widgets
        child: MediaQuery.fromView(
          view: _view,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.black),
              child: target,
            ),
          ),
        ),
      ).attachToRenderTree(buildOwner);

      buildOwner.buildScope(rootElement);

      await signal;

      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();

      _pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

      final pixelRatio = iSize.width / lSize.width;

      final ui.Image image = await repaintBoundary.toImage(
        pixelRatio: pixelRatio,
      );

      print("render view: ${renderView.size}");

      print('Image size: ${image.width} x ${image.height}, '
          'requested: ${iSize.width} x ${iSize.height}, '
          'logical size: ${lSize.width} x ${lSize.height}, '
          'pixel ratio: $pixelRatio');

      return _imageToBytes(image, format);
    } catch (e) {
      rethrow;
    } finally {
      buildOwner.finalizeTree();
      focusManager.dispose();
      renderView.dispose();
    }
  }
}

Future<Uint8List> _imageToBytes(
    ui.Image image, ui.ImageByteFormat format) async {
  final byteData = await image.toByteData(format: format);

  return byteData!.buffer.asUint8List();
}
