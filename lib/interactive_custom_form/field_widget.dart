import 'package:acre_labs/interactive_custom_form/cf_central_manager.dart';
import 'package:acre_labs/interactive_custom_form/cf_json_field.dart';
import 'package:acre_labs/interactive_custom_form/field_command.dart';
import 'package:acre_labs/interactive_custom_form/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'time_duration_picker.dart';

class CFFieldWidget extends StatefulWidget {
  final CFJsonField field;
  final bool visible;
  final bool readonly;
  const CFFieldWidget({
    super.key,
    required this.field,
    this.visible = true,
    this.readonly = false,
  });

  @override
  State<CFFieldWidget> createState() => _CFFieldWidgetState();
}

class _CFFieldWidgetState extends State<CFFieldWidget> with CFFieldRegistry {
  final ValueNotifier<CFFieldAction?> _action = ValueNotifier(null);

  @override
  void dispose() {
    _action.dispose();
    super.dispose();
  }

  @override
  String get fieldLabel => widget.field.label;

  @override
  bool get isOptional => widget.field.isOptional;

  @override
  void executeAction(CFFieldAction action) {
    if (action.label != fieldLabel) return;
    _action.value = action;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _action,
      builder: (context, action, child) {
        final visible = action?.visible ?? true;
        final readonly = action?.readonly ?? false;

        _isVisible = visible;

        return Visibility(
          visible: visible,
          maintainState: true,
          child: IgnorePointer(
            ignoring: readonly,
            child: buildFieldWidget(
              widget.field,
              action,
              readonly: readonly,
            ),
          ),
        );
      },
    );
  }

  Widget buildFieldWidget(
    CFJsonField field,
    CFFieldAction? action, {
    bool readonly = false,
  }) {
    final readonlyIndicator = readonly
        ? Tooltip(
            message: 'This field is read-only',
            child:
                const Icon(Icons.do_not_disturb_alt_rounded, color: Colors.red),
          )
        : null;

    final fieldWidget = switch (widget.field.fieldTypeName) {
      DropdownButtonFormFieldWidget.name => DropdownButtonFormFieldWidget(
          jsonField: widget.field,
          action: action,
          readonlyIndicator: readonlyIndicator,
        ),
      CheckboxWidget.name => CheckboxWidget(
          jsonField: widget.field,
          action: action,
          readonlyIndicator: readonlyIndicator,
        ),
      MultiSelectDropdownWidget.name => MultiSelectDropdownWidget(
          jsonField: widget.field,
          action: action,
          readonlyIndicator: readonlyIndicator,
        ),
      CronSchedulePickerWidget.name => CronSchedulePickerWidget(
          jsonField: widget.field,
          action: action,
          readonlyIndicator: readonlyIndicator,
        ),
      TimeDurationPickerWidget.name => TimeDurationPickerWidget(
          jsonField: widget.field,
          action: action,
          readonlyIndicator: readonlyIndicator,
        ),
      _ => widget.field.wrapWidget(null),
    };

    return fieldWidget;
  }
}

typedef CFFieldActionDispatcher = void Function(List<CFFieldAction> actions);
typedef CFFieldValueChangeCallback = void Function(String label, dynamic value);

mixin CFFieldRegistry<T extends StatefulWidget> on State<T> {
  String get fieldLabel;
  bool get isOptional;
  bool get isVisible => _isVisible;

  late bool _isVisible;

  void executeAction(CFFieldAction action) {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerFieldState();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
    _registerFieldState();
  }

  @override
  void dispose() {
    // final CFCentralManager manager = CFManager.of(context);
    // manager.unregister(fieldLabel);

    super.dispose();
  }

  void _registerFieldState() {
    final CFCentralManager manager = CFManager.of(context);
    manager.register(fieldLabel, this);
  }
}

extension CFManagerContextExt on BuildContext {
  CFCentralManager? get cfManager {
    if (!mounted) {
      return null;
    }
    return CFManager.of(this);
  }

  void reportActions(List<CFFieldAction> actions) {
    if (actions.isEmpty) return;

    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.postFrameCallbacks) {
      // If we are in the post-frame callback phase, we can directly dispatch actions
      cfManager?.dispatchActions(actions);
    } else {
      // Otherwise, we need to schedule the dispatch for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cfManager?.dispatchActions(actions);
      });
    }
  }

  void reportValueChange(String label, dynamic value) {
    cfManager?.reportValueChange(label, value);
  }

  void reportItemActions(Map<String, dynamic> item) {
    final actions = CFFieldAction.fromActions(
      item["actions"] as Map<String, dynamic>?,
    );
    reportActions(actions);
  }
}
