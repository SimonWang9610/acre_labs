import 'package:acre_labs/dynamic_custom_form/core/json_field.dart';
import 'package:acre_labs/dynamic_custom_form/non_field_widgets/dynamic_text.dart';
import 'package:acre_labs/dynamic_custom_form/widgets/check_box_widget.dart';
import 'package:acre_labs/dynamic_custom_form/widgets/cron_schedule_widget.dart';
import 'package:acre_labs/dynamic_custom_form/widgets/single_dropdown_widget.dart';
import 'package:acre_labs/dynamic_custom_form/widgets/time_duration_widget.dart';
import 'package:flutter/material.dart';

class DynamicFormFieldBuilder extends StatelessWidget {
  final JsonField jsonField;
  final bool readonly;
  const DynamicFormFieldBuilder({
    super.key,
    required this.jsonField,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    final type = jsonField.type;

    if (DropdownButtonFormFieldWidget.isTypeMatched(type)) {
      return DropdownButtonFormFieldWidget(
        jsonField: jsonField,
        readonly: readonly,
      );
    } else if (DynamicCheckboxWidget.isTypeMatched(type)) {
      return DynamicCheckboxWidget(
        jsonField: jsonField,
        readonly: readonly,
      );
    } else if (DynamicTextWidget.isTypeMatched(type)) {
      return DynamicTextWidget(
        jsonField: jsonField,
      );
    } else if (DynamicCronSchedulePickerWidget.isTypeMatched(type)) {
      return DynamicCronSchedulePickerWidget(
        jsonField: jsonField,
        readonly: readonly,
      );
    } else if (TimeDurationPickerWidget.isTypeMatched(type)) {
      return TimeDurationPickerWidget(
        jsonField: jsonField,
        readonly: readonly,
      );
    } else {
      debugPrint('Unknown field type: $type');
      return const SizedBox
          .shrink(); // Return an empty widget if type is not matched
    }
  }
}
