import 'package:acre_labs/dynamic_custom_form/core.dart';
import 'package:flutter/material.dart';

class DynamicCustomFormExample extends StatefulWidget {
  final List<Map<String, dynamic>> formDefinition;
  const DynamicCustomFormExample({
    super.key,
    required this.formDefinition,
  });

  @override
  State<DynamicCustomFormExample> createState() =>
      _DynamicCustomFormExampleState();
}

class _DynamicCustomFormExampleState extends State<DynamicCustomFormExample> {
  late CFFieldRegistry registry = CFFieldRegistry(
    formDefinitions: widget.formDefinition,
  );

  @override
  void didUpdateWidget(covariant DynamicCustomFormExample oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.formDefinition != widget.formDefinition) {
      registry.reset();
      registry = CFFieldRegistry(
        formDefinitions: widget.formDefinition,
      );
    }
  }

  @override
  void dispose() {
    registry.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CFManager(
      registry: registry,
      child: Column(
        spacing: 20,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: registry.fieldCount,
              itemBuilder: (context, index) => Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: registry.buildFieldByIndex(context, index)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final values = registry.getFormValues(excludeInvisible: true);

                  return AlertDialog(
                    title: Text('Submitted Values'),
                    content: Text(
                      values.isEmpty
                          ? 'No values submitted.'
                          : values.entries
                              .map((e) => '${e.key}: ${e.value}')
                              .join('\n'),
                    ),
                  );
                },
              );
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
