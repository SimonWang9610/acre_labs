import 'package:acre_labs/cron_job/example.dart';
import 'package:acre_labs/interactive_custom_form/example.dart';
import 'package:acre_labs/labs/bigint_example.dart';
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
      home: InteractiveCustomFormExample(),
    );
  }
}
