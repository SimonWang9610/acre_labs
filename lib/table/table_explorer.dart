// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// The class demonstrating an infinite number of rows and columns in
/// TableView.
class InfiniteTableExample extends StatefulWidget {
  /// Creates a screen that demonstrates an infinite TableView widget.
  const InfiniteTableExample({super.key});

  @override
  State<InfiniteTableExample> createState() => _InfiniteExampleState();
}

class _InfiniteExampleState extends State<InfiniteTableExample> {
  late final _source = TableDataSource(
    headerCellBuilder: _buildHeaderCell,
    cellBuilder: _buildCell,
  )..addRows(
      List.generate(
        10,
        (r) {
          return List.generate(5, (c) => "$r,$c");
        },
      ),
    );

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _source,
        builder: (_, __) {
          return TableView.builder(
            mainAxis: Axis.horizontal,
            cellBuilder: (_, vicinity) {
              if (vicinity.row == 0) {
                return _source.buildHeaderCell(vicinity.column);
              } else {
                return _source.buildCell(vicinity);
              }
            },
            columnCount: _source.columnCount,
            rowCount: _source.rowCount,
            columnBuilder: _buildColumnSpan,
            rowBuilder: _buildSpan,
            pinnedColumnCount: 1,
            pinnedRowCount: 1,
            diagonalDragBehavior: DiagonalDragBehavior.free,
          );
        },
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: <Widget>[
        FilledButton(
          onPressed: () {
            _source.addRows(List.generate(
              10,
              (r) {
                return List.generate(5, (c) => "$r,$c");
              },
            ));
          },
          child: Text(
            'add 10 rows',
          ),
        ),
        FilledButton(
          onPressed: () {},
          child: Text(
            'add 2 columns',
          ),
        ),
        ListenableBuilder(
          listenable: _source,
          builder: (_, __) {
            return Text(
                "Total ${_source.rowCount} x ${_source.columnCount} cells");
          },
        )
      ],
    );
  }

  Widget _buildCell(BuildContext context, dynamic data, bool selected) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Text('Cell $data'),
      ),
    );
  }

  Widget _buildHeaderCell(
      BuildContext context, int index, _CellSelection? selection) {
    final selected = selection?.column == index && selection?.row == null;

    return Center(
      child: Text('Header $index'),
    );
  }

  TableSpan? _buildSpan(int index) {
    return TableSpan(
      extent: MaxSpanExtent(
        FixedTableSpanExtent(0),
        FixedTableSpanExtent(200),
      ),
      backgroundDecoration: SpanDecoration(
        border: SpanBorder(
          leading: BorderSide(
            width: 1.0,
          ),
        ),
      ),
    );
  }

  late _DynamicSpaceDecoration _columnDecoration = _DynamicSpaceDecoration(
    afterPaint: _updateRect,
    border: SpanBorder(
      trailing: BorderSide(
        color: Colors.black,
        width: 1.0,
      ),
    ),
  );

  void _updateRect(Rect r) {
    print(' rect: $r');
  }

  TableSpan _buildColumnSpan(int index) {
    final width = 100.0 * ((index % 3) + 1);
    return TableSpan(
      extent: FixedTableSpanExtent(width),
      backgroundDecoration: _columnDecoration,
    );
  }
}

typedef TableCellBuilder = Widget Function(
  BuildContext context,
  dynamic data,
  bool selected,
);

typedef TableHeaderCellBuilder = Widget Function(
  BuildContext context,
  int index,
  _CellSelection? selected,
);

class TableDataSource extends ChangeNotifier {
  TableDataSource({
    required TableHeaderCellBuilder headerCellBuilder,
    required TableCellBuilder cellBuilder,
    List<List>? data,
  })  : _data = data ?? [],
        _cellBuilder = cellBuilder,
        _headerCellBuilder = headerCellBuilder {
    _debugCheckColumnCount(_data);
  }

  TableHeaderCellBuilder _headerCellBuilder;
  TableCellBuilder _cellBuilder;

  set headerCellBuilder(TableHeaderCellBuilder value) {
    _headerCellBuilder = value;
    notifyListeners();
  }

  set cellBuilder(TableCellBuilder value) {
    _cellBuilder = value;
    notifyListeners();
  }

  int get rowCount => _data.length;
  int get columnCount => _data.isEmpty ? 0 : _data[0].length;

  final List<List> _data;

  void addRows(List<List> rows) {
    _debugCheckColumnCount(rows);
    _data.addAll(rows);
    notifyListeners();
  }

  void addColumns(List<List<dynamic>> columns) {
    assert(columns.length == rowCount);
    for (int i = 0; i < rowCount; i++) {
      _data[i].addAll(columns[i]);
    }
    notifyListeners();
  }

  void _debugCheckColumnCount(List<List> rows) {
    assert(() {
      if (rows.isEmpty) return true;

      int columnCount = rows[0].length;

      return rows.every((row) => row.length == columnCount);
    }());
  }

  final ValueNotifier<_CellSelection?> _selected = ValueNotifier(null);

  TableViewCell buildHeaderCell(int index) {
    return TableViewCell(
      child: InkWell(
        onTap: () => _markCellAsSelected(null, index),
        child: ValueListenableBuilder(
          valueListenable: _selected,
          builder: (context, _CellSelection? selected, child) {
            return _headerCellBuilder(context, index, selected);
          },
        ),
      ),
    );
  }

  TableViewCell buildCell(TableVicinity vicinity) {
    assert(vicinity.row > 0);

    return TableViewCell(
      child: InkWell(
        onTap: () => _markCellAsSelected(vicinity.row, vicinity.column),
        child: ValueListenableBuilder(
          valueListenable: _selected,
          builder: (context, _CellSelection? selection, child) {
            print('vicinity: $vicinity');
            final cellData = _data[vicinity.row][vicinity.column];
            final selected = selection?.isSelected(vicinity) ?? false;
            return _cellBuilder(context, cellData, selected);
          },
        ),
      ),
    );
  }

  void _markCellAsSelected(int? row, int? column) {
    if (row == null && column == null) {
      _selected.value = null;
    } else {
      _selected.value =
          _CellSelection(row: row, column: column == 0 ? null : column);
    }
  }

  @override
  void dispose() {
    _selected.dispose();
    super.dispose();
  }
}

class _CellSelection {
  final int? row;
  final int? column;

  const _CellSelection({this.row, this.column});

  bool isSelected(TableVicinity vicinity) {
    if (row == null || column == null) {
      return row == vicinity.row || column == vicinity.column;
    }

    return row == vicinity.row && column == vicinity.column;
  }
}

class _DynamicSpaceDecoration extends SpanDecoration {
  final ValueChanged<Rect>? afterPaint;

  _DynamicSpaceDecoration({
    this.afterPaint,
    super.color,
    super.border,
    super.consumeSpanPadding = true,
  });

  @override
  void paint(SpanDecorationPaintDetails details) {
    super.paint(details);
    afterPaint?.call(details.rect);
  }
}
