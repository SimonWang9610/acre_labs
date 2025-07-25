import 'package:acre_labs/interactive_custom_form/cf_json_field.dart';
import 'package:acre_labs/interactive_custom_form/field_action.dart';
import 'package:acre_labs/interactive_custom_form/core.dart';
import 'package:flutter/material.dart';

class TimeDurationPickerWidget extends StatefulWidget {
  static const name = 'TimeDurationPickerWidget';

  final CFJsonField jsonField;
  final CFFieldAction? action;
  final Widget? readonlyIndicator;

  const TimeDurationPickerWidget({
    super.key,
    required this.jsonField,
    this.action,
    this.readonlyIndicator,
  });

  @override
  State<TimeDurationPickerWidget> createState() =>
      _TimeDurationPickerWidgetState();
}

class _TimeDurationPickerWidgetState extends State<TimeDurationPickerWidget> {
  PickedTimeDuration? _currentDuration;

  late final TextEditingController _month;
  late final TextEditingController _day;
  late final TextEditingController _hour;

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.jsonField.fieldJson["initialValue"] != null
        ? PickedTimeDuration.fromString(
            widget.jsonField.fieldJson["initialValue"])
        : null;

    _month = TextEditingController(text: _currentDuration?.months?.toString());
    _day = TextEditingController(text: _currentDuration?.days?.toString());
    _hour = TextEditingController(text: _currentDuration?.hours?.toString());

    _month.addListener(_onDurationChanged);
    _day.addListener(_onDurationChanged);
    _hour.addListener(_onDurationChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.reportValueChange(
        widget.jsonField.label, _currentDuration?.getFormattedDuration());
  }

  @override
  void didUpdateWidget(covariant TimeDurationPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.action?.value != null) {
      final newDuration = PickedTimeDuration.fromString(widget.action!.value);
      _month.text = newDuration.months?.toString() ?? '';
      _day.text = newDuration.days?.toString() ?? '';
      _hour.text = newDuration.hours?.toString() ?? '';

      _currentDuration = newDuration;

      context.reportValueChange(
        widget.jsonField.label,
        newDuration.getFormattedDuration(),
      );
      context.reportItemActions(widget.jsonField.fieldJson);
    }
  }

  @override
  void dispose() {
    _month.dispose();
    _day.dispose();
    _hour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border:
                Border.all(width: 2, color: Theme.of(context).disabledColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            spacing: 15,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DurationPartField(
                controller: _month,
                width: 50,
                label: "Months",
                validator: (v) {
                  if (_currentDuration == null || !_currentDuration!.isValid) {
                    return "Invalid_Duration";
                  }

                  return null;
                },
              ),
              _DurationPartField(
                controller: _day,
                label: "Days",
                width: 50,
                validator: (v) {
                  if (_currentDuration == null || !_currentDuration!.isValid) {
                    return "Invalid_Duration";
                  }

                  return null;
                },
              ),
              _DurationPartField(
                controller: _hour,
                label: "Hours",
                width: 50,
                validator: (v) {
                  if (_currentDuration == null || !_currentDuration!.isValid) {
                    return "Invalid_Duration";
                  }

                  return null;
                },
              ),
            ],
          ),
        )
      ],
    );
  }

  void _onDurationChanged() {
    final months = int.tryParse(_month.text);
    final days = int.tryParse(_day.text);
    final hours = int.tryParse(_hour.text);

    _currentDuration =
        PickedTimeDuration(months: months, days: days, hours: hours);

    context.reportValueChange(
        widget.jsonField.label, _currentDuration?.getFormattedDuration());
  }
}

class _DurationPartField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final double width;
  final FormFieldValidator<String>? validator;
  const _DurationPartField({
    required this.controller,
    required this.label,
    this.width = 50,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: width,
        child: Column(
          spacing: 5,
          children: [
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                border: const OutlineInputBorder(),
                hintText: '0',
                hintStyle: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              validator: validator,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class PickedTimeDuration {
  final int? months;
  final int? days;
  final int? hours;

  const PickedTimeDuration({
    this.months,
    this.days,
    this.hours,
  });

  factory PickedTimeDuration.fromString(String duration) {
    final regex = RegExp(r'(?:(\d+)m)?(?:(\d+)d)?(?:(\d+)h)?');
    final match = regex.firstMatch(duration);

    if (match == null) {
      throw const FormatException("Invalid duration format");
    }

    return PickedTimeDuration(
      months: int.tryParse(match.group(1) ?? ''),
      days: int.tryParse(match.group(2) ?? ''),
      hours: int.tryParse(match.group(3) ?? ''),
    );
  }

  bool get isValid {
    return (months != null && months! >= 0) ||
        (days != null && days! >= 0) ||
        (hours != null && hours! >= 0);
  }

  String? getFormattedDuration() {
    if (!isValid) return null;

    final parts = <String>[];
    if (months != null) {
      parts.add("${months}m");
    }

    if (days != null) {
      parts.add("${days}d");
    }

    if (hours != null) {
      parts.add("${hours}h");
    }

    return parts.join('');
  }

  PickedTimeDuration copyWith({
    int? months,
    int? days,
    int? hours,
  }) {
    return PickedTimeDuration(
      months: months ?? this.months,
      days: days ?? this.days,
      hours: hours ?? this.hours,
    );
  }

  @override
  String toString() {
    return 'PickedTimeDuration(months: $months, days: $days, hours: $hours)';
  }
}
