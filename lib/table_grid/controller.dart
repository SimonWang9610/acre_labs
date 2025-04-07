import 'package:acre_labs/table_grid/cell_detail.dart';
import 'package:acre_labs/table_grid/controller_impl.dart';
import 'package:acre_labs/table_grid/models.dart';
import 'package:acre_labs/table_grid/table_span_manager.dart';
import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

base mixin TableCoordinator {
  void notifyRebuild();

  void adaptReordering({
    required int from,
    required int to,
    required bool forColumn,
  });

  void adaptRemoval({
    Map<int, int>? newRowIndices,
    Map<int, int>? newColumnIndices,
  });

  bool isColumnHeader(int vicinityRow);
}

base mixin TableCoordinatorMixin {
  TableCoordinator? _coordinator;

  @protected
  TableCoordinator get coordinator {
    assert(
      _coordinator != null,
      "TableCoordinator is not set. Please set it before using.",
    );
    return _coordinator!;
  }

  void bindCoordinator(TableCoordinator coordinator) {
    _coordinator = coordinator;
  }

  @mustCallSuper
  void dispose() {
    _coordinator = null;
  }
}

abstract base class TableController {
  TableController();

  factory TableController.impl({
    required List<ColumnId> columns,
    required DefaultTableSpanManager spanManager,
    List initialRows = const [],
    bool alwaysShowHeader = true,
    bool? addPlaceholderRow,
    List<TableSelectionStrategy> selectionStrategies = const [
      TableSelectionStrategy.row
    ],
    List<TableHoveringStrategy> hoveringStrategies = const [
      TableHoveringStrategy.row
    ],
  }) =>
      TableControllerImpl(
        columns: columns,
        spanManager: spanManager,
        initialRows: initialRows,
        alwaysShowHeader: alwaysShowHeader,
        addPlaceholderRow: addPlaceholderRow,
        selectionStrategies: selectionStrategies,
        hoveringStrategies: hoveringStrategies,
      );

  void updateStrategies({
    List<TableSelectionStrategy>? selectionStrategies,
    List<TableHoveringStrategy>? hoveringStrategies,
  });

  void select({
    List<int>? rows,
    List<int>? columns,
    List<CellIndex>? cells,
  });
  void unselect({List<int>? rows, List<int>? columns, List<CellIndex>? cells});

  void hoverOn({int? row, int? column});
  void hoverOff({int? row, int? column});

  bool isCellSelected(int row, int column);
  bool isCellHovered(int row, int column);

  int get columnCount;
  int get pinnedColumnCount;
  void reorderColumn(ColumnId id, int to);
  void addColumn(ColumnId column, {bool pinned = false});
  void removeColumn(ColumnId id);
  void pinColumn(ColumnId id);
  void unpinColumn(ColumnId id);
  bool isColumnHeader(int vicinityRow);

  int get rowCount;
  int get pinnedRowCount;
  int get dataCount;
  bool get hasPlaceholderRow;

  void addRows(
    List rows, {
    bool skipDuplicates = false,
    bool removePlaceholder = true,
  });
  void removeRows(
    List<int> rows, {
    bool showPlaceholder = false,
  });
  void reorderRow(int fromDataIndex, int toDataIndex);
  void pinRow(int dataIndex);
  void unpinRow(int dataIndex);

  void toggleHeaderVisibility(bool alwaysShowHeader);
  void togglePlaceholder(bool show);

  Listenable get listenable;
  List<ColumnId> get orderedColumns;

  TableSpan buildRowSpan(int index);
  TableSpan buildColumnSpan(int index);

  T getCellDetail<T extends CellDetail>(TableVicinity vicinity);
  Listenable? getCellActionNotifier(TableVicinity vicinity);
  CellIndex getCellIndex(TableVicinity vicinity);
  bool isPlaceholderRow(TableVicinity vicinity);

  int toVicinityRow(int row);

  void dispose();
}

// todo: data source exporter xlsx/pdf
// todo: column span drag
// todo: row span drag
