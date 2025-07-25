import 'package:flutter/material.dart';

enum CronRange {
  minute(0, 59),
  hour(0, 23),
  day(1, 31),
  month(1, 12),
  weekday(0, 6); // 0 = Sunday, 1 = Monday,

  final int min;
  final int max;

  const CronRange(this.min, this.max);
}

class CronExpression {
  static final fieldReg = RegExp(r'^\d+(-\d+)?(,\d+(-\d+)?)*$');

  final Set<int> minutes;
  final Set<int> hours;
  final Set<int> days;
  final Set<int> months;
  final Set<int> weekdays;

  const CronExpression({
    required this.minutes,
    required this.hours,
    required this.days,
    required this.months,
    required this.weekdays,
  });

  factory CronExpression.always() {
    return const CronExpression(
      minutes: {},
      hours: {},
      days: {},
      months: {},
      weekdays: {},
    );
  }

  static CronExpression parse(String cron) {
    final parts = cron.trim().split(RegExp(r'\s+'));
    if (parts.length != 5) {
      throw const FormatException(
          'Cron must have 5 fields: minute hour day month weekday');
    }

    return CronExpression(
      minutes: _parseField(parts[0], CronRange.minute),
      hours: _parseField(parts[1], CronRange.hour),
      days: _parseField(parts[2], CronRange.day),
      months: _parseField(parts[3], CronRange.month),
      weekdays: _parseField(parts[4], CronRange.weekday),
    );
  }

  static Set<int> _parseField(String field, CronRange valueRange) {
    if (field == '*' || field.isEmpty) {
      return Set.from(List.generate(
          valueRange.max - valueRange.min + 1, (i) => valueRange.min + i));
    }

    final parts = field.split(',');
    final result = <int>{};

    for (final part in parts) {
      if (part.contains('/')) {
        /// handle: min-max/step, or value/step

        final split = part.split('/');

        if (split.length != 2) {
          throw FormatException('Invalid step format: $part');
        }

        final range = split[0];
        final step = int.parse(split[1]);

        final rangeValues = _parseField(range, valueRange).toList()..sort();
        for (int i = 0; i < rangeValues.length; i += step) {
          result.add(rangeValues[i]);
        }
      } else if (part.contains('-')) {
        /// handle: min-max
        final split = part.split('-');

        if (split.length != 2) {
          throw FormatException('Invalid range format: $part');
        }

        final start = int.parse(split[0]);
        final end = int.parse(split[1]);
        result.addAll(List.generate(end - start + 1, (i) => start + i));
      } else {
        /// handle: single value
        result.add(int.parse(part));
      }
    }

    final validatedResult = result
        .every((value) => value >= valueRange.min && value <= valueRange.max);

    if (!validatedResult) {
      throw FormatException(
          'Values out of range for ${valueRange.name}: $field');
    }

    return result;
  }

  static Set<int>? validateField(String field, CronRange range) {
    try {
      final values = _parseField(field, range);
      for (final value in values) {
        if (value < range.min || value > range.max) {
          return null;
        }
      }
      return values;
    } catch (e) {
      debugPrint('Error validating field "$field": $e');
      return null;
    }
  }

  bool validate() {
    // Validate that all fields are within their respective ranges
    for (final minute in minutes) {
      if (minute < CronRange.minute.min || minute > CronRange.minute.max) {
        return false;
      }
    }
    for (final hour in hours) {
      if (hour < CronRange.hour.min || hour > CronRange.hour.max) {
        return false;
      }
    }
    for (final day in days) {
      if (day < CronRange.day.min || day > CronRange.day.max) {
        return false;
      }
    }
    for (final month in months) {
      if (month < CronRange.month.min || month > CronRange.month.max) {
        return false;
      }
    }
    for (final weekday in weekdays) {
      if (weekday < CronRange.weekday.min || weekday > CronRange.weekday.max) {
        return false;
      }
    }

    return true;
  }

  CronExpression copyWith({
    Set<int>? minutes,
    Set<int>? hours,
    Set<int>? days,
    Set<int>? months,
    Set<int>? weekdays,
  }) {
    return CronExpression(
      minutes: minutes ?? this.minutes,
      hours: hours ?? this.hours,
      days: days ?? this.days,
      months: months ?? this.months,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  @override
  String toString() {
    return "${minutes.join(',')} ${hours.join(',')} ${days.join(',')} ${months.join(',')} ${weekdays.join(',')}";
  }

  String toCronString() {
    return '${minutes.toShortCronField(CronRange.minute.min, CronRange.minute.max)} '
        '${hours.toShortCronField(CronRange.hour.min, CronRange.hour.max)} '
        '${days.toShortCronField(CronRange.day.min, CronRange.day.max)} '
        '${months.toShortCronField(CronRange.month.min, CronRange.month.max)} '
        '${weekdays.toShortCronField(CronRange.weekday.min, CronRange.weekday.max)}';
  }
}

extension CronFieldStringExt on Set<int> {
  String toShortCronField(
    int min,
    int max, {
    String separator = ',',
  }) {
    final sorted = toList()..sort();

    // Full range, if all values are present
    /// if empty, return '*'
    if (length == (max - min + 1) || length == 0) return '*';

    // Detect consecutive ranges (e.g. 1-5,7,9-11)
    final List<String> parts = [];
    int start = sorted[0];
    int prev = sorted[0];

    for (int i = 1; i <= sorted.length; i++) {
      if (i < sorted.length && sorted[i] == prev + 1) {
        prev = sorted[i];
        continue;
      }
      if (start == prev) {
        parts.add('$start');
      } else if (prev == start + 1) {
        parts.add('$start,$prev');
      } else {
        parts.add('$start-$prev');
      }
      if (i < sorted.length) {
        start = prev = sorted[i];
      }
    }

    return parts.join(separator);
  }
}

extension HumanReadableExt on CronExpression {
  String toHumanReadable() {
    return [
      describeMinutes(),
      describeHours(),
      describeWeekdays(),
      describeDays(),
      describeMonths(),
    ].where((part) => part.isNotEmpty).join('\n');
  }

  String describeMinutes() {
    final step = _ifStep(minutes, CronRange.minute);

    if (step != null) {
      return step == 1 ? 'Every minute' : 'Every $step minutes';
    }

    if (minutes.isEmpty) return 'Every minute';

    return "At minutes: ${minutes.toShortCronField(CronRange.minute.min, CronRange.minute.max, separator: "/")}";
  }

  String describeHours() {
    final step = _ifStep(hours, CronRange.hour);

    if (step != null) {
      return step == 1 ? 'Every hour' : 'Every $step hours';
    }

    if (hours.isEmpty) return 'Every hour';

    return "At hours: ${hours.toShortCronField(CronRange.hour.min, CronRange.hour.max, separator: "/")}";
  }

  String describeDays() {
    final step = _ifStep(days, CronRange.day);

    if (step != null) {
      return step == 1 ? 'Every day' : 'Every $step days';
    }

    if (days.isEmpty) return 'Every day';

    return "At days: ${days.toShortCronField(CronRange.day.min, CronRange.day.max, separator: "/")}";
  }

  String describeMonths() {
    final step = _ifStep(months, CronRange.month);

    if (step != null) {
      return step == 1 ? 'Every month' : 'Every $step months';
    }

    if (months.isEmpty) return 'Every month';

    return "At months: ${months.toShortCronField(CronRange.month.min, CronRange.month.max, separator: "/")}";
  }

  String describeWeekdays() {
    final step = _ifStep(weekdays, CronRange.weekday);

    if (step != null) {
      return step == 1
          ? 'Every day of the week'
          : 'Every $step days of the week';
    }

    if (weekdays.isEmpty) return 'Every day of the week';

    const weekdayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];

    final weekdaysList = weekdays.map((day) => weekdayNames[day]).join('/');

    return "At weekdays: $weekdaysList";
  }

  int? _ifStep(Set<int> values, CronRange range) {
    if (values.length < 2) return null;

    final sorted = values.toList()..sort();
    final step = sorted[1] - sorted[0];

    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] - sorted[i - 1] != step) {
        return null;
      }
    }

    final isFullRange = sorted.first <= range.min && sorted.last >= range.max;

    return isFullRange ? step : null;
  }
}
