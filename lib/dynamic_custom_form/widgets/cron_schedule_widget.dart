import 'package:acre_labs/dynamic_custom_form/core/extensions.dart';
import 'package:acre_labs/dynamic_custom_form/core/json_field.dart';
import 'package:flutter/material.dart';

class DynamicCronSchedulePickerWidget extends StatefulWidget {
  static bool isTypeMatched(String type) {
    return type == 'CronSchedulePickerWidget' || type == 'CronSchedule';
  }

  final JsonField jsonField;
  final bool readonly;
  const DynamicCronSchedulePickerWidget({
    super.key,
    required this.jsonField,
    this.readonly = false,
  });

  @override
  State<DynamicCronSchedulePickerWidget> createState() =>
      _DynamicCronSchedulePickerWidgetState();
}

class _DynamicCronSchedulePickerWidgetState
    extends State<DynamicCronSchedulePickerWidget> {
  TextEditingController? _cron;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cron?.dispose();

    _cron = TextEditingController(
      text: context.getPreAssignedValue(widget.jsonField) ??
          widget.jsonField.initialData?.toString() ??
          '',
    );

    _cron?.addListener(
      () {
        context.reportFieldChange(widget.jsonField, _cron?.text);
      },
    );

    context.subscribeDataAction(
      widget.jsonField,
      onData: (val) {
        if (val is String) {
          _cron?.text = val;
        }
      },
    );
  }

  @override
  void dispose() {
    _cron?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.jsonField.label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (widget.readonly)
          Tooltip(
            message: 'This field is read-only',
            child: const Icon(
              Icons.do_not_disturb_alt_rounded,
              color: Colors.red,
            ),
          ),
        TextField(
          controller: _cron,
          decoration: InputDecoration(
            hintText: 'Enter cron schedule',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
