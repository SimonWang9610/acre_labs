import 'package:acre_labs/dynamic_custom_form/core.dart';
import 'package:acre_labs/dynamic_custom_form/json_field.dart';
import 'package:flutter/material.dart';

class CronSchedulePickerWidget extends StatefulWidget {
  static const name = 'CronSchedulePickerWidget';

  final JsonField jsonField;
  final UIAction? action;
  final bool readonly;
  const CronSchedulePickerWidget({
    super.key,
    required this.jsonField,
    this.action,
    this.readonly = false,
  });

  @override
  State<CronSchedulePickerWidget> createState() =>
      _CronSchedulePickerWidgetState();
}

class _CronSchedulePickerWidgetState extends State<CronSchedulePickerWidget> {
  late final _cron = TextEditingController(
    text: widget.action?.data ?? '',
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cron.addListener(
      () {
        if (_cron.text.isNotEmpty) {
          context.reportValueChange(widget.jsonField.label, _cron.text);
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant CronSchedulePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.action?.data != null) {
      _cron.text = widget.action!.data;
    }
  }

  @override
  void dispose() {
    _cron.dispose();
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
