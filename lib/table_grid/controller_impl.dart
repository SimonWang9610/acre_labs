import 'package:acre_labs/table_grid/action_manager.dart';
import 'package:acre_labs/table_grid/cell_detail.dart';
import 'package:acre_labs/table_grid/data_source.dart';
import 'package:acre_labs/table_grid/models.dart';
import 'package:acre_labs/table_grid/span.dart';
import 'package:acre_labs/table_grid/table_column_manager.dart';
import 'package:acre_labs/table_grid/table_span_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'controller.dart';

final class TableControllerImpl extends TableController
    with
        // ChangeNotifier,
        TableCoordinator,
        TableActionImplMixin,
        TableColumnImplMixin,
        TableDataSourceImplMixin {
  TableControllerImpl({
    required List<ColumnId> columns,
    required TableExtentManager extentManager,
    List initialRows = const [],
    bool alwaysShowHeader = true,
    List<TableSelectionStrategy> selectionStrategies = const [
      TableSelectionStrategy.row
    ],
    List<TableHoveringStrategy> hoveringStrategies = const [
      TableHoveringStrategy.row
    ],
  }) : _extentManager = extentManager {
    _actionManager = ActionManager(
      hoveringStrategies: hoveringStrategies,
      selectionStrategies: selectionStrategies,
    )..bindCoordinator(this);

    _dataSource = TableDataSource(
      rows: initialRows,
      alwaysShowHeader: alwaysShowHeader,
    )..bindCoordinator(this);

    _columnManager = TableColumnManager()
      ..bindCoordinator(this)
      ..setColumns(columns);

    _extentManager.bindCoordinator(this);
  }

  @override
  late final ActionManager _actionManager;

  @override
  late final TableDataSource _dataSource;

  @override
  late final TableColumnManager _columnManager;

  TableExtentManager _extentManager;

  set extentManager(TableExtentManager value) {
    if (_extentManager == value) return;
    _extentManager.dispose();
    _extentManager = value;
    _extentManager.bindCoordinator(this);
    notifyRebuild();
  }

  @override
  void notifyRebuild() {
    notifyListeners();
  }

  @override
  void adaptReordering({
    required int from,
    required int to,
    required bool forColumn,
  }) {
    _actionManager.adapt(
      from,
      to,
      forColumn: forColumn,
    );
  }

  @override
  void adaptRemoval({
    Map<int, int>? newRowIndices,
    Map<int, int>? newColumnIndices,
  }) {
    _actionManager.replace(
      newRowIndices: newRowIndices,
      newColumnIndices: newColumnIndices,
    );
  }

  @override
  void dispose() {
    _extentManager.dispose();
    _dataSource.dispose();
    _columnManager.dispose();
    _actionManager.dispose();
    super.dispose();
  }

  @override
  bool isColumnHeader(int vicinityRow) {
    return _dataSource.alwaysShowHeader ? vicinityRow == 0 : false;
  }

  @override
  T getCellDetail<T extends CellDetail>(TableVicinity vicinity) {
    final selected =
        _actionManager.isCellSelected(vicinity.row, vicinity.column);
    final hovering =
        _actionManager.isCellHovering(vicinity.row, vicinity.column);

    final columnId = orderedColumns[vicinity.column];
    final isPinned = vicinity.column < pinnedColumnCount;

    if (isColumnHeader(vicinity.row)) {
      return ColumnHeaderDetail(
        columnId: columnId,
        column: vicinity.column,
        isPinned: isPinned,
        selected: selected,
        hovering: hovering,
      ) as T;
    }

    final cellIndex = getCellIndex(vicinity);

    return TableCellDetail(
      columnId: columnId,
      index: cellIndex,
      isPinned: isPinned,
      selected: selected,
      hovering: hovering,
      rowData: _dataSource[cellIndex.row],
    ) as T;
  }

  @override
  CellIndex getCellIndex(TableVicinity vicinity) {
    final row = _dataSource.toCellRow(vicinity.row);

    assert(
      row >= 0 && row < dataCount,
      "Row index $row must be greater than or equal to 0",
    );

    assert(
      vicinity.column >= 0 && vicinity.column < columnCount,
      "Column index ${vicinity.column} must be greater than or equal to 0",
    );

    return CellIndex(row, vicinity.column);
  }

  @override
  int toVicinityRow(int row) {
    return _dataSource.toVicinityRow(row);
  }

  @override
  TableSpan buildColumnSpan(int index, TableGridBorder border) {
    final columnId = orderedColumns[index];
    final extent = _extentManager.getColumnExtent(columnId);
    return border.build(
      axis: Axis.vertical,
      extent: extent,
      last: index == columnCount - 1,
    );
  }

  @override
  TableSpan buildRowSpan(int index, TableGridBorder border) {
    final extent = _extentManager.getRowExtent(index);
    return border.build(
      axis: Axis.horizontal,
      extent: extent,
      last: index == rowCount - 1,
    );
  }
}

base mixin TableDataSourceImplMixin on TableController {
  TableDataSource get _dataSource;

  @override
  void addRows(
    List rows, {
    bool skipDuplicates = false,
    bool removePlaceholder = true,
  }) {
    _dataSource.add(
      rows,
      skipDuplicates: skipDuplicates,
    );
  }

  @override
  void removeRows(
    List<int> rows, {
    bool showPlaceholder = false,
  }) {
    _dataSource.remove(
      rows
          .map(
            (r) => toVicinityRow(r),
          )
          .toList(),
    );
  }

  @override
  void reorderRow(int fromDataIndex, int toDataIndex) {
    _dataSource.reorder(
      toVicinityRow(fromDataIndex),
      toVicinityRow(toDataIndex),
    );
  }

  @override
  void pinRow(int dataIndex) {
    _dataSource.pin(
      toVicinityRow(dataIndex),
    );
  }

  @override
  void unpinRow(int dataIndex) {
    _dataSource.unpin(
      toVicinityRow(dataIndex),
    );
  }

  @override
  void toggleHeaderVisibility(bool alwaysShowHeader) {
    _dataSource.alwaysShowHeader = alwaysShowHeader;
  }

  @override
  int get rowCount => _dataSource.rowCount;

  @override
  int get pinnedRowCount => _dataSource.pinnedRowCount;

  @override
  int get dataCount => _dataSource.dataCount;
}

base mixin TableColumnImplMixin on TableController {
  TableColumnManager get _columnManager;

  @override
  void addColumn(ColumnId column, {bool pinned = false}) {
    _columnManager.add(column, pinned: pinned);
  }

  @override
  void removeColumn(ColumnId id) {
    _columnManager.remove(id);
  }

  @override
  void pinColumn(ColumnId id) {
    _columnManager.pin(id);
  }

  @override
  void unpinColumn(ColumnId id) {
    _columnManager.unpin(id);
  }

  @override
  void reorderColumn(ColumnId id, int to) {
    _columnManager.reorder(id, to);
  }

  @override
  int get columnCount => _columnManager.columnCount;

  @override
  int get pinnedColumnCount => _columnManager.pinnedColumnCount;

  @override
  List<ColumnId> get orderedColumns => _columnManager.orderedColumns;
}

base mixin TableActionImplMixin on TableController, TableCoordinator {
  ActionManager get _actionManager;

  @override
  void updateStrategies({
    List<TableSelectionStrategy>? selectionStrategies,
    List<TableHoveringStrategy>? hoveringStrategies,
  }) {
    bool shouldNotify = false;

    if (selectionStrategies != null) {
      shouldNotify |=
          _actionManager.updateSelectionStrategy(selectionStrategies);
    }

    if (hoveringStrategies != null) {
      shouldNotify |= _actionManager.updateHoveringStrategy(hoveringStrategies);
    }

    if (shouldNotify) {
      notifyRebuild();
    }
  }

  @override
  void select({
    List<int>? rows,
    List<int>? columns,
    List<CellIndex>? cells,
  }) {
    final vicinityRows = rows?.map((row) => toVicinityRow(row));
    final vicinityColumns = columns?.map((column) => column);
    final vicinityCells = cells?.map(
      (cell) => CellIndex(
        toVicinityRow(cell.row),
        cell.column,
      ),
    );

    assert(
      () {
        if (vicinityRows != null) {
          return vicinityRows.every((r) => r < rowCount);
        }

        if (vicinityColumns != null) {
          return vicinityColumns.every((c) => c < columnCount);
        }

        if (vicinityCells != null) {
          return vicinityCells
              .every((c) => c.row < rowCount && c.column < columnCount);
        }

        return true;
      }(),
      "Provided row/column/cell indices are out of range",
    );

    _actionManager.select(
      rows: vicinityRows?.where((row) => row < rowCount),
      columns: vicinityColumns?.where((column) => column < columnCount),
      cells: vicinityCells?.where(
        (cell) => cell.row < rowCount && cell.column < columnCount,
      ),
    );
  }

  @override
  void unselect({
    List<int>? rows,
    List<int>? columns,
    List<CellIndex>? cells,
  }) {
    final vicinityRows = rows?.map((row) => toVicinityRow(row));
    final vicinityColumns = columns?.map((column) => column);
    final vicinityCells = cells?.map(
      (cell) => CellIndex(
        toVicinityRow(cell.row),
        cell.column,
      ),
    );
    _actionManager.unselect(
      rows: vicinityRows?.where((row) => row < rowCount),
      columns: vicinityColumns?.where((column) => column < columnCount),
      cells: vicinityCells?.where(
        (cell) => cell.row < rowCount && cell.column < columnCount,
      ),
    );
  }

  @override
  void hoverOn({int? row, int? column}) {
    _actionManager.hoverOn(
      row: row != null ? toVicinityRow(row) : null,
      column: column,
    );
  }

  @override
  void hoverOff({int? row, int? column}) {
    _actionManager.hoverOff(
      row: row != null ? toVicinityRow(row) : null,
      column: column,
    );
  }

  @override
  bool isCellSelected(int row, int column) {
    return _actionManager.isCellSelected(
      toVicinityRow(row),
      column,
    );
  }

  @override
  bool isCellHovered(int row, int column) {
    return _actionManager.isCellHovering(
      toVicinityRow(row),
      column,
    );
  }

  @override
  Listenable? getCellActionNotifier(TableVicinity vicinity) {
    return _actionManager.getCellActionNotifier(vicinity.row, vicinity.column);
  }
}
