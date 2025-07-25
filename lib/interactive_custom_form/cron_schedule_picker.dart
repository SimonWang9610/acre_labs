import 'package:acre_labs/interactive_custom_form/cf_json_field.dart';
import 'package:acre_labs/interactive_custom_form/field_action.dart';
import 'package:acre_labs/interactive_custom_form/core.dart';
import 'package:flutter/material.dart';

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
  String? _currentCron;

  @override
  void initState() {
    super.initState();
    _currentCron = widget.jsonField.fieldJson["initialValue"] as String?;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.reportValueChange(
      widget.jsonField.label,
      _currentCron,
    );
    context.reportItemActions(widget.jsonField.fieldJson);
  }

  @override
  void didUpdateWidget(covariant CronSchedulePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.action?.value != null) {
      _currentCron = widget.action!.value as String?;
      context.reportValueChange(
        widget.jsonField.label,
        _currentCron,
      );
      context.reportItemActions(widget.jsonField.fieldJson);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.jsonField.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.readonlyIndicator != null) widget.readonlyIndicator!,
            ],
          ),
          Text(
            _currentCron ?? '0 0 * * *',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
