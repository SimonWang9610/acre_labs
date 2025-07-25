import 'package:acre_labs/interactive_custom_form/cf_json_field.dart';
import 'package:acre_labs/interactive_custom_form/field_command.dart';
import 'package:acre_labs/interactive_custom_form/field_widget.dart';
import 'package:flutter/material.dart';

class DropdownButtonFormFieldWidget extends StatefulWidget {
  static const name = 'DropdownButtonFormField';

  final CFJsonField jsonField;
  final CFFieldAction? action;
  final Widget? readonlyIndicator;

  const DropdownButtonFormFieldWidget({
    super.key,
    required this.jsonField,
    this.action,
    this.readonlyIndicator,
  });

  @override
  State<DropdownButtonFormFieldWidget> createState() =>
      _DropdownButtonFormFieldState();
}

class _DropdownButtonFormFieldState
    extends State<DropdownButtonFormFieldWidget> {
  Map<String, dynamic>? _selected;
  final List<DropdownMenuItem> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateItems();

    if (_selected != null) {
      _report(_selected!);
    }
  }

  @override
  void didUpdateWidget(covariant DropdownButtonFormFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    _updateItems();

    if (widget.action?.value != null) {
      for (final item in _items) {
        if (widget.action?.value == item.value["key"]) {
          _selected = item.value;
          _report(_selected!);
          break;
        }
      }
    }
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
              if (widget.readonlyIndicator != null) widget.readonlyIndicator!,
            ],
          ),
          widget.jsonField.wrapWidget(dropdown),
        ],
      ),
    );
  }

  void _updateItems() {
    _items.clear();

    final items =
        widget.jsonField.fieldJson["items"] as List<Map<String, dynamic>>?;

    _selected = null;

    for (final item in items ?? []) {
      if (item["selected"] == true) {
        _selected = item;
      }

      final child = CFFormConverter.wrapWidget(item["child"], null);
      _items.add(
        DropdownMenuItem(
          value: item,
          child: child,
        ),
      );
    }

    if (_selected != null) {
      context.reportValueChange(
        widget.jsonField.label,
        {
          "key": _selected!["key"],
          "value": _selected!["value"],
        },
      );
    }
  }

  void _report(Map<String, dynamic> item) {
    context.reportItemActions(item);
    context.reportValueChange(
      widget.jsonField.label,
      {
        "key": item["key"],
        "value": item["value"],
      },
    );
  }
}

class CheckboxWidget extends StatefulWidget {
  static const name = 'CheckboxWidget';

  final CFJsonField jsonField;
  final CFFieldAction? action;
  final Widget? readonlyIndicator;

  const CheckboxWidget({
    super.key,
    required this.jsonField,
    this.action,
    this.readonlyIndicator,
  });

  @override
  State<CheckboxWidget> createState() => _CheckboxWidgetState();
}

class _CheckboxWidgetState extends State<CheckboxWidget> {
  late bool _isChecked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initialValue = widget.jsonField.fieldJson["initialValue"] as String?;
    _isChecked = initialValue == "checked";

    context.reportValueChange(
      widget.jsonField.label,
      _isChecked ? "checked" : "unchecked",
    );
  }

  @override
  void didUpdateWidget(covariant CheckboxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.action?.value != null) {
      _isChecked = (widget.action?.value as String?) == "checked";
      context.reportValueChange(
        widget.jsonField.label,
        _isChecked ? "checked" : "unchecked",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget checkbox = Checkbox(
      value: _isChecked,
      onChanged: (value) {
        if (value == null) return;

        _isChecked = value;

        final actionsMap = value
            ? widget.jsonField.fieldJson["checked"]
            : widget.jsonField.fieldJson["unchecked"];
        _report(actionsMap);

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
              if (widget.readonlyIndicator != null) widget.readonlyIndicator!,
            ],
          ),
          widget.jsonField.wrapWidget(checkbox),
        ],
      ),
    );
  }

  void _report(Map<String, dynamic> item) {
    context.reportItemActions(item);
    context.reportValueChange(
      widget.jsonField.label,
      _isChecked ? "checked" : "unchecked",
    );
  }
}

class MultiSelectDropdownWidget extends StatefulWidget {
  static const name = 'MultiSelectDropdownWidget';

  final CFJsonField jsonField;
  final CFFieldAction? action;
  final Widget? readonlyIndicator;

  const MultiSelectDropdownWidget({
    super.key,
    required this.jsonField,
    this.action,
    this.readonlyIndicator,
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
    _updateActionSelected();
  }

  @override
  void didUpdateWidget(covariant MultiSelectDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateItems();
    _updateActionSelected();
  }

  @override
  Widget build(BuildContext context) {
    Widget dropdown = DropdownButtonFormField(
      items: _items,
      onChanged: (value) {
        if (value == null) return;

        final isSelected = _selected.any(
          (item) => item["value"] == value["value"],
        );

        if (isSelected) {
          _selected.removeWhere(
            (item) => item["value"] == value["value"],
          );
        } else {
          _selected.add(value);
        }

        context.reportItemActions(value);

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
              if (widget.readonlyIndicator != null) widget.readonlyIndicator!,
            ],
          ),
          widget.jsonField.wrapWidget(dropdown),
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

    final items =
        widget.jsonField.fieldJson["items"] as List<Map<String, dynamic>>?;

    for (final item in items ?? []) {
      if (item["selected"] == true) {
        _selected.add(item);
      }

      final child = CFFormConverter.wrapWidget(item["child"], null);
      _items.add(
        DropdownMenuItem(
          value: item,
          child: child,
        ),
      );
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
  }

  void _updateActionSelected() {
    if (widget.action?.value == null) return;

    final actionSelectedKeys = widget.action!.value as List<String>;

    _selected.clear();

    for (final item in _items) {
      if (actionSelectedKeys.contains(item.value["key"])) {
        _selected.add(item.value);
      }
    }

    context.reportValueChange(
        widget.jsonField.label,
        _selected
            .map(
              (e) => {
                "key": e["key"],
                "value": e["value"],
              },
            )
            .toList());

    for (final item in _selected) {
      context.reportItemActions(item);
    }
  }
}

class CronSchedulePickerWidget extends StatefulWidget {
  static const name = 'CronSchedulePickerWidget';

  final CFJsonField jsonField;
  final CFFieldAction? action;
  final Widget? readonlyIndicator;
  const CronSchedulePickerWidget({
    super.key,
    required this.jsonField,
    this.action,
    this.readonlyIndicator,
  });

  @override
  State<CronSchedulePickerWidget> createState() =>
      _CronSchedulePickerWidgetState();
}

class _CronSchedulePickerWidgetState extends State<CronSchedulePickerWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
