import 'dart:async';

import 'package:acre_labs/dynamic_custom_form/core/extensions.dart';
import 'package:acre_labs/dynamic_custom_form/core/json_field.dart';
import 'package:acre_labs/dynamic_custom_form/core/utils.dart';
import 'package:acre_labs/dynamic_custom_form/widgets/multi_dropdown_widget.dart';
import 'package:flutter/material.dart';

class DropdownButtonFormFieldWidget extends StatelessWidget {
  static const name = 'DropdownButtonFormFieldWidget';

  static bool isTypeMatched(String type) {
    return type == 'DropdownButtonFormFieldWidget' || type == 'DropdownButton';
  }

  final JsonField jsonField;

  final bool readonly;

  const DropdownButtonFormFieldWidget({
    super.key,
    required this.jsonField,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMultiSelect = jsonField.uiConfig?["isMultiSelect"] == true;

    return !isMultiSelect
        ? SingleDropdownButtonFormFieldWidget(
            jsonField: jsonField,
            readonly: readonly,
          )
        : DynamicMultiSelectDropdownWidget(
            jsonField: jsonField,
            readonly: readonly,
          );
  }
}

class SingleDropdownButtonFormFieldWidget extends StatefulWidget {
  static const name = 'DropdownButtonFormField';

  final JsonField jsonField;

  final bool readonly;

  const SingleDropdownButtonFormFieldWidget({
    super.key,
    required this.jsonField,
    this.readonly = false,
  });

  @override
  State<SingleDropdownButtonFormFieldWidget> createState() =>
      _DropdownButtonFormFieldState();
}

class _DropdownButtonFormFieldState
    extends State<SingleDropdownButtonFormFieldWidget> {
  late final _loading = ValueNotifier<bool>(false);

  Map<String, dynamic>? _selected;
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
  void dispose() {
    _loading.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget dropdown = DropdownButtonFormField(
      value: _selected,
      items: _items,
      onChanged: (value) {
        _selected = value;
        _report(value!);
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
        ],
      ),
    );
  }

  void _updateItems(dynamic value) {
    _items.clear();

    final items =
        widget.jsonField["items"] as List<Map<String, dynamic>>? ?? [];

    _selected = null;

    for (final item in items) {
      if (value != null && value["key"] == item["key"]) {
        _selected = item;
      }

      final child =
          DynamicWidgetBuilder.buildJsonWidget(context, item["child"]);
      _items.add(
        DropdownMenuItem(
          value: item,
          child: child,
        ),
      );
    }

    final actionKeys = <String>[];

    if (_selected != null) {
      actionKeys.add(_selected!["key"]);
      actionKeys.add(UIAction.notNullTrigger);
    } else {
      actionKeys.add(UIAction.nullTrigger);
    }

    for (final actionKey in actionKeys) {
      context.reportActions(widget.jsonField.actions?[actionKey] ?? {});
    }

    context.reportFieldChange(widget.jsonField, _selected);
  }

  void _report(Map<String, dynamic> item) {
    final actionKeys = <String>[
      item["key"],
      UIAction.notNullTrigger,
    ];

    for (final actionKey in actionKeys) {
      context.reportActions(widget.jsonField.actions?[actionKey] ?? {});
    }

    context.reportFieldChange(widget.jsonField, item);
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
