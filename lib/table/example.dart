import 'package:acre_labs/table_grid/cell_detail.dart';
import 'package:acre_labs/table_grid/controller.dart';
import 'package:acre_labs/table_grid/models.dart';
import 'package:acre_labs/table_grid/span.dart';
import 'package:acre_labs/table_grid/table_span_manager.dart';
import 'package:acre_labs/table_grid/widget.dart';
import 'package:flutter/material.dart';

class TableExample extends StatefulWidget {
  const TableExample({super.key});

  @override
  State<TableExample> createState() => _TableExampleState();
}

class _TableExampleState extends State<TableExample> {
  final _extentManager = TableExtentManager(
    defaultRowExtent: TableExtent.fixed(50),
    defaultColumnExtent: TableExtent.fixed(100),
  );

  late final TableController controller = TableController.impl(
    columns: List.generate(8, (index) => "C($index)"),
    extentManager: _extentManager,
    hoveringStrategies: [
      TableHoveringStrategy.row,
    ],
  );

  @override
  void dispose() {
    _extentManager.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Table Grid Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableGrid(
          controller: controller,
          cellBuilder: _buildCell,
          columnBuilder: _buildColumn,
          border: TableGridBorder(
            vertical: BorderSide(
              color: Colors.red,
              width: 2,
            ),
            horizontal: BorderSide(
              color: Colors.black,
              width: 2,
            ),
          ),
          loadingBuilder: (ctx) {
            return CircularProgressIndicator(
              color: Colors.red,
            );
          },
        ),
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            _addRows(1);
          },
        ),
        TextButton(
          onPressed: () {
            controller.removeRows(
              [0],
            );
          },
          child: Text("Remove first row"),
        ),
        TextButton(
          onPressed: () {
            controller.removeColumn(
              controller.orderedColumns.first,
            );
          },
          child: Text("Remove first column"),
        ),
      ],
    );
  }

  Widget _buildColumn(BuildContext ctx, ColumnHeaderDetail detail) {
    return InkWell(
      onTap: () {
        if (detail.isPinned) {
          controller.unpinColumn(detail.columnId);
        } else {
          controller.pinColumn(detail.columnId);
        }
      },
      child: Container(
        color: detail.isPinned ? Colors.blue : Colors.yellow,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              detail.columnId,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              detail.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext ctx, TableCellDetail detail) {
    final rowData = detail.rowData;

    final name =
        rowData is Map ? rowData[detail.columnId] : detail.rowData.toString();

    return InkWell(
      onTap: () {
        print('Tapped: #$detail');
        if (!detail.selected) {
          controller.select(rows: [detail.index.row]);
        } else {
          controller.unselect(rows: [detail.index.row]);
        }
      },
      child: Container(
        // color: detail.selected ? Colors.green : Colors.white,
        decoration: BoxDecoration(
          color: detail.selected ? Colors.green : Colors.blue,
          border: detail.selected
              ? Border.all(
                  color: Colors.yellow,
                  width: 2,
                )
              : null,
        ),
        child: Center(
          child: Text(
            "$name, ${detail.columnId}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _addRows(int count) {
    final columns = controller.orderedColumns;

    final rows = List.generate(
      count,
      (index) => {
        for (var column in columns)
          column: 'Row ${controller.dataCount + index}',
      },
    );

    controller.addRows(
      rows,
      skipDuplicates: true,
      removePlaceholder: true,
    );
  }
}
