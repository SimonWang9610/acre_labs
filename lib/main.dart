import 'package:acre_labs/cron_job/example.dart';
import 'package:acre_labs/dynamic_custom_form/example.dart';
import 'package:acre_labs/dynamic_custom_form/example_schema.dart';
import 'package:acre_labs/floating_dialog/alarm/global_event_alarm_listener.dart';
import 'package:acre_labs/labs/bigint_example.dart';
import 'package:acre_labs/snapshot/example.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: _Example(),
      home: GlobalEventAlarmListener(),
    );
  }
}

class _Example extends StatefulWidget {
  const _Example();

  @override
  State<_Example> createState() => __ExampleState();
}

class __ExampleState extends State<_Example> {
  final _examples = {
    "Door Template": doorTemplateSchema,
    "Dynamic Text": dynamicTextSchema,
    "Null Action Trigger": nullActionSchema,
  };

  final _selectedSchema = ValueNotifier<String>("Door Template");

  @override
  void dispose() {
    _selectedSchema.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dynamic Custom Form Example"),
      ),
      body: Column(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: _selectedSchema,
            builder: (context, schemaName, child) {
              return DropdownButton<String>(
                value: schemaName,
                items: _examples.keys
                    .map(
                      (key) => DropdownMenuItem(
                        value: key,
                        child: Text(key),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _selectedSchema.value = value;
                  }
                },
              );
            },
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _selectedSchema,
              builder: (context, schemaName, child) {
                return DynamicCustomFormExample(
                  formDefinition: _examples[schemaName]!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
