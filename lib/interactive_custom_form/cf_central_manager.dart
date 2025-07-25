import 'package:acre_labs/interactive_custom_form/field_command.dart';
import 'package:acre_labs/interactive_custom_form/field_widget.dart';
import 'package:flutter/widgets.dart';

class CFCentralManager {
  final Map<String, CFFieldRegistry> _fields = {};
  final Map<String, dynamic> _values = {};

  Map<String, dynamic> get formValues => Map.of(_values);

  Map<String, dynamic> getFormValues({bool excludeInvisible = true}) {
    if (!excludeInvisible) return Map.of(_values);

    final values = <String, dynamic>{};

    for (final label in _values.keys) {
      final field = _fields[label];
      if (field == null) continue;
      if (excludeInvisible && !field.isVisible) continue;

      values[label] = _values[label];
    }

    return values;
  }

  // todo: better design
  Map<String, dynamic>? validateFormValues({bool excludeInvisible = true}) {
    final values = getFormValues(excludeInvisible: excludeInvisible);

    for (final field in _fields.values) {
      if (!field.isOptional && !values.containsKey(field.fieldLabel)) {
        return null; // Required field is missing
      }
    }

    return values;
  }

  CFCentralManager();

  void register(String label, CFFieldRegistry state) {
    _fields[label] = state;
  }

  void unregister(String label) {
    _fields.remove(label);
  }

  void dispatchActions(List<CFFieldAction> actions) {
    for (final action in actions) {
      final field = _fields[action.label];
      field?.executeAction(action);
    }
  }

  void reportValueChange(String label, dynamic value) {
    _values[label] = value;
  }

  void reset() {
    _fields.clear();
    _values.clear();
  }
}

class CFManager extends InheritedWidget {
  final CFCentralManager centralManager;

  const CFManager({
    super.key,
    required this.centralManager,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant CFManager oldWidget) {
    return oldWidget.centralManager != centralManager;
  }

  static CFCentralManager of(BuildContext context) {
    final CFManager? manager =
        context.dependOnInheritedWidgetOfExactType<CFManager>();

    if (manager == null) {
      throw Exception('CFManager not found in context');
    }

    return manager.centralManager;
  }
}
