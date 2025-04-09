// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:acre_labs/table_grid/span.dart';
import 'package:flutter/material.dart';

import 'package:acre_labs/table_grid/cell_detail.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class CellIndex {
  final int row;
  final int column;

  const CellIndex(this.row, this.column)
      : assert(row >= 0 && column >= 0, "row and column must be non-negative");

  @override
  bool operator ==(covariant CellIndex other) {
    if (identical(this, other)) return true;

    return other.row == row && other.column == column;
  }

  @override
  int get hashCode => row.hashCode ^ column.hashCode;

  @override
  String toString() => 'CellIndex(row: $row, column: $column)';
}

enum TableSelectionStrategy {
  none,
  row,
  column,
  cell,
}

enum TableHoveringStrategy {
  none,
  row,
  column,
}

typedef TableCellDetailBuilder<T extends CellDetail> = Widget Function(
  BuildContext context,
  T detail,
);

typedef TableCellDataExtractor<T> = dynamic Function(
  T rowData,
  ColumnId columnId,
);
