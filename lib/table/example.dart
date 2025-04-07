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
  final _spanManager = DefaultTableSpanManager(
    defaultRowSpan: CellSpan.fixed(
      pixels: 50,
      decoration: CellSpanDecoration(
        trailing: BorderSide(
          color: Colors.black,
          width: 2,
        ),
      ),
    ),
    defaultColumnSpan: CellSpan.fixed(
      pixels: 150,
      decoration: CellSpanDecoration(
        leading: BorderSide(
          color: Colors.black,
          width: 2,
        ),
      ),
    ),
  );

  late final TableController controller = TableController.impl(
    addPlaceholderRow: true,
    columns: List.generate(6, (index) => "C($index)"),
    spanManager: _spanManager,
    hoveringStrategies: [
      TableHoveringStrategy.row,
    ],
  );

  @override
  void dispose() {
    _spanManager.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Table Grid Example'),
      ),
      body: TableGrid(
        controller: controller,
        cellBuilder: _buildCell,
        columnBuilder: _buildColumn,
        placeholderBuilder: (ctx) {
          return const Center(
            child: Text(
              'No data available',
              style: TextStyle(fontSize: 16),
            ),
          );
        },
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            _addRows(5);
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
        color: detail.isPinned ? Colors.blue : Colors.grey,
        margin: const EdgeInsets.all(10),
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
        color: detail.selected ? Colors.green : Colors.white,
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
