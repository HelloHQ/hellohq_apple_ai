import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hellohq_apple_ai/hellohq_apple_ai.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: VerifyPage());
}

/// On-device verification harness for `hellohq_apple_ai`.
///
/// Run on a real Apple-Intelligence-eligible device (macOS 26+ / iOS 26+):
///   cd example && flutter run -d macos   # or a connected iOS device
///
/// Then: tap **Check availability** (expect `available`), enter a prompt, and
/// try **Respond** (one-shot) and **Stream** (incremental deltas).
class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  static const _client = AppleFoundationModelsClient();
  final _prompt = TextEditingController(
    text: 'Explain compound interest in two sentences.',
  );

  AppleFoundationModelsAvailability? _availability;
  String _output = '';
  bool _busy = false;
  StreamSubscription<String>? _sub;

  Future<void> _check() async {
    final availability = await _client.availability();
    if (!mounted) return;
    setState(() => _availability = availability);
  }

  Future<void> _respond() async {
    setState(() {
      _busy = true;
      _output = '';
    });
    try {
      final text = await _client.respond(
        prompt: _prompt.text,
        instructions: 'You are a concise assistant.',
      );
      if (mounted) setState(() => _output = text);
    } on AppleFoundationModelsException catch (e) {
      if (mounted) setState(() => _output = 'Error: ${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stream() async {
    await _sub?.cancel();
    setState(() {
      _busy = true;
      _output = '';
    });
    final buffer = StringBuffer();
    _sub = _client
        .stream(
          prompt: _prompt.text,
          instructions: 'You are a concise assistant.',
        )
        .listen(
          (delta) {
            buffer.write(delta);
            if (mounted) setState(() => _output = buffer.toString());
          },
          onError: (Object e) {
            if (mounted) setState(() => _output = 'Error: $e');
          },
          onDone: () {
            if (mounted) setState(() => _busy = false);
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _availability == AppleFoundationModelsAvailability.available;
    return Scaffold(
      appBar: AppBar(title: const Text('hellohq_apple_ai — verify')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Availability: ${_availability ?? "unknown"}'),
                ),
                ElevatedButton(
                  onPressed: _check,
                  child: const Text('Check availability'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prompt,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: ready && !_busy ? _respond : null,
                  child: const Text('Respond'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: ready && !_busy ? _stream : null,
                  child: const Text('Stream'),
                ),
                const SizedBox(width: 12),
                if (_busy) const CircularProgressIndicator(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(_output),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
