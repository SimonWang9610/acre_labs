import 'package:flutter/material.dart';
import 'cron_expression.dart';

class CronSchedulePickerWidget extends StatefulWidget {
  final String? initialSchedule;
  final ValueChanged<CronExpression?> onScheduleChanged;

  late _CronSchedulePickerWidgetState? _state;

  CronSchedulePickerWidget({
    super.key,
    required this.onScheduleChanged,
    this.initialSchedule,
  });

  @override
  State<CronSchedulePickerWidget> createState() =>
      _CronSchedulePickerWidgetState();

  static String? getScheduleString(CronSchedulePickerWidget widget) {
    return widget._state?._cron.toCronString();
  }
}

class _CronSchedulePickerWidgetState extends State<CronSchedulePickerWidget> {
  late CronExpression _cron;

  @override
  void initState() {
    super.initState();
    widget._state = this;
    _cron = widget.initialSchedule != null
        ? CronExpression.parse(widget.initialSchedule!)
        : CronExpression.always();
  }

  @override
  void didUpdateWidget(covariant CronSchedulePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSchedule != widget.initialSchedule) {
      _cron = widget.initialSchedule != null
          ? CronExpression.parse(widget.initialSchedule!)
          : CronExpression.always();
    }

    if (oldWidget != widget) {
      oldWidget._state = null;
      widget._state = this;
    }
  }

  @override
  Widget build(BuildContext context) {
    // return _CronField(
    //   onCronChanged: (value) {
    //     _updateSchedule(
    //       minutes: value?.minutes,
    //       hours: value?.hours,
    //       days: value?.days,
    //       months: value?.months,
    //       weekdays: value?.weekdays,
    //     );
    //   },
    // );
    return Column(
      spacing: 5,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          spacing: 15,
          children: [
            _CronPartTextField(
              range: CronRange.hour,
              initialValues: _cron.hours,
              onChanged: (values) {
                _updateSchedule(hours: values);
              },
              width: 100,
              hintText: 'e.g., 0-23',
            ),
            _CronPartTextField(
              range: CronRange.minute,
              initialValues: _cron.minutes,
              onChanged: (values) {
                _updateSchedule(minutes: values);
              },
              width: 100,
              hintText: 'e.g., 0-59',
            ),
          ],
        ),
        Row(
          spacing: 15,
          children: [
            _CronPartTextField(
              range: CronRange.weekday,
              initialValues: _cron.weekdays,
              onChanged: (values) {
                _updateSchedule(weekdays: values);
              },
              width: 100,
              hintText: 'e.g., 0-6',
            ),
            _CronPartTextField(
              range: CronRange.day,
              initialValues: _cron.days,
              onChanged: (values) {
                _updateSchedule(days: values);
              },
              width: 100,
              hintText: 'e.g., 1-31',
            ),
          ],
        ),
        _CronPartTextField(
          range: CronRange.month,
          initialValues: _cron.months,
          onChanged: (values) {
            _updateSchedule(months: values);
          },
          width: 100,
          hintText: 'e.g., 1-12',
        ),
      ],
    );
  }

  void _updateSchedule({
    Set<int>? minutes,
    Set<int>? hours,
    Set<int>? days,
    Set<int>? months,
    Set<int>? weekdays,
  }) {
    _cron = _cron.copyWith(
      minutes: minutes ?? _cron.minutes,
      hours: hours ?? _cron.hours,
      days: days ?? _cron.days,
      months: months ?? _cron.months,
      weekdays: weekdays ?? _cron.weekdays,
    );
    widget.onScheduleChanged(_cron);
  }
}

class _CronPartTextField extends StatefulWidget {
  final CronRange range;
  final Set<int> initialValues;
  final ValueChanged<Set<int>> onChanged;
  final double width;
  final String? hintText;
  const _CronPartTextField({
    super.key,
    required this.range,
    required this.initialValues,
    required this.onChanged,
    required this.width,
    this.hintText,
  });

  @override
  State<_CronPartTextField> createState() => _CronPartTextFieldState();
}

class _CronPartTextFieldState extends State<_CronPartTextField> {
  @override
  Widget build(BuildContext context) {
    final label = switch (widget.range) {
      CronRange.minute => 'Minutes',
      CronRange.hour => 'Hours',
      CronRange.day => 'Days',
      CronRange.month => 'Months',
      CronRange.weekday => 'Weekdays',
    };

    return Row(
      spacing: 8,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(
          width: widget.width,
          child: TextFormField(
            initialValue: widget.initialValues.isEmpty
                ? '*'
                : widget.initialValues.toShortCronField(
                    widget.range.min,
                    widget.range.max,
                  ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }
              final values = CronExpression.validateField(value, widget.range);
              if (values == null) {
                return 'Invalid value';
              }
              return null;
            },
            onChanged: (value) {
              final values = CronExpression.validateField(value, widget.range);
              if (values != null) {
                widget.onChanged(values);
              }
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: const OutlineInputBorder(),
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
              errorBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
