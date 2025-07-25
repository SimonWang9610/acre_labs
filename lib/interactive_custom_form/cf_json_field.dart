import 'package:flutter/widgets.dart';

class CFJsonField {
  final String label;
  final List<Map<String, dynamic>> outerWidgets;
  final Map<String, dynamic> fieldJson;
  final bool isOptional;

  const CFJsonField({
    required this.label,
    required this.fieldJson,
    required this.outerWidgets,
    required this.isOptional,
  });

  factory CFJsonField.fromJson(Map<String, dynamic> json) {
    final (outer, field) = _structureJsonWidgets(json);

    return CFJsonField(
      label: field?['label'] ?? '',
      fieldJson: field ?? {},
      outerWidgets: outer ?? [],
      isOptional: field?['isOptional'] ?? false,
    );
  }

  Widget wrapWidget(Widget? fieldWidget) {
    Widget child = fieldWidget ?? const SizedBox.shrink();

    for (final widgetJson in outerWidgets.reversed) {
      child = CFFormConverter.wrapWidget(widgetJson, child);
    }

    return child;
  }

  String? get fieldTypeName {
    return fieldJson['type'] as String?;
  }
}

(List<Map<String, dynamic>>?, Map<String, dynamic>?) _structureJsonWidgets(
    Map<String, dynamic> json) {
  final outerWidgets = <Map<String, dynamic>>[];
  Map<String, dynamic>? fieldWidget;

  if (!json.containsKey("type")) return (null, null);

  if (json.containsKey("label")) {
    fieldWidget = json;
    return (outerWidgets, fieldWidget);
  }

  outerWidgets.add(json);

  if (json.containsKey("child")) {
    final child = json['child'] as Map<String, dynamic>;
    final (out, field) = _structureJsonWidgets(child);
    outerWidgets.addAll(out ?? []);
    fieldWidget = field;
  }

  return (outerWidgets, fieldWidget);
}

// Padding/Row/SizedBox/Text/Expanded/Align

class CFFormConverter {
  static Widget wrapWidget(Map<String, dynamic> json, Widget? child) {
    final type = json['type'] as String?;

    if (type == null) return child ?? const SizedBox.shrink();

    child ??= const SizedBox.shrink();

    switch (type) {
      case 'Padding':
        final padding = json['padding'] as Map<String, dynamic>;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            double.tryParse(padding['left'].toString()) ?? 0,
            double.tryParse(padding['top'].toString()) ?? 0,
            double.tryParse(padding['right'].toString()) ?? 10,
            double.tryParse(padding['bottom'].toString()) ?? 10,
          ),
          child: child,
        );
      case 'SizedBox':
        return SizedBox(
          width: json['width'] != null
              ? double.tryParse(json['width'].toString()) ?? 0
              : null,
          height: json['height'] != null
              ? double.tryParse(json['height'].toString()) ?? 0
              : null,
          child: child,
        );
      case 'Text':
        return Text(json['data'] ?? '');
      case 'Expanded':
        return Expanded(
          child: child,
        );
      case 'Align':
        return Align(alignment: Alignment.center, child: child);
      default:
        return child;
    }
  }
}
