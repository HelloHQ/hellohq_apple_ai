import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hellohq_apple_ai/hellohq_apple_ai.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _client = AppleFoundationModelsClient();
  AppleFoundationModelsAvailability? _availability;
  String _answer = '';

  Future<void> _check() async {
    final availability = await _client.availability();
    if (!mounted) return;
    setState(() => _availability = availability);
  }

  Future<void> _ask() async {
    try {
      final text = await _client.respond(prompt: 'Say hello in one word.');
      if (!mounted) return;
      setState(() => _answer = text);
    } on AppleFoundationModelsException catch (e) {
      if (!mounted) return;
      setState(() => _answer = 'Error: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('hellohq_apple_ai')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Availability: ${_availability ?? 'tap to check'}'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _check, child: const Text('Check')),
              ElevatedButton(onPressed: _ask, child: const Text('Ask')),
              const SizedBox(height: 12),
              Text(_answer),
            ],
          ),
        ),
      ),
    );
  }
}
