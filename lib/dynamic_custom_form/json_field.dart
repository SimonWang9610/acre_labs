/// Represents a UI action that can be applied to a field, such as setting its state or data.
/// ```json
/// {
///  "@state": {
///   "visible": true,
///   "readonly": false
///  },
///  "@data": "some data"
/// }
/// ```
class UIAction {
  final StateAction? state;
  final dynamic data;

  const UIAction({
    this.state,
    this.data,
  });

  factory UIAction.fromJson(Map<String, dynamic> json) {
    return UIAction(
      state:
          json['@state'] != null ? StateAction.fromJson(json['@state']) : null,
      data: json['@data'],
    );
  }
}

/// Represents the state of a field, including visibility and readonly status.
/// ```json
/// {
///  "@state": {
///   "visible": true,
///   "readonly": false
///  }
/// }
class StateAction {
  final bool visible;
  final bool readonly;

  const StateAction({
    this.visible = true,
    this.readonly = false,
  });

  factory StateAction.fromJson(Map<String, dynamic> json) {
    return StateAction(
      visible: json['visible'] as bool? ?? true,
      readonly: json['readonly'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'StateAction(visible: $visible, readonly: $readonly)';
  }
}

/// Represents a field in the dynamic custom form.
class JsonField {
  final String type;
  final String label;

  /// The preset action for the field, which can be used to set initial values or states.
  final UIAction? preset;

  /// if no `@ui-configuration` is provided, the raw json is used as the uiConfig
  /// for backward compatibility.
  final Map<String, dynamic>? uiConfig;
  final Map<String, Map<String, UIAction>>? actions;

  /// The raw JSON representation of the field, which can be used to access additional properties.
  final Map<String, dynamic> _raw;

  const JsonField({
    required this.type,
    required this.label,
    Map<String, dynamic> raw = const {},
    this.preset,
    this.uiConfig,
    this.actions,
  }) : _raw = raw;

  factory JsonField.fromJson(Map<String, dynamic> json) {
    _convertPreset(json);

    final actions = <String, Map<String, UIAction>>{};

    if (json.containsKey('@actions') &&
        json['@actions'] is Map<String, dynamic>) {
      for (final entry in json['@actions'].entries) {
        actions[entry.key] = (entry.value as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, UIAction.fromJson(value)),
        );
      }
    }

    return JsonField(
      type: json['type'] as String,
      label: json['label'] as String,
      preset: json.containsKey('@preset')
          ? UIAction.fromJson(json['@preset'])
          : null,
      uiConfig: json.containsKey('@ui-configuration')
          ? json['@ui-configuration'] as Map<String, dynamic>
          : json,
      actions: actions,
      raw: json,
    );
  }

  /// Used to get the raw value of the raw widget json.
  dynamic operator [](String key) {
    return _raw[key];
  }
}

void _convertPreset(Map<String, dynamic> json) {
  if (json.containsKey("@preset")) return;

  final preset = <String, dynamic>{};

  if (json.containsKey("initialValue")) {
    preset['@data'] = json['initialValue'];
  } else if (json.containsKey("selectedValue")) {
    preset['@data'] = json['selectedValue'];
  } else if (json.containsKey("selectedValues")) {
    preset['@data'] = json['selectedValues'];
  }

  json["@preset"] = preset;
}
