import 'package:acre_labs/dynamic_custom_form/core/extensions.dart';
import 'package:acre_labs/dynamic_custom_form/core/json_field.dart';

import 'package:flutter/material.dart';

class DynamicCheckboxWidget extends StatefulWidget {
  static const name = 'DynamicCheckboxWidget';

  static bool isTypeMatched(String type) {
    return type == 'CheckboxWidget' || type == 'Checkbox';
  }

  final JsonField jsonField;

  final bool readonly;

  const DynamicCheckboxWidget({
    super.key,
    required this.jsonField,
    this.readonly = false,
  });

  @override
  State<DynamicCheckboxWidget> createState() => _DynamicCheckboxWidgetState();
}

class _DynamicCheckboxWidgetState extends State<DynamicCheckboxWidget> {
  late bool _isChecked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final preAssigned = context.getPreAssignedValue(widget.jsonField);

    if (preAssigned != null) {
      _isChecked = preAssigned.toLowerCase() == 'true';
    } else {
      _isChecked = widget.jsonField.initialData == true;
    }

    _report(_isChecked);

    context.subscribeDataAction(
      widget.jsonField,
      onData: (val) {
        if (val is bool) {
          _onValueChange(val);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget checkbox = Checkbox(
      value: _isChecked,
      onChanged: (value) {
        if (value == null) return;

        _isChecked = value;

        _report(_isChecked);

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
          checkbox,
        ],
      ),
    );
  }

  void _onValueChange(bool? value) {
    if (value == null) return;

    _isChecked = value;
    _report(_isChecked);

    setState(() {});
  }

  void _report(bool? value) {
    if (value == null) return;

    context.reportFieldChange(widget.jsonField, "$value");
    final actionTrigger =
        value ? UIAction.checkedTrigger : UIAction.uncheckedTrigger;
    context.reportActions(widget.jsonField.actions?[actionTrigger]);
  }
}
