import 'package:acre_labs/dynamic_custom_form/core.dart';
import 'package:acre_labs/dynamic_custom_form/json_field.dart';
import 'package:acre_labs/dynamic_custom_form/widgets/check_box_widget.dart';
import 'package:acre_labs/dynamic_custom_form/widgets/cron_schedule_widget.dart';
import 'package:acre_labs/dynamic_custom_form/widgets/single_dropdown_widget.dart';
import 'package:acre_labs/dynamic_custom_form/widgets/time_duration_widget.dart';
import 'package:flutter/material.dart';

/// A helper class to build widgets from JSON definitions.
class CFWidgetBuilder {
  static Widget buildJsonWidget(
      BuildContext context, Map<String, dynamic>? json) {
    if (json == null) return const SizedBox.shrink();

    final type = json["type"] as String?;
    final label = json["label"] as String?;

    if (type == null) {
      return const SizedBox.shrink();
    }

    if (label != null) {
      return CFStateWrapperWidget(
        jsonField: JsonField.fromJson(json),
      );
    }

    return switch (type) {
      "Text" => _buildText(context, json),
      "Padding" => _buildPadding(context, json),
      "SizedBox" => _buildSizedBox(context, json),
      "Align" => _buildAlign(context, json),
      "DecoratedBox" => _buildDecoratedBox(context, json),
      "Row" => _buildRow(context, json),
      "Expanded" => _buildExpanded(context, json),
      _ => throw UnsupportedError('Unsupported widget type: $type'),
    };
  }

  static Widget _buildText(BuildContext context, Map<String, dynamic> json) {
    final text = json["data"] as String? ?? "";
    return Text(text);
  }

  static Widget _buildPadding(BuildContext context, Map<String, dynamic> json) {
    final padding = json["padding"] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: EdgeInsets.fromLTRB(
        double.tryParse(padding['left'].toString()) ?? 0,
        double.tryParse(padding['top'].toString()) ?? 0,
        double.tryParse(padding['right'].toString()) ?? 10,
        double.tryParse(padding['bottom'].toString()) ?? 10,
      ),
      child: buildJsonWidget(context, json["child"]),
    );
  }

  static Widget _buildSizedBox(
      BuildContext context, Map<String, dynamic> json) {
    final width = json["width"] as double?;
    final height = json["height"] as double?;
    return SizedBox(
      width: width,
      height: height,
      child: buildJsonWidget(context, json["child"]),
    );
  }

  static Widget _buildAlign(BuildContext context, Map<String, dynamic> json) {
    return Align(
      alignment: Alignment.center, // Default to center
      child: buildJsonWidget(context, json["child"]),
    );
  }

  static Widget _buildDecoratedBox(
      BuildContext context, Map<String, dynamic> json) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1.0,
            style: BorderStyle.solid,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(3.0)),
        ),
      ),
      child: buildJsonWidget(context, json["child"]),
    );
  }

  static Widget _buildRow(BuildContext context, Map<String, dynamic> json) {
    final children = <Widget>[];
    if (json.containsKey("children")) {
      for (final child in json["children"]) {
        if (child is Map<String, dynamic>) {
          final widget = buildJsonWidget(context, child);

          if (widget is Text) {
            children.add(Expanded(
              flex: 6,
              child: widget,
            ));
          } else {
            children.add(widget);
          }
        }
      }
    }

    return Row(
      children: children,
    );
  }

  static Widget _buildExpanded(
      BuildContext context, Map<String, dynamic> json) {
    final child = buildJsonWidget(context, json["child"]);
    return Expanded(
      child: child,
    );
  }
}

/// A helper class to build field widgets from [JsonField] definitions.
class CFFieldBuilder {
  static Widget buildFieldWidget(
    BuildContext context,
    JsonField field, {
    UIAction? action,
    bool readonly = false,
  }) {
    return switch (field.type) {
      CheckboxWidget.name => CheckboxWidget(
          jsonField: field,
          action: action,
          readonly: readonly,
        ),
      CronSchedulePickerWidget.name => CronSchedulePickerWidget(
          jsonField: field,
          action: action,
          readonly: readonly,
        ),
      TimeDurationPickerWidget.name => TimeDurationPickerWidget(
          jsonField: field,
          action: action,
          readonly: readonly,
        ),
      DropdownButtonFormFieldWidget.name => DropdownButtonFormFieldWidget(
          jsonField: field,
          action: action,
          readonly: readonly,
        ),
      _ => throw UnsupportedError(
          'Unsupported field type: ${field.type}',
        ),
    };
  }
}
