import 'package:acre_labs/dynamic_custom_form/core.dart';
import 'package:acre_labs/dynamic_custom_form/json_field.dart';
import 'package:acre_labs/dynamic_custom_form/utils.dart';
import 'package:acre_labs/dynamic_custom_form/widgets/multi_dropdown_widget.dart';
import 'package:flutter/material.dart';

class DropdownButtonFormFieldWidget extends StatelessWidget {
  static const name = 'DropdownButtonFormFieldWidget';

  final JsonField jsonField;
  final UIAction? action;
  final bool readonly;

  const DropdownButtonFormFieldWidget({
    super.key,
    required this.jsonField,
    this.action,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMultiSelect = jsonField.uiConfig?["isMultiSelect"] == true;

    return !isMultiSelect
        ? SingleDropdownButtonFormFieldWidget(
            jsonField: jsonField,
            action: action,
            readonly: readonly,
          )
        : MultiSelectDropdownWidget(
            jsonField: jsonField,
            action: action,
            readonly: readonly,
          );
  }
}

class SingleDropdownButtonFormFieldWidget extends StatefulWidget {
  static const name = 'DropdownButtonFormField';

  final JsonField jsonField;
  final UIAction? action;

  final bool readonly;

  const SingleDropdownButtonFormFieldWidget({
    super.key,
    required this.jsonField,
    this.action,
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
    _updateItems();
  }

  @override
  void didUpdateWidget(
      covariant SingleDropdownButtonFormFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateItems();
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

  void _updateItems() {
    _items.clear();

    final items =
        widget.jsonField["items"] as List<Map<String, dynamic>>? ?? [];

    _selected = null;

    for (final item in items) {
      if (widget.action?.data != null &&
          widget.action?.data["key"] == item["key"]) {
        _selected = item;
      }

      final child = CFWidgetBuilder.buildJsonWidget(context, item["child"]);
      _items.add(
        DropdownMenuItem(
          value: item,
          child: child,
        ),
      );
    }

    String? selectedActionKey = _selected?["key"];

    selectedActionKey ??= _selected != null
        ? UIAction.notNullTriggerKey
        : UIAction.nullTriggerKey;

    context.reportActions(
      widget.jsonField.actions?[selectedActionKey] ?? {},
    );

    context.reportValueChange(widget.jsonField.label, _selected);
  }

  void _report(Map<String, dynamic> item) {
    final actionKeys = <String>[
      item["key"],
      UIAction.notNullTriggerKey,
    ];

    for (final actionKey in actionKeys) {
      context.reportActions(widget.jsonField.actions?[actionKey] ?? {});
    }

    context.reportValueChange(widget.jsonField.label, item);
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
