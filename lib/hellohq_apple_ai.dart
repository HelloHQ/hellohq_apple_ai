import 'package:flutter/services.dart';

/// Availability of Apple's on-device Foundation Model, mirroring
/// `SystemLanguageModel.availability`.
enum AppleFoundationModelsAvailability {
  available,
  unavailableDeviceNotEligible,
  unavailableAiNotEnabled,
  unavailableModelNotReady,
  unavailableUnknown,
}

AppleFoundationModelsAvailability appleFoundationModelsAvailabilityFromName(
  String? name,
) {
  switch (name) {
    case 'available':
      return AppleFoundationModelsAvailability.available;
    case 'deviceNotEligible':
      return AppleFoundationModelsAvailability.unavailableDeviceNotEligible;
    case 'appleIntelligenceNotEnabled':
      return AppleFoundationModelsAvailability.unavailableAiNotEnabled;
    case 'modelNotReady':
      return AppleFoundationModelsAvailability.unavailableModelNotReady;
    default:
      return AppleFoundationModelsAvailability.unavailableUnknown;
  }
}

class AppleFoundationModelsException implements Exception {
  final String message;
  AppleFoundationModelsException(this.message);
  @override
  String toString() => message;
}

/// `hellohq_apple_ai` — Flutter client for Apple's on-device Foundation Model
/// (and Private Cloud Compute, later). Talks to the native Swift plugin on
/// macOS/iOS.
///
/// `stream()` yields **incremental** text deltas: the native side emits
/// cumulative `streamResponse` snapshots and this client diffs them.
class AppleFoundationModelsClient {
  static const MethodChannel _method = MethodChannel('hellohq_apple_ai');
  static const EventChannel _events = EventChannel('hellohq_apple_ai/stream');

  const AppleFoundationModelsClient();

  Future<AppleFoundationModelsAvailability> availability() async {
    final name = await _method.invokeMethod<String>('availability');
    return appleFoundationModelsAvailabilityFromName(name);
  }

  /// Non-streaming `LanguageModelSession.respond(to:)`.
  Future<String> respond({required String prompt, String? instructions}) async {
    final String? result;
    try {
      result = await _method.invokeMethod<String>('respond', {
        'prompt': prompt,
        if (instructions != null && instructions.trim().isNotEmpty)
          'instructions': instructions,
      });
    } on PlatformException catch (e) {
      throw AppleFoundationModelsException(e.message ?? 'On-device model error.');
    }
    final content = (result ?? '').trim();
    if (content.isEmpty) {
      throw AppleFoundationModelsException(
        'The on-device model returned an empty response.',
      );
    }
    return content;
  }

  /// Streaming respond → incremental text deltas (native cumulative snapshots
  /// diffed here).
  Stream<String> stream({required String prompt, String? instructions}) async* {
    final args = {
      'prompt': prompt,
      if (instructions != null && instructions.trim().isNotEmpty)
        'instructions': instructions,
    };
    var previous = '';
    await for (final snapshot in _events.receiveBroadcastStream(args)) {
      final current = snapshot is String ? snapshot : '${snapshot ?? ''}';
      final delta = appleFoundationModelsIncrementalDelta(previous, current);
      previous = current;
      if (delta.isNotEmpty) yield delta;
    }
  }
}

/// Convert one cumulative snapshot into the new piece since [previous]. Apple's
/// `streamResponse` yields snapshots where each (normally) is a superset of the
/// prior; emit only the new tail, or the whole current on non-prefix growth.
String appleFoundationModelsIncrementalDelta(String previous, String current) {
  if (previous.isEmpty) return current;
  if (current.length >= previous.length && current.startsWith(previous)) {
    return current.substring(previous.length);
  }
  return current;
}
