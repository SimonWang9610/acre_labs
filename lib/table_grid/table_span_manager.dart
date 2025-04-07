import 'package:acre_labs/table_grid/cell_detail.dart';
import 'package:acre_labs/table_grid/controller.dart';
import 'package:acre_labs/table_grid/span.dart';

final class DefaultTableSpanManager with TableCoordinatorMixin {
  DefaultTableSpanManager({
    required CellSpan defaultRowSpan,
    required CellSpan defaultColumnSpan,
    Map<ColumnId, CellSpan>? columnSpans,
    Map<int, CellSpan>? rowSpans,
  })  : _defaultRowSpan = defaultRowSpan,
        _defaultColumnSpan = defaultColumnSpan {
    if (columnSpans != null) {
      _mutatedColumnSpans.addAll(columnSpans);
    }

    if (rowSpans != null) {
      _mutatedRowSpans.addAll(rowSpans);
    }
  }

  final Map<ColumnId, CellSpan> _mutatedColumnSpans = {};
  final Map<int, CellSpan> _mutatedRowSpans = {};

  CellSpan _defaultRowSpan;

  set defaultRowSpan(CellSpan value) {
    if (_defaultRowSpan == value) return;

    _defaultRowSpan = value;
    coordinator.notifyRebuild();
  }

  CellSpan _defaultColumnSpan;
  set defaultColumnSpan(CellSpan value) {
    if (_defaultColumnSpan == value) return;

    _defaultColumnSpan = value;
    coordinator.notifyRebuild();
  }

  CellSpan getColumnSpan(ColumnId columnId) {
    return _mutatedColumnSpans[columnId] ?? _defaultColumnSpan;
  }

  CellSpan getRowSpan(int rowIndex) {
    return _mutatedRowSpans[rowIndex] ?? _defaultRowSpan;
  }

  void setRowSpan(int index, CellSpan span) {
    if (_mutatedRowSpans[index] == span || _defaultRowSpan == span) return;

    _mutatedRowSpans[index] = span;
    coordinator.notifyRebuild();
  }

  void setColumnSpan(ColumnId columnId, CellSpan span) {
    if (_mutatedColumnSpans[columnId] == span || _defaultColumnSpan == span) {
      return;
    }

    _mutatedColumnSpans[columnId] = span;
    coordinator.notifyRebuild();
  }

  @override
  void dispose() {
    _mutatedColumnSpans.clear();
    _mutatedRowSpans.clear();
    super.dispose();
  }

  DefaultTableSpanManager copyWith({
    CellSpan? defaultRowSpan,
    CellSpan? defaultColumnSpan,
    Map<ColumnId, CellSpan>? columnSpans,
    Map<int, CellSpan>? rowSpans,
    bool rebuildImmediately = true,
  }) {
    final newManager = DefaultTableSpanManager(
      defaultRowSpan: defaultRowSpan ?? _defaultRowSpan,
      defaultColumnSpan: defaultColumnSpan ?? _defaultColumnSpan,
      columnSpans: columnSpans ?? _mutatedColumnSpans,
      rowSpans: rowSpans ?? _mutatedRowSpans,
    )..bindCoordinator(coordinator);

    dispose();

    if (rebuildImmediately) {
      newManager.coordinator.notifyRebuild();
    }

    return newManager;
  }
}
