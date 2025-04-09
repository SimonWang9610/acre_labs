// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/widgets.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

sealed class TableExtent {
  const TableExtent();

  SpanExtent get spanExtent;

  factory TableExtent.fixed(double pixels) {
    return _FixedTableExtent(pixels);
  }
  factory TableExtent.fractional(double fraction) {
    return _FractionalTableExtent(fraction);
  }

  factory TableExtent.ranged(double min, double max) {
    return _RangedTableExtent(min, max);
  }
}

final class _FixedTableExtent extends TableExtent {
  final double pixels;

  const _FixedTableExtent(this.pixels)
      : assert(pixels >= 0, "pixels must be non-negative");

  @override
  SpanExtent get spanExtent => FixedSpanExtent(pixels);
}

final class _FractionalTableExtent extends TableExtent {
  final double fraction;

  const _FractionalTableExtent(this.fraction)
      : assert(
            fraction >= 0 && fraction <= 1, "fraction must be between 0 and 1");

  @override
  SpanExtent get spanExtent => FractionalSpanExtent(fraction);
}

final class _RangedTableExtent extends TableExtent {
  final double min;
  final double max;

  const _RangedTableExtent(this.min, this.max)
      : assert(min >= 0 && max >= min, "min and max must be non-negative");

  @override
  SpanExtent get spanExtent {
    if (max == min) {
      return FixedSpanExtent(min);
    } else {
      return MaxSpanExtent(
        FixedSpanExtent(min),
        FixedSpanExtent(max),
      );
    }
  }
}

class TableGridBorder {
  final bool foreground;
  final BorderSide? vertical;
  final BorderSide? horizontal;

  const TableGridBorder({
    this.vertical,
    this.horizontal,
    this.foreground = false,
  });

  TableSpan build({
    required Axis axis,
    required TableExtent extent,
    bool last = false,
  }) {
    final padding = switch (axis) {
      Axis.horizontal => SpanPadding(
          trailing: last ? 0 : horizontal?.width ?? 0,
        ),
      Axis.vertical => SpanPadding(
          trailing: last ? 0 : vertical?.width ?? 0,
        ),
    };

    final border = switch (axis) {
      Axis.horizontal => SpanBorder(
          trailing: last ? BorderSide.none : horizontal ?? BorderSide.none,
        ),
      Axis.vertical => SpanBorder(
          trailing: last ? BorderSide.none : vertical ?? BorderSide.none,
        ),
    };

    final decoration = SpanDecoration(
      consumeSpanPadding: true,
      border: border,
    );

    return TableSpan(
      extent: extent.spanExtent,
      padding: padding,
      backgroundDecoration: !foreground ? decoration : null,
      foregroundDecoration: foreground ? decoration : null,
    );
  }

  @override
  bool operator ==(covariant TableGridBorder other) {
    if (identical(this, other)) return true;

    return other.foreground == foreground &&
        other.vertical == vertical &&
        other.horizontal == horizontal;
  }

  @override
  int get hashCode {
    return foreground.hashCode ^ vertical.hashCode ^ horizontal.hashCode;
  }
}
