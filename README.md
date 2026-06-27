# hellohq_apple_ai

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
![Platforms: macOS · iOS](https://img.shields.io/badge/platforms-macOS%20%C2%B7%20iOS-lightgrey.svg)

A Flutter plugin for **Apple's on-device Foundation Models** — the language model
that ships with Apple Intelligence. It runs **on-device**: no API key, no
account, no per-token cost, and prompts never leave the machine.

It exposes a small Dart client over a Swift plugin that talks to Apple's
[`FoundationModels`](https://developer.apple.com/documentation/foundationmodels)
framework, with three calls: check availability, get a one-shot response, and
stream a response as incremental text deltas.

> Extracted from the [HelloHQ](https://github.com/HelloHQ) app so on-device AI
> can live as a standalone, reusable plugin. Native code **auto-registers** —
> no `Runner`/`pbxproj` edits in the host app.

## Requirements

| | |
|---|---|
| **Platforms** | macOS and iOS only (no Android/web/Linux/Windows) |
| **OS at runtime** | macOS 26+ / iOS 26+ — the `FoundationModels` APIs are `@available`-guarded |
| **Hardware** | An Apple Intelligence–eligible device with Apple Intelligence enabled |

The plugin links on older deployment targets (macOS 10.11 / iOS 13), but the
model is only reachable at runtime on supported OS versions and eligible
hardware — always check `availability()` first (see below).

## Install

Not published to pub.dev. Depend on it as a pinned git dependency:

```yaml
dependencies:
  hellohq_apple_ai:
    git:
      url: https://github.com/HelloHQ/hellohq_apple_ai.git
      ref: <commit-sha>   # pin to a specific commit
```

Then `flutter pub get`. The native plugin registers itself via Flutter's
generated plugin registrant — nothing to wire up manually.

## Usage

```dart
import 'package:hellohq_apple_ai/hellohq_apple_ai.dart';

const client = AppleFoundationModelsClient();

// 1. Always gate on availability — the model may be missing, disabled,
//    or still downloading.
final availability = await client.availability();
if (availability != AppleFoundationModelsAvailability.available) {
  // Surface the reason to the user (see table below) and stop here.
  return;
}

// 2. One-shot response.
final answer = await client.respond(
  prompt: 'Summarise this portfolio in one sentence.',
  instructions: 'You are a concise financial assistant.', // optional system text
);
print(answer);

// 3. Streaming — yields *incremental* deltas, ready to append to the UI.
final buffer = StringBuffer();
await for (final delta in client.stream(prompt: 'Explain compound interest.')) {
  buffer.write(delta);
  // render buffer.toString()
}
```

### Availability states

`availability()` returns an `AppleFoundationModelsAvailability`:

| Value | Meaning | Suggested UX |
|---|---|---|
| `available` | Model ready | Enable the feature |
| `unavailableDeviceNotEligible` | Hardware doesn't support Apple Intelligence | Hide the feature |
| `unavailableAiNotEnabled` | Apple Intelligence is off | Prompt: enable it in System Settings |
| `unavailableModelNotReady` | Model still downloading | "Try again soon" |
| `unavailableUnknown` | Unsupported OS or unrecognised reason | Hide / generic message |

### Errors

`respond()` throws `AppleFoundationModelsException` on a platform error or an
empty response. `stream()` surfaces native errors through the stream.

## How it works

- **`MethodChannel('hellohq_apple_ai')`** — `availability` and `respond`
  (one-shot `LanguageModelSession.respond(to:)`).
- **`EventChannel('hellohq_apple_ai/stream')`** — streaming. Apple's
  `streamResponse` emits **cumulative snapshots** (each is normally a superset of
  the previous); the Dart client diffs consecutive snapshots and yields only the
  new tail, so consumers get clean incremental deltas. The diff helper
  `appleFoundationModelsIncrementalDelta` is exported and unit-tested.
- Native Swift is `@available(macOS 26 / iOS 26)`-guarded and type-checked.

## Privacy

The on-device path runs entirely locally — prompts and responses do not leave
the device, and no API key or account is required. (Apple's optional Private
Cloud Compute tier is **not** wired up yet — see roadmap.)

## Roadmap

- **Private Cloud Compute (PCC) tier.** WWDC 2026 unified Foundation Models into
  one Swift API spanning on-device → PCC → third-party clouds, shipping in
  **iOS/macOS 27**; PCC is free of cloud API cost for App Store Small Business
  Program members. This plugin currently targets the **iOS/macOS 26** on-device
  model only. Adding a PCC option means building against the iOS 27 SDK and
  routing requests through the new server tier — a clean extension of the
  session-based API here, not a rewrite.
- Structured / guided generation (`@Generable`) and tool calling.
- **On-device verification.** Run `example/` on real Apple-Intelligence hardware
  (macOS 26+ / iOS 26+): `cd example && flutter run -d macos`, then exercise
  Check availability / Respond / Stream. Native runtime can't be verified in CI.

## License

[Apache License 2.0](LICENSE).
