import 'package:acre_labs/cron_job/cron_expression.dart';
import 'package:acre_labs/cron_job/time_duration_picker.dart';
import 'package:acre_labs/cron_job/widget.dart';
import 'package:flutter/material.dart';

class CronPickerExample extends StatefulWidget {
  const CronPickerExample({super.key});

  @override
  State<CronPickerExample> createState() => _CronPickerExampleState();
}

class _CronPickerExampleState extends State<CronPickerExample> {
  final ValueNotifier<CronExpression?> _cronExpression = ValueNotifier(
    CronExpression.always(),
  );

  @override
  Widget build(BuildContext context) {
    final picker = CronSchedulePickerWidget(
      initialSchedule: _cronExpression.value?.toCronString(),
      onScheduleChanged: (newCron) {
        if (newCron != null) {
          _cronExpression.value = newCron;
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cron Picker Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<CronExpression?>(
              valueListenable: _cronExpression,
              builder: (context, cron, child) {
                return Text(
                  cron?.toHumanReadable() ?? 'No Cron Expression',
                  style: const TextStyle(fontSize: 16),
                );
              },
            ),
            const SizedBox(height: 20),
            picker,
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Import/Export Cron Expression'),
                      content: Text(
                          CronSchedulePickerWidget.getScheduleString(picker) ??
                              '<No Cron Expression>'),
                      actions: [],
                    );
                  },
                );
              },
              icon: Icon(Icons.import_export),
            )
          ],
        ),
      ),
    );
  }
}

class TimeDurationPickerExample extends StatefulWidget {
  const TimeDurationPickerExample({super.key});

  @override
  State<TimeDurationPickerExample> createState() =>
      _TimeDurationPickerExampleState();
}

class _TimeDurationPickerExampleState extends State<TimeDurationPickerExample> {
  final ValueNotifier<String?> _duration = ValueNotifier<String?>(null);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Duration Picker Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: _duration,
                builder: (context, duration, child) {
                  return Text(
                    duration ?? 'No Duration Selected',
                    style: const TextStyle(fontSize: 16),
                  );
                },
              ),
              const SizedBox(height: 20),
              TimeDurationPickerWidget(
                label: 'Duration',
                initialDuration: _duration.value,
                onDurationChanged: (newDuration) {
                  _duration.value = newDuration;
                },
              ),
              IconButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Selected Duration'),
                          content:
                              Text(_duration.value ?? 'No Duration Selected'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                icon: const Icon(Icons.check),
              )
            ],
          ),
        ),
      ),
    );
  }
}
