import 'package:acre_labs/dynamic_custom_form/core.dart';
import 'package:acre_labs/dynamic_custom_form/json_field.dart';
import 'package:flutter/material.dart';

class DynamicTextWidget extends StatefulWidget {
  static const name = "Text";

  final JsonField jsonField;
  final UIAction? action;
  const DynamicTextWidget({
    super.key,
    required this.jsonField,
    this.action,
  });

  @override
  State<DynamicTextWidget> createState() => _DynamicTextWidgetState();
}

class _DynamicTextWidgetState extends State<DynamicTextWidget> {
  String _text = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(covariant DynamicTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_text);
  }

  void _update() {
    _text = widget.action?.data ?? widget.jsonField["data"] ?? "";

    final actions = widget.jsonField.actions?[_text];
    context.reportActions(actions ?? {});
  }
}
