import 'package:acre_labs/interactive_custom_form/cf_json_field.dart';
import 'package:acre_labs/interactive_custom_form/core.dart';
import 'package:acre_labs/interactive_custom_form/json_form.dart';
import 'package:flutter/material.dart';

class InteractiveCustomFormExample extends StatefulWidget {
  const InteractiveCustomFormExample({super.key});

  @override
  State<InteractiveCustomFormExample> createState() =>
      _InteractiveCustomFormExampleState();
}

class _InteractiveCustomFormExampleState
    extends State<InteractiveCustomFormExample> {
  final _manager = CFCentralManager();

  @override
  void dispose() {
    _manager.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fields =
        jsonFormDefinitions.map((json) => CFJsonField.fromJson(json)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Custom Form Example'),
      ),
      body: CFManager(
        centralManager: _manager,
        child: Column(
          spacing: 20,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final field = fields[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: CFFieldWidget(field: field),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final values =
                        _manager.getFormValues(excludeInvisible: true);

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
      ),
    );
  }
}
