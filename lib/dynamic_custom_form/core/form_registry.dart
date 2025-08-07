import 'dart:async';

import 'package:acre_labs/dynamic_custom_form/core/extensions.dart';
import 'package:acre_labs/dynamic_custom_form/core/form_field_builder.dart';
import 'package:acre_labs/dynamic_custom_form/core/json_field.dart';
import 'package:acre_labs/dynamic_custom_form/core/utils.dart';

import 'package:flutter/material.dart';

typedef FieldDataActionCallback = void Function(dynamic data);

class DynamicFormRegistry {
  final List<Map<String, dynamic>> formDefinitions;
  final Map<String, dynamic> preAssignedValues = {};

  DynamicFormRegistry({
    required this.formDefinitions,
    Map<String, dynamic>? preAssignedValues,
  }) {
    if (preAssignedValues != null) {
      this.preAssignedValues.addAll(preAssignedValues);
    }
  }

  final Map<String, _DynamicFieldWrapperState> _fieldStates = {};
  final Map<String, dynamic> _fieldValues = {};

  void _register(String label, _DynamicFieldWrapperState state) {
    _fieldStates[label] = state;
  }

  /// Dispatches actions to the fields based on their labels.
  ///
  /// [actions] is a map where the key is the field label and the value is the action to be applied.
  void dispatch(Map<String, UIAction> actions) {
    for (final entry in actions.entries) {
      final fieldLabel = entry.key;
      final action = entry.value;

      if (_fieldStates.containsKey(fieldLabel)) {
        _fieldStates[fieldLabel]?.applyAction(action);
      }
    }
  }

  /// Reports a value change for a field.
  ///
  /// It only collects the field value and does not notify the field state,
  /// as the value report should be from the field itself.
  void reportValueChange(String label, dynamic value) {
    final fieldState = _fieldStates[label];

    // debugPrint('$label = $value');

    if (fieldState == null || fieldState.isNonField) return;

    _fieldValues[label] = value;
  }

  /// Manually sets a value for a field.
  /// It will trigger the action associated with the field value if applicable.
  ///
  /// NOTE: only works when the field is registered and active.
  void setValue(String label, dynamic value) {
    _fieldValues[label] = value;
    _fieldStates[label]?.addDataAction(value);
  }

  void subscribeDataAction(
    String label, {
    required FieldDataActionCallback onData,
  }) {
    _fieldStates[label]?.subscribeDataAction(onData);
  }

  void reset() {
    _fieldStates.clear();
    _fieldValues.clear();
  }

  Map<String, dynamic> get formValues => Map.of(_fieldValues);

  /// Returns a map of field values, excluding fields that are not visible if [excludeInvisible] is true.
  ///
  /// all non-field will be ignored, which is described by `isNonField` in [JsonField].
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

  List<Widget> buildFormFields(BuildContext context) {
    return formDefinitions.map(
      (json) {
        return DynamicWidgetBuilder.buildJsonWidget(context, json);
      },
    ).toList();
  }

  int get fieldCount => formDefinitions.length;
}

class CFManager extends InheritedWidget {
  final DynamicFormRegistry registry;

  const CFManager({
    super.key,
    required this.registry,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant CFManager oldWidget) {
    return oldWidget.registry != registry;
  }

  static DynamicFormRegistry of(BuildContext context) {
    final CFManager? manager =
        context.dependOnInheritedWidgetOfExactType<CFManager>();

    if (manager == null) {
      throw Exception('CFManager not found in context');
    }

    return manager.registry;
  }
}

class DynamicFieldWrapper extends StatefulWidget {
  final JsonField jsonField;
  const DynamicFieldWrapper({
    super.key,
    required this.jsonField,
  });

  @override
  State<DynamicFieldWrapper> createState() => _DynamicFieldWrapperState();
}

class _DynamicFieldWrapperState extends State<DynamicFieldWrapper> {
  StateAction? _lastStateAction;

  StreamController? _dataActionController;
  StreamSubscription<dynamic>? _dataSub;

  String get fieldLabel => widget.jsonField.label;

  bool get isOptional => widget.jsonField.isOptional;

  bool get isNonField => widget.jsonField.isNonField;

  bool get isVisible => _lastStateAction?.visible ?? true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerFieldState();

    if (widget.jsonField.preset != null) {
      _lastStateAction = widget.jsonField.preset?.state;
    }
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _dataActionController?.close();
    super.dispose();
  }

  void applyAction(UIAction action) {
    addDataAction(action.data);

    if (action.state != null) {
      _lastStateAction = action.state;
      setState(() {});
    }
  }

  void addDataAction(dynamic data) {
    _dataActionController?.add(data);
  }

  void subscribeDataAction(FieldDataActionCallback onData) {
    _dataSub?.cancel();
    _dataSub = _dataActionController?.stream.listen(
      onData,
      onDone: () {
        _dataSub?.cancel();
      },
    );
  }

  void _registerFieldState() {
    _dataActionController?.close();
    _dataActionController = StreamController();

    final registry = context.cfRegistry;
    if (registry != null) {
      registry._register(fieldLabel, this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _lastStateAction?.visible ?? true,
      maintainState: true,
      child: IgnorePointer(
        ignoring: _lastStateAction?.readonly ?? false,
        child: DynamicFormFieldBuilder(
          jsonField: widget.jsonField,
          readonly: _lastStateAction?.readonly ?? false,
        ),
      ),
    );
  }
}
