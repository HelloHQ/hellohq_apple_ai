import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hellohq_apple_ai/hellohq_apple_ai.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('hellohq_apple_ai');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  void mock(Future<Object?>? Function(MethodCall call) handler) =>
      messenger.setMockMethodCallHandler(channel, handler);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('appleFoundationModelsIncrementalDelta (cumulative snapshots)', () {
    test('first snapshot whole; prefix growth = tail; identical = empty', () {
      expect(appleFoundationModelsIncrementalDelta('', 'Hello'), 'Hello');
      expect(
          appleFoundationModelsIncrementalDelta('Hello', 'Hello world'), ' world');
      expect(appleFoundationModelsIncrementalDelta('Hello', 'Hello'), '');
    });
    test('non-prefix growth emits the whole current', () {
      expect(appleFoundationModelsIncrementalDelta('Hello', 'Hi'), 'Hi');
    });
    test('summing prefix snapshots reconstructs the final text', () {
      const snaps = ['Comp', 'Compound ', 'Compound interest.'];
      var prev = '';
      final b = StringBuffer();
      for (final s in snaps) {
        b.write(appleFoundationModelsIncrementalDelta(prev, s));
        prev = s;
      }
      expect(b.toString(), 'Compound interest.');
    });
  });

  group('availability name mapping', () {
    test('maps known + unknown', () {
      expect(appleFoundationModelsAvailabilityFromName('available'),
          AppleFoundationModelsAvailability.available);
      expect(appleFoundationModelsAvailabilityFromName('appleIntelligenceNotEnabled'),
          AppleFoundationModelsAvailability.unavailableAiNotEnabled);
      expect(appleFoundationModelsAvailabilityFromName('deviceNotEligible'),
          AppleFoundationModelsAvailability.unavailableDeviceNotEligible);
      expect(appleFoundationModelsAvailabilityFromName('modelNotReady'),
          AppleFoundationModelsAvailability.unavailableModelNotReady);
      expect(appleFoundationModelsAvailabilityFromName(null),
          AppleFoundationModelsAvailability.unavailableUnknown);
    });
  });

  group('AppleFoundationModelsClient (mocked channel)', () {
    const client = AppleFoundationModelsClient();

    test('availability() round-trips native value', () async {
      mock((call) async => call.method == 'availability' ? 'available' : null);
      expect(await client.availability(),
          AppleFoundationModelsAvailability.available);
    });
    test('respond() returns trimmed content', () async {
      mock((call) async {
        expect(call.method, 'respond');
        expect((call.arguments as Map)['prompt'], 'hi');
        return '  Hello there.  ';
      });
      expect(await client.respond(prompt: 'hi'), 'Hello there.');
    });
    test('respond() throws on empty', () async {
      mock((call) async => '   ');
      expect(() => client.respond(prompt: 'hi'),
          throwsA(isA<AppleFoundationModelsException>()));
    });
    test('respond() maps PlatformException', () async {
      mock((call) async => throw PlatformException(code: 'x', message: 'boom'));
      expect(
        () => client.respond(prompt: 'hi'),
        throwsA(isA<AppleFoundationModelsException>()
            .having((e) => e.message, 'message', 'boom')),
      );
    });
  });
}
