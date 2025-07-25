class CFFieldAction {
  final String label;
  final bool? visible;
  final bool? readonly;
  final dynamic value;

  const CFFieldAction({
    required this.label,
    this.visible,
    this.readonly,
    this.value,
  });

  static CFFieldAction fromJson(String label, Map<String, dynamic> json) {
    return CFFieldAction(
      label: label,
      visible: json['visible'] as bool?,
      readonly: json['readonly'] as bool?,
      value: json['value'],
    );
  }

  static List<CFFieldAction> fromActions(Map<String, dynamic>? actions) {
    if (actions == null) return [];

    return actions.entries.map(
      (entry) {
        return CFFieldAction.fromJson(entry.key, entry.value);
      },
    ).toList();
  }

  @override
  String toString() {
    return 'CFFieldAction(label: $label, visible: $visible, readonly: $readonly, value: $value)';
  }
}
