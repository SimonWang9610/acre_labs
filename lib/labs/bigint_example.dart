import 'package:flutter/material.dart';

class BigIntExample extends StatefulWidget {
  const BigIntExample({super.key});

  @override
  State<BigIntExample> createState() => _BigIntExampleState();
}

class _BigIntExampleState extends State<BigIntExample> {
  final controller = TextEditingController();

  final _max = BigInt.from(2).pow(63) - BigInt.one;

  BigInt? _bigIntValue;
  int? _intValue;
  double? _doubleValue;
  String? _stringValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BigInt Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          spacing: 15,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Enter a number',
                suffix: ElevatedButton(
                  onPressed: _parse,
                  child: Icon(Icons.check),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            Text('BigInt: ${_bigIntValue?.toString() ?? 'null'}'),
            Text('int: ${_intValue?.toString() ?? 'null'}'),
            Text('double: ${_doubleValue?.toString() ?? 'null'}'),
            Text('String: ${_stringValue ?? 'null'}'),
          ],
        ),
      ),
    );
  }

  void _parse() {
    final input = controller.text;
    if (input.isEmpty) {
      return;
    }

    try {
      _bigIntValue = BigInt.tryParse(input);
      _intValue = int.tryParse(input);
      _doubleValue = double.tryParse(input);
      _stringValue = input;

      if (_bigIntValue != null && _bigIntValue! > _max) {
        print('BigInt exceeds max value');
      }
    } catch (e) {
      // Handle parsing error
    }

    setState(() {});
  }
}
