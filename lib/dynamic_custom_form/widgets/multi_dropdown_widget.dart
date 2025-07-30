import 'package:acre_labs/dynamic_custom_form/core.dart';
import 'package:acre_labs/dynamic_custom_form/json_field.dart';
import 'package:acre_labs/dynamic_custom_form/utils.dart';
import 'package:flutter/material.dart';

class MultiSelectDropdownWidget extends StatefulWidget {
  static const name = 'MultiSelectDropdownWidget';

  final JsonField jsonField;
  final UIAction? action;
  final bool readonly;

  const MultiSelectDropdownWidget({
    super.key,
    required this.jsonField,
    this.action,
    this.readonly = false,
  });

  @override
  State<MultiSelectDropdownWidget> createState() =>
      _MultiSelectDropdownWidgetState();
}

class _MultiSelectDropdownWidgetState extends State<MultiSelectDropdownWidget> {
  final List<Map<String, dynamic>> _selected = [];
  final List<DropdownMenuItem> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateItems();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant MultiSelectDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateItems();
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

        context.reportValueChange(
          widget.jsonField.label,
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

  void _updateItems() {
    _selected.clear();
    _items.clear();

    final items = widget.jsonField["items"] as List<Map<String, dynamic>>?;
    final actionSelectedKeys =
        (widget.action?.data as List<dynamic>?)?.map((e) => e["key"]).toSet() ??
            {};

    for (final item in items ?? []) {
      if (actionSelectedKeys.contains(item["key"])) {
        _selected.add(item);
      }
      final child = CFWidgetBuilder.buildJsonWidget(context, item["child"]);
      _items.add(
        DropdownMenuItem(
          value: item,
          child: child,
        ),
      );
    }

    context.reportValueChange(widget.jsonField.label, _selected);

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
                ? CFWidgetBuilder.buildJsonWidget(context, item["child"])
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
