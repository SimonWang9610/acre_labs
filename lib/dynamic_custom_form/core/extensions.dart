import 'package:acre_labs/dynamic_custom_form/core/form_registry.dart';
import 'package:acre_labs/dynamic_custom_form/core/json_field.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

extension CFFieldStateExtension on BuildContext {
  DynamicFormRegistry? get cfRegistry {
    if (!mounted) return null;

    return CFManager.of(this);
  }

  void reportActions(Map<String, UIAction>? actions) {
    if (!mounted || actions == null || actions.isEmpty) return;

    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.postFrameCallbacks) {
      cfRegistry?.dispatch(actions);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cfRegistry?.dispatch(actions);
      });
    }
  }

  void reportFieldChange(JsonField field, dynamic value) {
    if (!mounted) return;
    cfRegistry?.reportValueChange(field.label, value);
  }

  void subscribeDataAction(JsonField field,
      {required FieldDataActionCallback onData}) {
    if (!mounted) return;

    cfRegistry?.subscribeDataAction(field.label, onData: onData);
  }

  /// Get the pre-assigned value for a field.
  /// It is designed to be compatible with [ConvertCustomFormWidgets.assignValues]
  ///
  /// Each widget will handle the pre-assigned value in its [didChangeDependencies] method to apply the value.
  ///
  /// Designed for  editor custom form fields that need to get the pre-assigned value from the [BaseInfo.metadata],
  /// while the fit custom form should set `@preset` or initialValues in the action data.
  String? getPreAssignedValue(JsonField field) {
    if (!mounted) return null;
    return cfRegistry?.preAssignedValues[field.label];
  }
}

extension DateTimeTrimExt on DateTime {
  /// Designed for format compatibility with the server.
  ///
  /// Somehow, the millisecond part is truncated after the server processes the date.
  /// This method converts the DateTime to a string without milliseconds to match the server's expected format.
  /// So that we can ensure consistent date formatting across different platforms.
  String toNonMillString() {
    final str = toUtc().toIso8601String();

    return "${str.substring(0, str.length - 5)}Z";
  }
}
