import 'dart:async';

import 'package:acre_labs/dynamic_custom_form/core/extensions.dart';
import 'package:acre_labs/dynamic_custom_form/core/json_field.dart';
import 'package:acre_labs/dynamic_custom_form/core/utils.dart';
import 'package:flutter/material.dart';

class DynamicMultiSelectDropdownWidget extends StatefulWidget {
  static const name = 'DynamicMultiSelectDropdownWidget';

  final JsonField jsonField;
  final bool readonly;

  const DynamicMultiSelectDropdownWidget({
    super.key,
    required this.jsonField,
    this.readonly = false,
  });

  @override
  State<DynamicMultiSelectDropdownWidget> createState() =>
      _DynamicMultiSelectDropdownWidgetState();
}

class _DynamicMultiSelectDropdownWidgetState
    extends State<DynamicMultiSelectDropdownWidget> {
  final List<Map<String, dynamic>> _selected = [];
  final List<DropdownMenuItem> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _updateItems(widget.jsonField.initialData);

    context.subscribeDataAction(
      widget.jsonField,
      onData: (val) {
        _updateItems(val);
        if (mounted) setState(() {});
      },
    );

    _loadIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    Widget dropdown = DropdownButtonFormField(
      value: _selected.isNotEmpty ? _selected.last : null,
      items: _items,
      onChanged: (value) {
        if (value == null) return;

        final isSelected = _selected.any(
          (item) => item["key"] == value["key"],
        );

        if (isSelected) {
          _selected.removeWhere(
            (item) => item["key"] == value["key"],
          );
        } else {
          _selected.add(value);
        }

        final actionKeys = <String>[value["key"]];

        if (_selected.isEmpty) {
          actionKeys.add(UIAction.emptyTrigger);
        } else {
          actionKeys.add(UIAction.notEmptyTrigger);
        }

        for (final actionKey in actionKeys) {
          final actions = widget.jsonField.actions?[actionKey];
          context.reportActions(actions ?? {});
        }

        context.reportFieldChange(
          widget.jsonField,
          _selected
              .map((e) => {
                    "key": e["key"],
                    "value": e["value"],
                  })
              .toList(),
        );

        setState(() {});
      },
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.all(5),
      child: Column(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.jsonField.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (widget.readonly)
                Tooltip(
                  message: 'This field is read-only',
                  child: const Icon(
                    Icons.do_not_disturb_alt_rounded,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          dropdown,
          Text(
            'Selected: ${_selected.map((e) => e["key"]).join(", ")}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _updateItems(dynamic value) {
    _selected.clear();
    _items.clear();

    final items = widget.jsonField["items"] as List<Map<String, dynamic>>?;
    final actionSelectedKeys =
        (value as List<dynamic>?)?.map((e) => e["key"]).toSet() ?? {};

    for (final item in items ?? []) {
      if (actionSelectedKeys.contains(item["key"])) {
        _selected.add(item);
      }

      _items.add(
        DropdownMenuItem(
          value: item,
          child: DynamicWidgetBuilder.buildJsonWidget(
            context,
            item["child"],
          ),
        ),
      );
    }

    context.reportFieldChange(
      widget.jsonField,
      _selected
          .map((e) => {
                "key": e["key"],
                "value": e["value"],
              })
          .toList(),
    );

    final actionKeys = _selected.map((e) => e["key"]).toList();

    if (_selected.isEmpty) {
      actionKeys.add(UIAction.emptyTrigger);
    } else {
      actionKeys.add(UIAction.notEmptyTrigger);
    }

    for (final actionKey in actionKeys) {
      final actions = widget.jsonField.actions?[actionKey];
      context.reportActions(actions ?? {});
    }
  }

  Future<List<Map<String, dynamic>>> _mockFetch() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final dropdownType = widget.jsonField["dropdownType"];

    return [
      {
        "key": "Item 1",
        "child": {"type": "Text", "data": "$dropdownType Item 1"}
      },
      {
        "key": "Item 2",
        "child": {"type": "Text", "data": "$dropdownType Item 2"}
      },
      {
        "key": "Item 3",
        "child": {"type": "Text", "data": "$dropdownType Item 3"}
      },
      {
        "key": "Item 4",
        "child": {"type": "Text", "data": "$dropdownType Item 4"}
      },
      {
        "key": "Item 5",
        "child": {"type": "Text", "data": "$dropdownType Item 5"}
      },
    ];
  }

  Future<void> _loadIfNeeded() async {
    final dropdownType = widget.jsonField["dropdownType"];

    if (dropdownType == null) return;

    try {
      final loaded = await _mockFetch();
      if (!mounted) return;

      _items.addAll(
        loaded.map(
          (item) => DropdownMenuItem(
            value: item,
            child: item["child"] != null
                ? DynamicWidgetBuilder.buildJsonWidget(context, item["child"])
                : Text(item["key"] ?? "<Unknown Item>"),
          ),
        ),
      );

      setState(() {});
    } catch (e) {
      debugPrint(
        'Failed to load items for $dropdownType: $e',
      );
    }
  }
}
