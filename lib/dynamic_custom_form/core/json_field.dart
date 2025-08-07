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
  /// Triggers for field that can check if its value is null or not.
  /// e.g., for single select dropdowns, time pickers, etc.
  static const nullTrigger = "#null";
  static const notNullTrigger = "#notNull";

  /// Triggers for field that can check if its value is empty or not.
  /// e.g., for text fields, multiselect dropdowns, etc.
  static const emptyTrigger = "#empty";
  static const notEmptyTrigger = "#notEmpty";

  /// Triggers for checkbox actions
  static const checkedTrigger = "#checked";
  static const uncheckedTrigger = "#unchecked";

  final StateAction? state;
  final dynamic data;

  const UIAction({
    this.state,
    this.data,
  });

  factory UIAction.fromJson(Map<String, dynamic> json) {
    return UIAction(
      state: json['@state'] != null ? StateAction.fromJson(json['@state']) : null,
      data: json['@data'],
    );
  }

  UIAction useData(dynamic newData) {
    return UIAction(
      state: state,
      data: newData,
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

    if (json.containsKey('@actions') && json['@actions'] is Map<String, dynamic>) {
      for (final entry in json['@actions'].entries) {
        actions[entry.key] = (entry.value as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, UIAction.fromJson(value)),
        );
      }
    }

    return JsonField(
      type: json['type'] as String,
      label: json['label'] as String,
      preset: json['@preset'] != null ? UIAction.fromJson(json['@preset']) : null,

      /// fallback to raw json if no `@ui-configuration` is provided for backward compatibility.
      uiConfig: json.containsKey('@ui-configuration') ? json['@ui-configuration'] as Map<String, dynamic> : json,
      actions: actions,
      raw: json,
    );
  }

  /// Used to get the raw value of the raw widget json.
  dynamic operator [](String key) {
    return uiConfig?[key] ?? _raw[key];
  }

  /// indicates whether the field is only for UI purpose.
  /// If true, its value will not be collected in the form values.
  ///
  /// It could be the top field of a field json schema, like:
  /// ```json
  /// {
  ///  "type": "Text",
  /// "label": "Title",
  ///  "nonField": true,
  /// ...
  /// }
  /// ```
  /// or a field with `@ui-configuration`:
  /// ```json
  /// {
  ///  "type": "Text",
  ///  "label": "Title",
  ///  "@ui-configuration": {
  ///   "nonField": true
  ///  },
  /// ...
  /// }
  /// ```
  bool get isNonField {
    return this['nonField'] == true;
  }

  bool get isOptional {
    return this['isOptional'] == true;
  }

  bool get isRequired {
    return this['isRequired'] == true;
  }

  String? get hint {
    return this['hint'] as String?;
  }

  bool get includeChildFolders {
    return this['includeChildFolders'] == true;
  }

  bool get spanScope {
    return this['spanScope'] == true;
  }

  dynamic get initialData {
    return preset?.data;
  }
}

void _convertPreset(Map<String, dynamic> json) {
  if (json.containsKey("@preset")) return;

  final preset = <String, dynamic>{};

  if (json.containsKey("initialValue")) {
    preset['@data'] = json['initialValue'];
  } else if (json.containsKey("initialDate")) {
    preset['@data'] = json['initialDate'];
  } else if (json.containsKey("selectedValue")) {
    preset['@data'] = json['selectedValue'];
  } else if (json.containsKey("selectedValues")) {
    preset['@data'] = json['selectedValues'];
  } else if (json.containsKey("hour") && json.containsKey("minute")) {
    /// for time picker widget
    preset['@data'] = {
      'hour': json['hour'],
      'minute': json['minute'],
    };
  }

  json["@preset"] = preset;
}
