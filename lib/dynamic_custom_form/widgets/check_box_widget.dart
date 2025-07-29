import 'package:acre_labs/dynamic_custom_form/core.dart';
import 'package:acre_labs/dynamic_custom_form/json_field.dart';
import 'package:flutter/material.dart';

class CheckboxWidget extends StatefulWidget {
  static const name = 'CheckboxWidget';

  final JsonField jsonField;
  final UIAction? action;
  final bool readonly;

  const CheckboxWidget({
    super.key,
    required this.jsonField,
    this.action,
    this.readonly = false,
  });

  @override
  State<CheckboxWidget> createState() => _CheckboxWidgetState();
}

class _CheckboxWidgetState extends State<CheckboxWidget> {
  late bool _isChecked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isChecked = widget.action?.data == true;
  }

  @override
  void didUpdateWidget(covariant CheckboxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.action?.data != null) {
      _isChecked = widget.action?.data == true;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget checkbox = Checkbox(
      value: _isChecked,
      onChanged: (value) {
        if (value == null) return;

        _isChecked = value;

        final actionsMap =
            widget.jsonField.actions?[_isChecked ? 'true' : 'false'];
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

  void _report(Map<String, UIAction>? actionsMap) {
    context.reportActions(actionsMap ?? {});
    context.reportValueChange(
      widget.jsonField.label,
      _isChecked,
    );
  }
}
