import 'dart:math';

import 'package:acre_labs/table_grid/controller.dart';
import 'package:acre_labs/table_grid/models.dart';
import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'cell_detail.dart';

class TableGrid extends StatefulWidget {
  final TableController controller;
  final ScrollController? horizontalScrollController;
  final ScrollController? verticalScrollController;
  final ScrollPhysics? horizontalScrollPhysics;
  final ScrollPhysics? verticalScrollPhysics;
  final TableCellDetailBuilder<TableCellDetail> cellBuilder;
  final TableCellDetailBuilder<ColumnHeaderDetail> columnBuilder;
  final WidgetBuilder? placeholderBuilder;
  final int placeholderWidthExtent;

  const TableGrid({
    super.key,
    required this.controller,
    required this.cellBuilder,
    required this.columnBuilder,
    this.horizontalScrollController,
    this.horizontalScrollPhysics,
    this.verticalScrollController,
    this.verticalScrollPhysics,
    this.placeholderBuilder,
    this.placeholderWidthExtent = 1,
  });

  @override
  State<TableGrid> createState() => _TableGridState();
}

class _TableGridState extends State<TableGrid> {
  // final Map<CellIndex, CachedCellDetailWidget> _cachedCells = {};
  // final Map<CellIndex, CachedCellDetailWidget> _cachedColumnHeaders = {};

  // @override
  // void didUpdateWidget(covariant TableGrid oldWidget) {
  //   super.didUpdateWidget(oldWidget);

  //   if (widget.controller != oldWidget.controller) {
  //     _cachedCells.clear();
  //     _cachedColumnHeaders.clear();
  //   }

  //   if (widget.cellBuilder != oldWidget.cellBuilder) {
  //     _cachedCells.clear();
  //   }

  //   if (widget.columnBuilder != oldWidget.columnBuilder) {
  //     _cachedColumnHeaders.clear();
  //   }
  // }

  // @override
  // void reassemble() {
  //   super.reassemble();
  //   _cachedCells.clear();
  //   _cachedColumnHeaders.clear();
  // }

  // @override
  // void dispose() {
  //   _cachedCells.clear();
  //   _cachedColumnHeaders.clear();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller.listenable,
      builder: (_, __) {
        return TableView.builder(
          horizontalDetails: ScrollableDetails.horizontal(
            controller: widget.horizontalScrollController,
            physics: widget.horizontalScrollPhysics,
          ),
          verticalDetails: ScrollableDetails.vertical(
            controller: widget.verticalScrollController,
            physics: widget.verticalScrollPhysics,
          ),
          columnCount: widget.controller.columnCount,
          rowCount: widget.controller.rowCount,
          pinnedColumnCount: widget.controller.pinnedColumnCount,
          pinnedRowCount: widget.controller.pinnedRowCount,
          columnBuilder: (int columnIndex) {
            return widget.controller.buildColumnSpan(columnIndex);
          },
          rowBuilder: (int rowIndex) {
            return widget.controller.buildRowSpan(rowIndex);
          },
          cellBuilder: (ctx, vicinity) {
            final listenable =
                widget.controller.getCellActionNotifier(vicinity);

            final extentRange = widget.controller.isPlaceholderRow(vicinity)
                ? _calculatePlaceholderWidthExtent(
                    widget.controller.columnCount,
                    widget.controller.pinnedColumnCount,
                  )
                : null;

            return TableViewCell(
              columnMergeStart: extentRange?.$1,
              columnMergeSpan: extentRange?.$2,
              child: listenable != null
                  ? ListenableBuilder(
                      listenable: listenable,
                      builder: (context, _) =>
                          _buildCellChild(context, vicinity),
                    )
                  : _buildCellChild(context, vicinity),
            );
          },
        );
      },
    );
  }

  Widget _buildCellChild(BuildContext context, TableVicinity vicinity) {
    final isPlaceholderRow = widget.controller.isPlaceholderRow(vicinity);

    if (isPlaceholderRow) {
      return widget.placeholderBuilder?.call(context) ??
          const SizedBox.shrink();
    }

    final detail = widget.controller.getCellDetail(vicinity);

    final child = switch (detail) {
      ColumnHeaderDetail() => widget.columnBuilder(context, detail),
      TableCellDetail() => widget.cellBuilder(context, detail),
    };

    return KeyedSubtree(
      // key: ValueKey(detail),
      child: child,
    );
  }

  (int, int) _calculatePlaceholderWidthExtent(
    int columnCount,
    int pinnedColumnCount,
  ) {
    final count =
        min(columnCount - pinnedColumnCount - 1, widget.placeholderWidthExtent);

    return (pinnedColumnCount, count);
  }

  // Widget _putCachedColumnHeaderIfAbsent(
  //   CellIndex index,
  //   CachedCellDetailWidget Function(CellDetail) builder,
  // ) {
  //   final cached = _cachedColumnHeaders[index];

  //   final newDetail = widget.controller.getCellDetailByIndex(index);

  //   if (cached != null && cached.detail == newDetail) {
  //     return cached.child;
  //   } else {
  //     final newCached = builder(newDetail);

  //     _cachedColumnHeaders[index] = newCached;

  //     return newCached.child;
  //   }
  // }

  // Widget _putCachedCellIfAbsent(
  //   CellIndex index,
  //   CachedCellDetailWidget Function(CellDetail) builder,
  // ) {
  //   final cached = _cachedCells[index];

  //   final newDetail = widget.controller.getCellDetailByIndex(index);

  //   if (cached != null && cached.detail == newDetail) {
  //     return cached.child;
  //   } else {
  //     final newCached = builder(newDetail);

  //     _cachedCells[index] = newCached;

  //     return newCached.child;
  //   }
  // }
}
