// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

sealed class CellSpan {
  final CellSpanDecoration? decoration;
  final bool background;

  const CellSpan({
    this.decoration,
    this.background = true,
  });

  factory CellSpan.fixed({
    required double pixels,
    CellSpanDecoration? decoration,
    bool background = true,
  }) {
    return _FixedCellSpan(
      pixels: pixels,
      decoration: decoration,
      background: background,
    );
  }

  factory CellSpan.fractional({
    required double fraction,
    CellSpanDecoration? decoration,
    bool background = true,
  }) {
    return _FractionalCellSpan(
      fraction: fraction,
      decoration: decoration,
      background: background,
    );
  }

  factory CellSpan.range({
    double min = 0,
    required double max,
    CellSpanDecoration? decoration,
    bool background = true,
  }) {
    return _RangeCellSpan(
      min: min,
      max: max,
      decoration: decoration,
      background: background,
    );
  }

  CellSpan copyWith({
    double? pixels,
    double? fraction,
    double? min,
    double? max,
    CellSpanDecoration? decoration,
    bool? background,
  }) {
    return switch (this) {
      _FixedCellSpan(pixels: final old) => CellSpan.fixed(
          pixels: pixels ?? old,
          decoration: decoration ?? this.decoration,
          background: background ?? this.background,
        ),
      _FractionalCellSpan(fraction: final old) => CellSpan.fractional(
          fraction: fraction ?? old,
          decoration: decoration ?? this.decoration,
          background: background ?? this.background,
        ),
      _RangeCellSpan(min: final oldMin, max: final oldMax) => CellSpan.range(
          min: min ?? oldMin,
          max: max ?? oldMax,
          decoration: decoration ?? this.decoration,
          background: background ?? this.background,
        ),
    };
  }

  TableSpan build({
    Map<Type, GestureRecognizerFactory> recognizerFactories = const {},
    PointerEnterEventListener? onEnter,
    PointerExitEventListener? onExit,
    MouseCursor cursor = MouseCursor.defer,
  });
}

final class _FixedCellSpan extends CellSpan {
  final double pixels;

  const _FixedCellSpan({
    required this.pixels,
    super.decoration,
    super.background,
  });

  @override
  TableSpan build({
    Map<Type, GestureRecognizerFactory> recognizerFactories = const {},
    PointerEnterEventListener? onEnter,
    PointerExitEventListener? onExit,
    MouseCursor cursor = MouseCursor.defer,
  }) {
    assert(
      pixels >= 0,
      'pixels must be greater than or equal to 0',
    );

    final spanDecoration = decoration?.spanDecoration;

    return TableSpan(
      extent: FixedTableSpanExtent(pixels),
      backgroundDecoration: background ? spanDecoration : null,
      foregroundDecoration: !background ? spanDecoration : null,
      recognizerFactories: recognizerFactories,
      cursor: cursor,
      onEnter: onEnter,
      onExit: onExit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _FixedCellSpan) return false;
    return pixels == other.pixels &&
        decoration == other.decoration &&
        background == other.background;
  }

  @override
  int get hashCode {
    return pixels.hashCode ^ decoration.hashCode ^ background.hashCode;
  }

  @override
  String toString() {
    return 'CellSpan.fixed(pixels: $pixels)';
  }
}

final class _FractionalCellSpan extends CellSpan {
  final double fraction;

  const _FractionalCellSpan({
    required this.fraction,
    super.decoration,
    super.background,
  });

  @override
  TableSpan build({
    Map<Type, GestureRecognizerFactory> recognizerFactories = const {},
    PointerEnterEventListener? onEnter,
    PointerExitEventListener? onExit,
    MouseCursor cursor = MouseCursor.defer,
  }) {
    assert(
      fraction >= 0 && fraction <= 1,
      'fraction must be between 0 and 1',
    );

    final spanDecoration = decoration?.spanDecoration;

    if (fraction == 0) {
      return TableSpan(
        extent: FixedTableSpanExtent(0),
        backgroundDecoration: background ? spanDecoration : null,
        foregroundDecoration: !background ? spanDecoration : null,
      );
    }

    return TableSpan(
      extent: FractionalTableSpanExtent(fraction),
      backgroundDecoration: background ? spanDecoration : null,
      foregroundDecoration: !background ? spanDecoration : null,
      recognizerFactories: recognizerFactories,
      onEnter: onEnter,
      onExit: onExit,
      cursor: cursor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _FractionalCellSpan) return false;
    return fraction == other.fraction &&
        decoration == other.decoration &&
        background == other.background;
  }

  @override
  int get hashCode {
    return fraction.hashCode ^ decoration.hashCode ^ background.hashCode;
  }

  @override
  String toString() {
    return 'CellSpan.fractional(fraction: $fraction)';
  }
}

final class _RangeCellSpan extends CellSpan {
  final double min;
  final double max;

  const _RangeCellSpan({
    this.min = 0,
    required this.max,
    super.decoration,
    super.background,
  });

  @override
  TableSpan build({
    Map<Type, GestureRecognizerFactory> recognizerFactories = const {},
    PointerEnterEventListener? onEnter,
    PointerExitEventListener? onExit,
    MouseCursor cursor = MouseCursor.defer,
  }) {
    assert(
      min >= 0 && max >= 0,
      'min and max must be greater than or equal to 0',
    );

    assert(
      min <= max,
      'min must be less than or equal to max',
    );

    final spanDecoration = decoration?.spanDecoration;

    final extent = max == min
        ? FixedTableSpanExtent(min)
        : MaxSpanExtent(
            FixedTableSpanExtent(min),
            FixedTableSpanExtent(max),
          );

    return TableSpan(
      extent: extent,
      backgroundDecoration: background ? spanDecoration : null,
      foregroundDecoration: !background ? spanDecoration : null,
      recognizerFactories: recognizerFactories,
      onEnter: onEnter,
      onExit: onExit,
      cursor: cursor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _RangeCellSpan) return false;
    return min == other.min &&
        max == other.max &&
        decoration == other.decoration &&
        background == other.background;
  }

  @override
  int get hashCode {
    return min.hashCode ^
        max.hashCode ^
        decoration.hashCode ^
        background.hashCode;
  }

  @override
  String toString() {
    return 'CellSpan.range(min: $min, max: $max)';
  }
}

class CellSpanDecoration {
  final BorderSide leading;
  final BorderSide trailing;
  final BorderRadius? borderRadius;
  final Color? filledColor;
  final bool consumePadding;

  const CellSpanDecoration({
    this.leading = BorderSide.none,
    this.trailing = BorderSide.none,
    this.borderRadius,
    this.filledColor,
    this.consumePadding = true,
  });

  CellSpanDecoration copyWith({
    BorderSide? leading,
    BorderSide? trailing,
    BorderRadius? borderRadius,
    Color? filledColor,
    bool? consumePadding,
  }) {
    return CellSpanDecoration(
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      borderRadius: borderRadius ?? this.borderRadius,
      filledColor: filledColor ?? this.filledColor,
      consumePadding: consumePadding ?? this.consumePadding,
    );
  }

  SpanDecoration get spanDecoration {
    return SpanDecoration(
      border: SpanBorder(
        leading: leading,
        trailing: trailing,
      ),
      borderRadius: borderRadius,
      color: filledColor,
      consumeSpanPadding: consumePadding,
    );
  }

  @override
  bool operator ==(covariant CellSpanDecoration other) {
    if (identical(this, other)) return true;

    return other.leading == leading &&
        other.trailing == trailing &&
        other.borderRadius == borderRadius &&
        other.filledColor == filledColor &&
        other.consumePadding == consumePadding;
  }

  @override
  int get hashCode {
    return leading.hashCode ^
        trailing.hashCode ^
        borderRadius.hashCode ^
        filledColor.hashCode ^
        consumePadding.hashCode;
  }
}
