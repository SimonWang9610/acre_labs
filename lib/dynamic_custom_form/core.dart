import 'package:acre_labs/dynamic_custom_form/json_field.dart';
import 'package:acre_labs/dynamic_custom_form/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CFStateWrapperWidget extends StatefulWidget {
  final JsonField jsonField;
  const CFStateWrapperWidget({
    super.key,
    required this.jsonField,
  });

  @override
  State<CFStateWrapperWidget> createState() => _CFStateWrapperWidgetState();
}

class _CFStateWrapperWidgetState extends State<CFStateWrapperWidget>
    with _CFFieldStateRegistry {
  late final _lastAction = ValueNotifier<UIAction?>(widget.jsonField.preset);

  String get fieldLabel => widget.jsonField.label;

  bool get isOptional {
    final config = widget.jsonField.uiConfig;

    return config?["isOptional"] == true || config?["isRequired"] == false;
  }

  bool get isNonField {
    return widget.jsonField.isNonField;
  }

  bool get isVisible => _isVisible;
  late bool _isVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerFieldState();
  }

  @override
  void dispose() {
    _lastAction.dispose();
    super.dispose();
  }

  void applyAction(UIAction action) {
    _lastAction.value = action;
  }

  void _registerFieldState() {
    final registry = context.cfRegistry;
    if (registry != null) {
      registry._register(fieldLabel, this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _lastAction,
      builder: (context, action, child) {
        final visible = action?.state?.visible ?? true;
        final readonly = action?.state?.readonly ?? false;

        print(
          'Building field: $fieldLabel, visible: $visible, readonly: $readonly',
        );

        _isVisible = visible;

        return Visibility(
          visible: visible,
          maintainState: true,
          child: IgnorePointer(
            ignoring: readonly,
            child: CFFieldBuilder.buildFieldWidget(
              context,
              widget.jsonField,
              action: action,
              readonly: readonly,
            ),
          ),
        );
      },
    );
  }
}

mixin _CFFieldStateRegistry<T extends StatefulWidget> on State<T> {}

class CFFieldRegistry {
  final List<Map<String, dynamic>> formDefinitions;

  CFFieldRegistry({
    required this.formDefinitions,
  });

  final Map<String, _CFStateWrapperWidgetState> _fieldStates = {};
  final Map<String, dynamic> _fieldValues = {};

  void _register(String label, _CFStateWrapperWidgetState state) {
    _fieldStates[label] = state;
  }

  void dispatch(Map<String, UIAction> actions) {
    for (final entry in actions.entries) {
      final fieldLabel = entry.key;
      final action = entry.value;

      if (_fieldStates.containsKey(fieldLabel)) {
        _fieldStates[fieldLabel]?.applyAction(action);
      }
    }
  }

  void reportValueChange(String label, dynamic value) {
    final fieldState = _fieldStates[label];

    // do not collect value for non-field but dynamic widgets
    if (fieldState == null || fieldState.isNonField) return;

    assert(() {
      final currentValue = _fieldValues[label];

      if (currentValue == null || value == null) {
        return true;
      }

      return currentValue.runtimeType == value.runtimeType;
    }(), "Field value type inconsistent: $label: $value");

    _fieldValues[label] = value;
  }

  void setValue(String label, dynamic value) {
    _fieldValues[label] = value;

    if (_fieldStates.containsKey(label)) {
      _fieldStates[label]?.applyAction(UIAction(data: value));
    }
  }

  void reset() {
    _fieldStates.clear();
    _fieldValues.clear();
  }

  Map<String, dynamic> get formValues => Map.of(_fieldValues);

  Map<String, dynamic> getFormValues({bool excludeInvisible = true}) {
    if (!excludeInvisible) return Map.of(_fieldValues);

    final values = <String, dynamic>{};

    for (final label in _fieldValues.keys) {
      final field = _fieldStates[label];
      if (field == null || field.isNonField) continue;
      if (excludeInvisible && !field.isVisible) continue;

      values[label] = _fieldValues[label];
    }

    return values;
  }

  // List<Widget> buildFormFields(BuildContext context) {
  //   return formDefinitions
  //       .map((json) => CFWidgetBuilder.buildJsonWidget(context, json))
  //       .toList();
  // }

  Widget buildFieldByIndex(BuildContext context, int index) {
    if (index < 0 || index >= formDefinitions.length) {
      throw RangeError.index(index, formDefinitions, 'index');
    }

    final json = formDefinitions[index];
    return CFWidgetBuilder.buildJsonWidget(context, json);
  }

  int get fieldCount => formDefinitions.length;
}

class CFManager extends InheritedWidget {
  final CFFieldRegistry registry;

  const CFManager({
    super.key,
    required this.registry,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant CFManager oldWidget) {
    return oldWidget.registry != registry;
  }

  static CFFieldRegistry of(BuildContext context) {
    final CFManager? manager =
        context.dependOnInheritedWidgetOfExactType<CFManager>();

    if (manager == null) {
      throw Exception('CFManager not found in context');
    }

    return manager.registry;
  }
}

extension CFFieldStateExtension on BuildContext {
  CFFieldRegistry? get cfRegistry {
    if (!mounted) return null;

    return CFManager.of(this);
  }

  void reportActions(Map<String, UIAction> actions) {
    if (!mounted || actions.isEmpty) return;

    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.postFrameCallbacks) {
      cfRegistry?.dispatch(actions);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cfRegistry?.dispatch(actions);
      });
    }
  }

  void reportValueChange(String label, dynamic value) {
    if (!mounted) return;

    cfRegistry?.reportValueChange(label, value);
  }
}
