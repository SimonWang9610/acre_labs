import 'package:acre_labs/dynamic_custom_form/core/extensions.dart';
import 'package:acre_labs/dynamic_custom_form/core/json_field.dart';
import 'package:flutter/material.dart';

class DynamicTextWidget extends StatefulWidget {
  static bool isTypeMatched(String type) {
    return type == 'TextWidget' || type == 'Text';
  }

  final JsonField jsonField;
  const DynamicTextWidget({
    super.key,
    required this.jsonField,
  });

  @override
  State<DynamicTextWidget> createState() => _DynamicTextWidgetState();
}

class _DynamicTextWidgetState extends State<DynamicTextWidget> {
  String _text = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initialText = context.getPreAssignedValue(widget.jsonField) ??
        widget.jsonField.initialData ??
        widget.jsonField["data"] ??
        "";

    _text = initialText;

    context.subscribeDataAction(
      widget.jsonField,
      onData: (val) {
        _update(val);

        if (mounted) setState(() {});
      },
    );

    _update(initialText);
  }

  @override
  Widget build(BuildContext context) {
    return Text(_text);
  }

  void _update(dynamic value) {
    if (value == null || value is! String) return;

    _text = value;

    final actionTrigger =
        _text.isEmpty ? UIAction.emptyTrigger : UIAction.notEmptyTrigger;

    final actions = widget.jsonField.actions?[_text] ??
        widget.jsonField.actions?[actionTrigger];

    context.reportActions(actions);
  }
}
